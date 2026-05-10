import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gcoop/features/cooperative/providers/documents_provider.dart';
import 'package:gcoop/features/cooperative/screens/documents/create_document_screen.dart';
import 'package:gcoop/features/cooperative/screens/documents/document_detail_screen.dart';
import 'package:gcoop/shared/models/document.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  String _searchQuery = '';
  int _selectedTab = 0; // 0: All, 1: Paid, 2: Unpaid

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AppDocument>> documentsAsync = ref.watch(documentsProvider);
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);
    const orangeAction = Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          l10n.documents,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateDocumentScreen()),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: l10n.searchDocument,
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.filter_list, color: primaryBlue),
                    suffixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabItem(l10n.all, 0),
                    _buildTabItem(l10n.paid, 1),
                    _buildTabItem(l10n.unpaid, 2),
                  ],
                ),
              ],
            ),
          ),
          // Documents List
          Expanded(
            child: switch (documentsAsync) {
              AsyncData(value: final docs) => (() {
                  if (docs.isEmpty) {
                    return Center(child: Text(l10n.noDocuments));
                  }

                  // Apply search and tab filters
                  final filtered = docs.where((doc) {
                    // Search filter
                    final matchesSearch = _searchQuery.isEmpty ||
                        doc.number.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        (doc.clientName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                    
                    if (!matchesSearch) return false;

                    // Tab filter
                    if (_selectedTab == 1) return doc.status == 'validated';
                    if (_selectedTab == 2) return doc.status != 'validated';
                    
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text(l10n.noResults));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildDocumentCard(context, filtered[index]),
                  );
                })(),
              AsyncError(:final error) => Center(child: Text('${l10n.error}: $error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateDocumentScreen()),
        ),
        backgroundColor: orangeAction,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    const primaryBlue = Color(0xFF1E3A8A);
    final isActive = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? primaryBlue : Colors.grey,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              height: 2,
              width: 40,
              color: primaryBlue,
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppDocument doc) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete, textAlign: TextAlign.right),
        content: Text(l10n.confirmDeleteDocument, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(documentsProvider.notifier).deleteDocument(doc.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.documentDeleted)),
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

  Widget _buildDocumentCard(BuildContext context, AppDocument doc) {
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);
    final isPaid = doc.status == 'validated';
    final isDraft = doc.status == 'draft';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DocumentDetailScreen(document: doc)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (isDraft)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateDocumentScreen(document: doc)),
                            );
                          } else if (value == 'delete') {
                            _showDeleteDialog(context, doc);
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
                    Text(
                      doc.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc.type,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${NumberFormat('#,##0.00', 'en_US').format(doc.total)} DH',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doc.type == 'FAC' || doc.type == 'BDL' 
                      ? '${l10n.client}: ${doc.clientName ?? l10n.unknown}'
                      : '${l10n.supplier}: ${doc.supplierName ?? l10n.unknown}',
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                Text(
                  _formatDate(context, doc.date),
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPaid)
                        const Icon(Icons.bolt, color: Colors.red, size: 14),
                      Text(
                        isPaid ? l10n.paid : l10n.unpaid,
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  doc.typeLabel,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(date);
    if (diff.inDays == 1) return l10n.yesterday;
    return DateFormat('yyyy/MM/dd').format(date);
  }
}
