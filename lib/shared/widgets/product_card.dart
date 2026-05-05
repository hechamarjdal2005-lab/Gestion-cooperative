import 'package:flutter/material.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final bool lowStock = product.stock <= product.minStock;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: product.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.photoUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.price.toStringAsFixed(2)} DH',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('المخزون: ${product.stock}', style: TextStyle(fontSize: 12, color: lowStock ? Colors.red : Colors.grey[600])),
                    if (lowStock)
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
