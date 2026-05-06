import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/suppliers_provider.dart';
import 'package:gcoop/features/cooperative/screens/suppliers/add_supplier_screen.dart';
import 'package:gcoop/shared/models/supplier.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _searchQuery = '';
  final Color primaryBlue = const Color(0xFF1A3A6B);
  final Color orangeAction = const Color(0xFFFF6B35);
  final Color lightBlueBg = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          l10n.suppliers,
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
                hintText: l10n.searchSupplier,
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
          // Suppliers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(suppliersProvider.notifier).refresh(),
              child: suppliersAsync.when(
                data: (suppliers) {
                  final filteredSuppliers = suppliers.where((supplier) {
                    return supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        supplier.phone.contains(_searchQuery);
                  }).toList();

                  if (suppliers.isEmpty) {
                    return _buildEmptyState(l10n.noSuppliers);
                  }

                  if (filteredSuppliers.isEmpty) {
                    return _buildEmptyState(l10n.noResults);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredSuppliers.length,
                    itemBuilder: (context, index) => _buildSupplierCard(filteredSuppliers[index]),
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
          MaterialPageRoute(builder: (context) => const AddSupplierScreen()),
        ).then((_) => ref.read(suppliersProvider.notifier).refresh()),
        backgroundColor: orangeAction,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Supplier supplier) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: TextAlign.right),
        content: Text(l10n.confirmDeleteSupplier, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(suppliersProvider.notifier).deleteSupplier(supplier.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.supplierDeleted)),
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

  Widget _buildSupplierCard(Supplier supplier) {
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
                MaterialPageRoute(builder: (context) => AddSupplierScreen(supplier: supplier)),
              ).then((_) => ref.read(suppliersProvider.notifier).refresh());
            } else if (value == 'delete') {
              _showDeleteDialog(context, supplier);
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
          supplier.name,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          supplier.phone,
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: CircleAvatar(
          backgroundColor: lightBlueBg,
          child: Text(
            supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Handle supplier details if needed
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade300),
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
