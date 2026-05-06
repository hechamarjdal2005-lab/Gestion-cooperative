import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/supplier.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';

class SuppliersNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('suppliers')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('name');

    return (response as List).map((json) => Supplier.fromJson(json)).toList();
  }

  Future<void> addSupplier(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('suppliers').insert(data);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateSupplier(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('suppliers').update(data).eq('id', id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteSupplier(String id) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('suppliers').delete().eq('id', id);
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

final suppliersProvider = AsyncNotifierProvider<SuppliersNotifier, List<Supplier>>(() {
  return SuppliersNotifier();
});
