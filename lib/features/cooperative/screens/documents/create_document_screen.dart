import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/cooperative/providers/documents_provider.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/features/cooperative/providers/clients_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/shared/models/document.dart';
import 'package:gcoop/shared/models/client.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:gcoop/core/services/pdf_service.dart';
import 'package:gcoop/core/utils/amount_to_words.dart';
import 'package:gcoop/shared/models/cooperative.dart';
import 'package:gcoop/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class CreateDocumentScreen extends ConsumerStatefulWidget {
  final AppDocument? document;
  const CreateDocumentScreen({super.key, this.document});

  @override
  ConsumerState<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends ConsumerState<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late String _docName;
  Client? _selectedClient;
  List<DocumentItem> _items = [];
  bool _isSaving = false;
  late String _paymentMethod;
  late double _discount;
  late double _tvaRate;
  late double _deliveryFees;
  late String _deliveryLocation;
  late String _deliveryDelay;
  late String _notes;
  late DateTime _selectedDate;

  final _pdfService = PdfService();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.document?.type ?? 'FAC';
    _docName = widget.document?.name ?? '';
    _paymentMethod = widget.document?.paymentMethod ?? 'Espèces';
    _discount = widget.document?.discount ?? 0;
    _tvaRate = widget.document?.tvaRate ?? 0;
    _deliveryFees = widget.document?.deliveryFees ?? 0;
    _deliveryLocation = widget.document?.deliveryLocation ?? '';
    _deliveryDelay = widget.document?.deliveryDelay ?? '';
    _notes = widget.document?.notes ?? '';
    _selectedDate = widget.document?.date ?? DateTime.now();
    
    if (widget.document != null) {
      _loadDocumentData();
    }
  }

  Future<void> _loadDocumentData() async {
    try {
      // Load Client
      if (widget.document!.clientId != null) {
        final clients = await ref.read(clientsProvider.future);
        _selectedClient = clients.firstWhere((c) => c.id == widget.document!.clientId);
      }

      // Load Items
      final itemsResponse = await Supabase.instance.client
          .from('document_items')
          .select()
          .eq('document_id', widget.document!.id);
      
      if (mounted) {
        setState(() {
          _items = (itemsResponse as List).map((json) => DocumentItem.fromJson(json)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading document data: $e');
    }
  }

  void _addItem() {
    setState(() {
      _items.add(DocumentItem(
        quantity: 1,
        unit: 'Pièce',
        unitPrice: 0,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectClient() async {
    final clients = await ref.read(clientsProvider.future);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: ListView.builder(
          itemCount: clients.length,
          itemBuilder: (context, index) {
            final client = clients[index];
            return ListTile(
              title: Text(client.name),
              subtitle: Text('${client.phone} - ${client.address}'),
              onTap: () {
                setState(() => _selectedClient = client);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectProduct(int index) async {
    final products = await ref.read(productsProvider.future);
    if (!mounted) return;

    final selected = await showModalBottomSheet<Product?>(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, i) {
            final product = products[i];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('${product.price.toStringAsFixed(2)} DH'),
              onTap: () => Navigator.pop(context, product),
            );
          },
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _items[index] = DocumentItem(
          productId: selected.id,
          productRef: selected.id.substring(0, 8).toUpperCase(),
          description: selected.name,
          quantity: _items[index].quantity,
          unit: _items[index].unit,
          unitPrice: selected.price,
          productName: selected.name,
        );
      });
    }
  }

  double get _subtotal {
    return _items.fold<double>(0, (sum, item) => sum + item.total);
  }

  double get _discountAmount => _subtotal * (_discount / 100);
  double get _afterDiscount => _subtotal - _discountAmount;
  double get _tvaAmount => _afterDiscount * (_tvaRate / 100);
  double get _total => _afterDiscount + _tvaAmount + _deliveryFees;

  String get _docNumberPrefix {
    final now = DateTime.now();
    final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    switch (_selectedType) {
      case 'FAC':
        return 'FAC-$dateStr';
      case 'BDL':
        return 'BL-$dateStr';
      case 'BDC':
        return 'CMD-$dateStr';
      case 'DEV':
        return 'DEV-$dateStr';
      default:
        return 'DOC-$dateStr';
    }
  }

  Future<void> _saveDocument({bool shareAfter = false}) async {
    if (!_formKey.currentState!.validate() || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_selectedClient == null
              ? (AppLocalizations.of(context)?.selectClient ?? 'Veuillez sélectionner un client')
              : 'Veuillez ajouter des produits'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final profile = ref.read(profileProvider).value;
      if (profile?.cooperativeId == null) return;

      String docNumber;
      if (widget.document != null) {
        docNumber = widget.document!.number;
      } else {
        docNumber = await PdfService.getNextDocumentNumber(_selectedType, profile!.cooperativeId!);
      }

      final docData = {
        'cooperative_id': profile?.cooperativeId,
        'type': _selectedType,
        'number': docNumber,
        'name': _docName,
        'client_id': _selectedClient!.id,
        'total': _total,
        'discount': _discount,
        'tva_rate': _tvaRate,
        'tva_amount': _tvaAmount,
        'delivery_fees': _deliveryFees,
        'date': _selectedDate.toIso8601String(),
        'status': 'draft',
        'payment_method': _paymentMethod,
        'delivery_location': _deliveryLocation.isNotEmpty ? _deliveryLocation : null,
        'delivery_delay': _deliveryDelay.isNotEmpty ? _deliveryDelay : null,
        'notes': _notes.isNotEmpty ? _notes : null,
        'additional_info': _notes.isNotEmpty ? _notes : null,
      };

      final itemsData = _items.map((item) => {
        'product_id': item.productId,
        'product_ref': item.productRef,
        'description': item.description,
        'quantity': item.quantity,
        'unit': item.unit,
        'unit_price': item.unitPrice,
      }).toList();

      if (widget.document != null) {
        await ref.read(documentsProvider.notifier).updateDocument(widget.document!.id, docData, itemsData);
      } else {
        await ref.read(documentsProvider.notifier).createDocument(docData, itemsData);
      }

      if (shareAfter && mounted) {
        await _shareLastDocument(profile?.cooperativeId ?? '', docNumber, itemsData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.save ?? 'Document enregistré'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _shareLastDocument(String coopId, String docNumber, List<Map<String, dynamic>> itemsData) async {
    try {
      final response = await Supabase.instance.client
          .from('documents')
          .select('*, clients(name, phone, address)')
          .eq('cooperative_id', coopId)
          .eq('number', docNumber)
          .single();

      final document = AppDocument.fromJson(response);
      document.items = itemsData.map((e) => DocumentItem(
        productId: e['product_id'],
        productRef: e['product_ref'] ?? '',
        description: e['description'] ?? '',
        quantity: e['quantity'],
        unit: e['unit'] ?? 'Pièce',
        unitPrice: (e['unit_price'] as num).toDouble(),
      )).toList();

      final coopResponse = await Supabase.instance.client
          .from('cooperatives')
          .select()
          .eq('id', coopId)
          .single();

      final cooperative = Cooperative.fromJson(coopResponse);
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';

      final pdf = await _pdfService.generateDocumentPdf(
        document: document,
        cooperative: cooperative,
        items: document.items,
        isArabic: isArabic,
      );

      await _pdfService.sharePdf(pdf, docNumber);
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
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
        title: Text(l10n.newDocument),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard(
                    children: [
                      _buildTypeSelector(l10n),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _docName,
                        decoration: InputDecoration(
                          labelText: isRtl ? 'اسم المستند' : 'Nom du document',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        validator: (v) => v == null || v.isEmpty ? (isRtl ? 'هذا الحقل مطلوب' : 'Ce champ est obligatoire') : null,
                        onChanged: (v) => _docName = v,
                      ),
                      const SizedBox(height: 12),
                      _buildDateField(l10n),
                      const SizedBox(height: 12),
                      _buildClientSelector(l10n),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_selectedType == 'FAC' || _selectedType == 'BDC') ...[
                    _buildCard(
                      children: [
                        _buildPaymentMethodField(l10n),
                        const SizedBox(height: 12),
                        _buildDiscountField(l10n),
                        const SizedBox(height: 12),
                        _buildTvaField(l10n),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_selectedType == 'BDC') ...[
                    _buildCard(
                      children: [
                        _buildDeliveryDelayField(l10n),
                        const SizedBox(height: 12),
                        _buildDeliveryFeesField(l10n),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_selectedType == 'BDL') ...[
                    _buildCard(
                      children: [
                        _buildDeliveryLocationField(l10n),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildCard(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.products,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          IconButton(
                            onPressed: _addItem,
                            icon: const Icon(Icons.add_circle, color: AppColors.accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value, l10n)).toList(),
                      if (_items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              l10n.addItem,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTotalsCard(l10n),
                  ],
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      TextFormField(
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.notes,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (v) => _notes = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            _buildBottomActions(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTypeSelector(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: l10n.documentType,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem(value: 'FAC', child: Text(l10n.invoice)),
        DropdownMenuItem(value: 'BDL', child: Text(l10n.deliveryNote)),
        DropdownMenuItem(value: 'BDC', child: Text(l10n.purchaseOrder)),
      ],
      onChanged: (v) => setState(() => _selectedType = v!),
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.date,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
      ),
    );
  }

  Widget _buildClientSelector(AppLocalizations l10n) {
    return InkWell(
      onTap: _selectClient,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.selectClient,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: const Icon(Icons.person_search, size: 18),
        ),
        child: _selectedClient != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedClient!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_selectedClient!.phone} - ${_selectedClient!.address}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              )
            : Text(l10n.selectClient, style: TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildPaymentMethodField(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: InputDecoration(
        labelText: l10n.paymentMethod,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem(value: 'Espèces', child: Text(l10n.cash)),
        DropdownMenuItem(value: 'Virement', child: Text(l10n.transfer)),
        DropdownMenuItem(value: 'Chèque', child: Text(l10n.check)),
      ],
      onChanged: (v) => setState(() => _paymentMethod = v!),
    );
  }

  Widget _buildDiscountField(AppLocalizations l10n) {
    return TextFormField(
      initialValue: _discount.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.discount,
        suffixText: '%',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
    );
  }

  Widget _buildTvaField(AppLocalizations l10n) {
    return TextFormField(
      initialValue: _tvaRate.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.tva,
        suffixText: '%',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (v) => setState(() => _tvaRate = double.tryParse(v) ?? 0),
    );
  }

  Widget _buildDeliveryFeesField(AppLocalizations l10n) {
    return TextFormField(
      initialValue: _deliveryFees.toString(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: l10n.deliveryFees,
        suffixText: 'DH',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (v) => setState(() => _deliveryFees = double.tryParse(v) ?? 0),
    );
  }

  Widget _buildDeliveryLocationField(AppLocalizations l10n) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: l10n.deliveryLocation,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (v) => _deliveryLocation = v,
    );
  }

  Widget _buildDeliveryDelayField(AppLocalizations l10n) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: l10n.deliveryDelay,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: (v) => _deliveryDelay = v,
    );
  }

  Widget _buildItemRow(int index, DocumentItem item, AppLocalizations l10n) {
    final hasProduct = item.productId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasProduct ? AppColors.clientSectionBg : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectProduct(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      hasProduct ? item.description : l10n.selectProduct,
                      style: TextStyle(
                        color: hasProduct ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: hasProduct ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.quantity,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                  onChanged: (v) {
                    final qty = int.tryParse(v) ?? 1;
                    setState(() => _items[index] = item.copyWith(quantity: qty));
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (hasProduct)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.total.toStringAsFixed(2)} DH',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(AppLocalizations l10n) {
    return _buildCard(
      children: [
        _totalRow(l10n.subtotal, '${_subtotal.toStringAsFixed(2)} DH'),
        if (_discount > 0)
          _totalRow('${l10n.discount} ($_discount%)', '-${_discountAmount.toStringAsFixed(2)} DH', isNegative: true),
        if (_tvaRate > 0)
          _totalRow('${l10n.tva} ($_tvaRate%)', '${_tvaAmount.toStringAsFixed(2)} DH'),
        if (_deliveryFees > 0)
          _totalRow(l10n.deliveryFees, '${_deliveryFees.toStringAsFixed(2)} DH'),
        const Divider(height: 16),
        _totalRow(l10n.totalToPay, '${_total.toStringAsFixed(2)} DH', isTotal: true),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.clientSectionBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${l10n.amountInWords}: ${AmountToWords.withCurrency(_total)}',
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primary),
          ),
        ),
      ],
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
                onPressed: _isSaving ? null : () => _saveDocument(),
                icon: const Icon(Icons.save, size: 18),
                label: Text(l10n.save),
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
                onPressed: _isSaving ? null : () => _saveDocument(shareAfter: true),
                icon: const Icon(Icons.share, size: 18),
                label: Text(l10n.saveAndShare),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DocumentItemCopyWith on DocumentItem {
  DocumentItem copyWith({
    String? productId,
    String? productRef,
    String? description,
    int? quantity,
    String? unit,
    double? unitPrice,
    String? productName,
  }) {
    return DocumentItem(
      id: id,
      documentId: documentId,
      productId: productId ?? this.productId,
      productRef: productRef ?? this.productRef,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      productName: productName ?? this.productName,
    );
  }
}
