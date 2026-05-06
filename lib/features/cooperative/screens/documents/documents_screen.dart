import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/documents_provider.dart';
import 'package:gcoop/shared/widgets/document_tile.dart';
import 'package:gcoop/features/cooperative/screens/documents/create_document_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.documentsList),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.all),
              Tab(text: l10n.invoices),
              Tab(text: l10n.deliveryNote),
              Tab(text: l10n.purchaseOrder),
              Tab(text: l10n.quote),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateDocumentScreen()),
              ),
            ),
          ],
        ),
        body: documentsAsync.when(
          data: (docs) => TabBarView(
            children: [
              _DocumentList(documents: docs),
              _DocumentList(documents: docs.where((d) => d.type == 'FAC').toList()),
              _DocumentList(documents: docs.where((d) => d.type == 'BDL').toList()),
              _DocumentList(documents: docs.where((d) => d.type == 'BDC').toList()),
              _DocumentList(documents: docs.where((d) => d.type == 'DEV').toList()),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final List<dynamic> documents;
  const _DocumentList({required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const Center(child: Text('No documents'));
    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) => DocumentTile(document: documents[index]),
    );
  }
}
