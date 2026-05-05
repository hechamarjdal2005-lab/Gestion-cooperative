import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'dart:io';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  
  File? _imageFile;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _uploadImage(String cooperativeId) async {
    if (_imageFile == null) return null;
    
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'products/$fileName';
      
      await Supabase.instance.client.storage
          .from('product-photos')
          .upload(path, _imageFile!);
          
      final url = Supabase.instance.client.storage
          .from('product-photos')
          .getPublicUrl(path);
          
      return url;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final profile = await ref.read(profileProvider.future);
      if (profile?.cooperativeId == null) throw 'Cooperative ID not found';

      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage(profile!.cooperativeId!);
      }

      await ref.read(productsProvider.notifier).addProduct({
        'cooperative_id': profile!.cooperativeId,
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'stock': int.parse(_stockController.text),
        'min_stock': int.parse(_minStockController.text),
        'photo_url': photoUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم المنتج'),
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'الثمن (DH)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(labelText: 'الكمية في المخزون'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minStockController,
              decoration: const InputDecoration(labelText: 'الحد الأدنى للتنبيه'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ المنتج'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
