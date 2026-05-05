import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/cooperative/providers/documents_provider.dart';
import 'package:gcoop/shared/widgets/document_tile.dart';
import 'package:gcoop/features/cooperative/screens/documents/create_document_screen.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الفواتير و المستندات'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'الكل'),
              Tab(text: 'فواتير (FAC)'),
              Tab(text: 'عروض (DEV)'),
              Tab(text: 'طلبات (BDC)'),
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
              _DocumentList(documents: docs.where((d) => d.type == 'DEV').toList()),
              _DocumentList(documents: docs.where((d) => d.type == 'BDC').toList()),
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
    if (documents.isEmpty) return const Center(child: Text('لا توجد مستندات'));
    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) => DocumentTile(document: documents[index]),
    );
  }
}
