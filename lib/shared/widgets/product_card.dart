import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gcoop/features/cooperative/providers/products_provider.dart';
import 'package:gcoop/features/cooperative/screens/products/product_form_screen.dart';

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
        content: const Text('هل أنت متأكد أنك تريد حذف هذا المنتج؟', textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(productsProvider.notifier).deleteProduct(product.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف المنتج بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool lowStock = product.stock <= product.minStock;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: product.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.photoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[100]),
                      errorWidget: (context, url, error) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[100],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'تصنيف عام',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductFormScreen(product: product),
                            ),
                          );
                        } else if (value == 'delete') {
                          _showDeleteDialog(context, ref);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('تعديل'),
                              SizedBox(width: 8),
                              Icon(Icons.edit, size: 18),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('حذف', style: TextStyle(color: Colors.red)),
                              SizedBox(width: 8),
                              Icon(Icons.delete, size: 18, color: Colors.red),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${NumberFormat('#,##0.00', 'en_US').format(product.price)} DH',
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'المخزون: ${product.stock}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: lowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lowStock ? 'منخفض' : 'متوفر',
                        style: TextStyle(
                          color: lowStock ? Colors.red : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
