import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/income.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';

class IncomesNotifier extends AsyncNotifier<List<Income>> {
  @override
  Future<List<Income>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('incomes')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('date', ascending: false);
    
    return (response as List).map((json) => Income.fromJson(json)).toList();
  }

  Future<void> addIncome(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final profile = await ref.read(profileProvider.future);
      if (profile?.cooperativeId != null) {
        data['cooperative_id'] = profile!.cooperativeId;
      }
      await Supabase.instance.client.from('incomes').insert(data);
      return build();
    });
  }

  Future<void> updateIncome(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.from('incomes').update(data).eq('id', id);
      return build();
    });
  }

  Future<void> deleteIncome(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.from('incomes').delete().eq('id', id);
      return build();
    });
  }
}

final incomesProvider = AsyncNotifierProvider<IncomesNotifier, List<Income>>(() {
  return IncomesNotifier();
});
