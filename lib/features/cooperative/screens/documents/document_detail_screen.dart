import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/document.dart';
import 'package:gcoop/shared/models/document_item.dart';
import 'package:gcoop/shared/models/cooperative.dart';
import 'package:gcoop/core/services/pdf_service.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final response = await Supabase.instance.client
        .from('document_items')
        .select('*, products(name)')
        .eq('document_id', widget.document.id);
    
    setState(() {
      _items = (response as List).map((json) => DocumentItem.fromJson(json)).toList();
      _isLoading = false;
    });
  }

  Future<void> _handlePdfAction(String action) async {
    final profile = ref.read(profileProvider).value;
    if (profile?.cooperativeId == null) return;

    final coopResponse = await Supabase.instance.client
        .from('cooperatives')
        .select()
        .eq('id', profile!.cooperativeId!)
        .single();
    
    final cooperative = Cooperative.fromJson(coopResponse);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final pdf = await _pdfService.generateDocumentPdf(widget.document, cooperative, _items, isArabic);

    if (action == 'download') {
      final path = await _pdfService.savePdfToDevice(pdf, widget.document.number);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
    } else if (action == 'share') {
      await _pdfService.sharePdf(pdf, widget.document.number);
    } else if (action == 'print') {
      await _pdfService.printPdf(pdf);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.document.number)),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(height: 32),
                const Text('المنتجات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(item.productName ?? 'منتج غير معروف'),
                        subtitle: Text('${item.quantity} x ${item.unitPrice} DH'),
                        trailing: Text('${item.total.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                _buildTotalSection(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _ActionButton(icon: Icons.download, label: 'تحميل', color: Colors.blue, onTap: () => _handlePdfAction('download'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionButton(icon: Icons.share, label: 'مشاركة', color: Colors.green, onTap: () => _handlePdfAction('share'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionButton(icon: Icons.print, label: 'طباعة', color: Colors.orange, onTap: () => _handlePdfAction('print'))),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.document.type, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 8),
        Text('الزبون/المورد: ${widget.document.clientName ?? widget.document.supplierName ?? ""}'),
        Text('التاريخ: ${widget.document.date.toIso8601String().split("T")[0]}'),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Column(
      children: [
        const Divider(),
        _totalRow('المجموع الصافي:', '${widget.document.total.toStringAsFixed(2)} DH'),
        _totalRow('الضريبة (20%):', '${(widget.document.total * 0.2).toStringAsFixed(2)} DH'),
        _totalRow('المجموع النهائي:', '${(widget.document.total * 1.2).toStringAsFixed(2)} DH', isBold: true),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null, fontSize: isBold ? 18 : 16)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null, fontSize: isBold ? 18 : 16, color: isBold ? AppColors.primary : null)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
