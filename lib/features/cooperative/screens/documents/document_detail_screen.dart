import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/document.dart';
import 'package:gcoop/shared/models/cooperative.dart';
import 'package:gcoop/core/services/pdf_service.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/utils/amount_to_words.dart';
import 'package:gcoop/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final AppDocument document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  final _pdfService = PdfService();
  List<DocumentItem> _items = [];
  bool _isLoading = true;
  Cooperative? _cooperative;
  String? _logoBytes;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final itemsResponse = await Supabase.instance.client
          .from('document_items')
          .select('*, products(name)')
          .eq('document_id', widget.document.id);

      final items = (itemsResponse as List)
          .map((json) => DocumentItem.fromJson(json))
          .toList();

      final profile = ref.read(profileProvider).value;
      Cooperative? coop;
      String? logo;

      if (profile?.cooperativeId != null) {
        final coopResponse = await Supabase.instance.client
            .from('cooperatives')
            .select()
            .eq('id', profile!.cooperativeId!)
            .single();

        coop = Cooperative.fromJson(coopResponse);

        if (coop.logoUrl != null) {
          logo = await _pdfService.fetchLogoAsBase64(coop.logoUrl);
        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _cooperative = coop;
          _logoBytes = logo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _subtotal => _items.fold<double>(0, (sum, item) => sum + item.total);
  double get _discountAmount => _subtotal * (widget.document.discount / 100);
  double get _afterDiscount => _subtotal - _discountAmount;
  double get _tvaAmount => _afterDiscount * (widget.document.tvaRate / 100);
  double get _total => _afterDiscount + _tvaAmount + widget.document.deliveryFees;

  Future<void> _handlePdfAction(String action) async {
    if (_cooperative == null) return;

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final document = widget.document;
    document.items = _items;

    final pdf = await _pdfService.generateDocumentPdf(
      document: document,
      cooperative: _cooperative!,
      items: _items,
      isArabic: isArabic,
      logoBytes: _logoBytes,
    );

    if (action == 'download') {
      final path = await _pdfService.savePdfToDevice(pdf, widget.document.number);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to $path'), backgroundColor: AppColors.success),
        );
      }
    } else if (action == 'share') {
      await _pdfService.sharePdf(pdf, widget.document.number);
    } else if (action == 'print') {
      await _pdfService.printPdf(pdf);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(widget.document.number),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHeaderCard(l10n),
                      const SizedBox(height: 12),
                      _buildClientCard(l10n),
                      const SizedBox(height: 12),
                      _buildItemsTable(l10n),
                      if (widget.document.type != 'BDL') ...[
                        const SizedBox(height: 12),
                        _buildTotalsCard(l10n),
                        const SizedBox(height: 12),
                        _buildAmountInWords(l10n),
                      ],
                      const SizedBox(height: 12),
                      _buildSignaturesCard(l10n),
                      if (widget.document.additionalInfo != null && widget.document.additionalInfo!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAdditionalInfoCard(l10n),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildBottomActions(l10n),
              ],
            ),
    );
  }

  Widget _buildHeaderCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_logoBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _decodeBase64(_logoBytes!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 50, height: 50),
                  ),
                ),
              if (_logoBytes != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cooperative?.name ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (_cooperative?.address != null)
                      Text(_cooperative!.address!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (_cooperative?.phone != null)
                      Text(_cooperative!.phone!, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (_cooperative?.ice != null || _cooperative?.rc != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (_cooperative?.ice != null)
                            Text('ICE: ${_cooperative!.ice}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          if (_cooperative?.rc != null) ...[
                            const SizedBox(width: 12),
                            Text('RC: ${_cooperative!.rc}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.document.typeLabel,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.document.number,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(widget.document.date),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.clientSectionBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'CLIENT',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.document.clientName ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                if (widget.document.clientAddress != null)
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.document.clientAddress!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                if (widget.document.clientPhone != null)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.document.clientPhone!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                if (widget.document.type == 'BDL' && widget.document.deliveryLocation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lieu: ${widget.document.deliveryLocation}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                if (widget.document.type == 'BDC' && widget.document.deliveryDelay != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Délai: ${widget.document.deliveryDelay}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
                if (widget.document.paymentMethod != null && widget.document.type != 'BDL') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Paiement: ${widget.document.paymentMethod}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable(AppLocalizations l10n) {
    final showPrices = widget.document.type != 'BDL';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 1, child: Text('Réf.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                const Expanded(flex: 3, child: Text('Description', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                const Expanded(flex: 1, child: Text('Qté', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                const Expanded(flex: 1, child: Text('Unité', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center)),
                if (showPrices) ...[
                  const Expanded(flex: 1, child: Text('P.U', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                  const Expanded(flex: 1, child: Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.right)),
                ],
              ],
            ),
          ),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : AppColors.tableBg,
                border: Border(
                  bottom: index < _items.length - 1
                      ? const BorderSide(color: AppColors.border, width: 0.5)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Expanded(flex: 1, child: Text(item.productRef, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                  Expanded(flex: 3, child: Text(item.description.isNotEmpty ? item.description : (item.productName ?? ''), style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 1, child: Text(item.quantity.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 1, child: Text(item.unit, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                  if (showPrices) ...[
                    Expanded(flex: 1, child: Text(item.unitPrice.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                    Expanded(flex: 1, child: Text(item.total.toStringAsFixed(2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _totalRow(l10n.subtotal, '${_subtotal.toStringAsFixed(2)} DH'),
          if (widget.document.discount > 0)
            _totalRow('${l10n.discount} (${widget.document.discount}%)', '-${_discountAmount.toStringAsFixed(2)} DH', isNegative: true),
          if (widget.document.tvaRate > 0)
            _totalRow('${l10n.tva} (${widget.document.tvaRate}%)', '${_tvaAmount.toStringAsFixed(2)} DH'),
          if (widget.document.deliveryFees > 0)
            _totalRow(l10n.deliveryFees, '${widget.document.deliveryFees.toStringAsFixed(2)} DH'),
          const Divider(height: 20),
          _totalRow(l10n.totalToPay, '${_total.toStringAsFixed(2)} DH', isTotal: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool isNegative = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : null,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.accent : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : null,
              fontSize: isTotal ? 16 : 14,
              color: isNegative ? AppColors.error : (isTotal ? AppColors.accent : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInWords(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.clientSectionBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            '${l10n.amountInWords}: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              AmountToWords.withCurrency(_total),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignaturesCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _signatureBlock(
              title: l10n.clientSignature,
              subtitle: widget.document.type == 'BDL' ? l10n.receivedOn : 'Bon pour:',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _signatureBlock(
              title: l10n.supplierSignature,
              subtitle: widget.document.type == 'BDL' ? l10n.deliveredOn : l10n.stamp,
              showStamp: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signatureBlock({required String title, required String subtitle, bool showStamp = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 50),
        Container(
          width: double.infinity,
          height: 0.5,
          color: AppColors.border,
        ),
        if (showStamp) ...[
          const SizedBox(height: 4),
          const Text(
            'Cachet',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.additionalInfo,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            widget.document.additionalInfo!,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handlePdfAction('download'),
                icon: const Icon(Icons.download, size: 18),
                label: Text(l10n.download),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handlePdfAction('share'),
                icon: const Icon(Icons.share, size: 18),
                label: Text(l10n.share),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _handlePdfAction('print'),
                icon: const Icon(Icons.print, size: 18),
                label: Text(l10n.print),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) {
    return base64Decode(base64String);
  }
}
