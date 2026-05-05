import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/product.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('products')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('name');
    
    return (response as List).map((json) => Product.fromJson(json)).toList();
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('products').insert(data);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});
