import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/clients_provider.dart';
import 'package:gcoop/features/cooperative/screens/clients/add_client_screen.dart';
import 'package:gcoop/shared/models/client.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  String _searchQuery = '';
  final Color primaryBlue = const Color(0xFF1A3A6B);
  final Color orangeAction = const Color(0xFFFF6B35);
  final Color lightBlueBg = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          l10n.clients,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: l10n.searchClient,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: primaryBlue),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Clients List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(clientsProvider.notifier).refresh(),
              child: clientsAsync.when(
                data: (clients) {
                  final filteredClients = clients.where((client) {
                    return client.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        client.phone.contains(_searchQuery);
                  }).toList();

                  if (clients.isEmpty) {
                    return _buildEmptyState(l10n.noClients);
                  }

                  if (filteredClients.isEmpty) {
                    return _buildEmptyState(l10n.noResults);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) => _buildClientCard(filteredClients[index]),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddClientScreen()),
        ).then((_) => ref.read(clientsProvider.notifier).refresh()),
        backgroundColor: orangeAction,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Client client) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: TextAlign.right),
        content: Text(l10n.confirmDeleteClient, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(clientsProvider.notifier).deleteClient(client.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.clientDeleted)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey.shade400),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddClientScreen(client: client)),
              ).then((_) => ref.read(clientsProvider.notifier).refresh());
            } else if (value == 'delete') {
              _showDeleteDialog(context, client);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(l10n.edit),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 18),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                  const SizedBox(width: 8),
                  const Icon(Icons.delete, size: 18, color: Colors.red),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          client.name,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          client.phone,
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: CircleAvatar(
          backgroundColor: lightBlueBg,
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Handle client details if needed
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
