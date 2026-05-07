import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/expense.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('expenses')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('date', ascending: false);
    
    return (response as List).map((json) => Expense.fromJson(json)).toList();
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.from('expenses').insert(data);
      return build();
    });
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.from('expenses').update(data).eq('id', id);
      return build();
    });
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client.from('expenses').delete().eq('id', id);
      return build();
    });
  }
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(() {
  return ExpensesNotifier();
});
