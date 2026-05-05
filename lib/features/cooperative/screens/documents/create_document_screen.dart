import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/cooperative/providers/documents_provider.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';

class CreateDocumentScreen extends ConsumerStatefulWidget {
  const CreateDocumentScreen({super.key});

  @override
  ConsumerState<CreateDocumentScreen> createState() => _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends ConsumerState<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'FAC';
  String? _selectedClientId;
  List<Map<String, dynamic>> _items = [];
  bool _isSaving = false;

  void _addItem() {
    setState(() {
      _items.add({
        'product_id': null,
        'quantity': 1,
        'unit_price': 0.0,
      });
    });
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate() || _items.isEmpty) return;
    
    setState(() => _isSaving = true);
    try {
      final profile = ref.read(profileProvider).value;
      if (profile?.cooperativeId == null) return;

      final docNumber = await Supabase.instance.client.rpc('generate_document_number', params: {
        'p_cooperative_id': profile!.cooperativeId,
        'p_type': _selectedType,
      });

      final total = _items.fold(0.0, (sum, item) => sum + (item['quantity'] * item['unit_price']));

      await ref.read(documentsProvider.notifier).createDocument({
        'cooperative_id': profile.cooperativeId,
        'type': _selectedType,
        'number': docNumber,
        'client_id': _selectedClientId,
        'total': total,
        'status': 'draft',
      }, _items);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء مستند جديد')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: 'FAC', child: Text('فاتورة (FAC)')),
                      DropdownMenuItem(value: 'DEV', child: Text('عرض سعر (DEV)')),
                      DropdownMenuItem(value: 'BDC', child: Text('طلب شراء (BDC)')),
                    ],
                    onChanged: (v) => setState(() => _selectedType = v!),
                    decoration: const InputDecoration(labelText: 'نوع المستند'),
                  ),
                  const SizedBox(height: 24),
                  const Text('المنتجات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map((entry) => _buildItemRow(entry.key, entry.value)).toList(),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDocument,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ المستند'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index, Map<String, dynamic> item) {
    final products = ref.watch(productsProvider).value ?? [];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            value: item['product_id'],
            items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
            onChanged: (v) {
              final product = products.firstWhere((p) => p.id == v);
              setState(() {
                _items[index]['product_id'] = v;
                _items[index]['unit_price'] = product.price;
              });
            },
            decoration: const InputDecoration(hintText: 'المنتج'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: TextFormField(
            initialValue: item['quantity'].toString(),
            keyboardType: TextInputType.number,
            onChanged: (v) => _items[index]['quantity'] = int.tryParse(v) ?? 1,
            decoration: const InputDecoration(hintText: 'الكمية'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => setState(() => _items.removeAt(index)),
        ),
      ],
    );
  }
}
