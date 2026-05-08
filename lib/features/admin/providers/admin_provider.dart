import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/cooperative.dart';
import 'package:gcoop/shared/models/profile.dart';

final supabase = Supabase.instance.client;

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final coopsCount = await supabase.from('cooperatives').count();
  
  final invoicesCount = await supabase
      .from('documents')
      .count()
      .eq('type', 'FAC');
      
  final profilesCount = await supabase.from('profiles').count();
  
  final productsCount = await supabase.from('products').count();
  
  final revenueResponse = await supabase
      .from('documents')
      .select('total')
      .eq('type', 'FAC')
      .eq('status', 'validated');
      
  double totalRevenue = 0;
  if (revenueResponse is List) {
    for (var doc in revenueResponse) {
      totalRevenue += (doc['total'] as num).toDouble();
    }
  }

  return {
    'cooperatives': coopsCount,
    'invoices': invoicesCount,
    'profiles': profilesCount,
    'products': productsCount,
    'revenue': totalRevenue,
  };
});

final recentCooperativesProvider = FutureProvider<List<Cooperative>>((ref) async {
  final response = await supabase
      .from('cooperatives')
      .select()
      .order('id', ascending: false) // Assuming id or created_at
      .limit(5);
      
  return (response as List).map((json) => Cooperative.fromJson(json)).toList();
});

final allCooperativesProvider = FutureProvider<List<Cooperative>>((ref) async {
  final response = await supabase
      .from('cooperatives')
      .select()
      .order('name');
      
  return (response as List).map((json) => Cooperative.fromJson(json)).toList();
});

final allProfilesProvider = FutureProvider<List<Profile>>((ref) async {
  final response = await supabase
      .from('profiles')
      .select()
      .eq('role', 'admin_cooperative')
      .order('full_name');
      
  return (response as List).map((json) => Profile.fromJson(json)).toList();
});
