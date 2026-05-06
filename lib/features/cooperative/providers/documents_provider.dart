import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/document.dart';
import '../../auth/providers/auth_provider.dart';

class DocumentsNotifier extends AsyncNotifier<List<AppDocument>> {
  @override
  Future<List<AppDocument>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile?.cooperativeId == null) return [];

    final response = await Supabase.instance.client
        .from('documents')
        .select('*, clients(name, phone, address), suppliers(name)')
        .eq('cooperative_id', profile!.cooperativeId!)
        .order('created_at', ascending: false);

    return (response as List).map((json) => AppDocument.fromJson(json)).toList();
  }

  Future<void> createDocument(Map<String, dynamic> data, List<Map<String, dynamic>> items) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = Supabase.instance.client;

      final docResponse = await client.from('documents').insert(data).select().single();
      final docId = docResponse['id'];

      final itemsWithDocId = items.map((item) => {
        ...item,
        'document_id': docId,
      }).toList();

      if (itemsWithDocId.isNotEmpty) {
        await client.from('document_items').insert(itemsWithDocId);
      }

      return build();
    });
  }

  Future<void> updateDocumentStatus(String documentId, String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client
          .from('documents')
          .update({'status': status})
          .eq('id', documentId);

      return build();
    });
  }

  Future<void> deleteDocument(String documentId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Supabase.instance.client
          .from('documents')
          .delete()
          .eq('id', documentId);

      return build();
    });
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<AppDocument>>(() {
  return DocumentsNotifier();
});
