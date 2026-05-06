import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/client.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';

class ClientsNotifier extends AsyncNotifier<List<Client>> {
  @override
  Future<List<Client>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('clients')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('name');

    return (response as List).map((json) => Client.fromJson(json)).toList();
  }

  Future<void> addClient(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('clients').insert(data);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> updateClient(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('clients').update(data).eq('id', id);
      ref.invalidateSelf();
      await future;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  Future<void> deleteClient(String id) async {
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('clients').delete().eq('id', id);
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

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, List<Client>>(() {
  return ClientsNotifier();
});
