import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/features/cooperative/screens/clients/add_client_screen.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('الزبناء')),
      body: FutureBuilder(
        future: _fetchClients(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final clients = snapshot.data as List<dynamic>;
          if (clients.isEmpty) {
            return const Center(child: Text('لا يوجد زبناء حاليا'));
          }
          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                title: Text(client['name']),
                subtitle: Text(client['phone']),
                leading: const CircleAvatar(child: Icon(Icons.person)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddClientScreen()),
          ).then((_) => ref.invalidate(profileProvider)); // Simple way to refresh
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<dynamic>> _fetchClients(WidgetRef ref) async {
    final profile = await ref.read(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('clients')
        .select()
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('name');
    
    return response as List<dynamic>;
  }
}
