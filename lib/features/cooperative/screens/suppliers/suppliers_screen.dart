import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/features/cooperative/screens/suppliers/add_supplier_screen.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموردين')),
      body: FutureBuilder(
        future: _fetchSuppliers(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final suppliers = snapshot.data as List<dynamic>;
          if (suppliers.isEmpty) {
            return const Center(child: Text('لا يوجد موردين حاليا'));
          }
          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              return ListTile(
                title: Text(supplier['name']),
                subtitle: Text(supplier['phone'] ?? ''),
                leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSupplierScreen()),
          ).then((_) => ref.invalidate(profileProvider)); // Refresh trigger
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<dynamic>> _fetchSuppliers(WidgetRef ref) async {
    final profile = await ref.read(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('suppliers')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('name');
    
    return response as List<dynamic>;
  }
}
