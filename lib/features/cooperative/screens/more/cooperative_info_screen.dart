import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CooperativeInfoScreen extends ConsumerWidget {
  const CooperativeInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cooperativeAsync = ref.watch(cooperativeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('معلومات التعاونية')),
      body: cooperativeAsync.when(
        data: (coop) {
          if (coop == null) return const Center(child: Text('لا توجد بيانات'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (coop.logoUrl != null)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: CachedNetworkImageProvider(coop.logoUrl!),
                  )
                else
                  const CircleAvatar(
                    radius: 60,
                    child: Icon(Icons.business, size: 60),
                  ),
                const SizedBox(height: 24),
                _buildInfoCard(context, [
                  _buildInfoRow('الاسم (AR)', coop.nameAr ?? '-'),
                  _buildInfoRow('الاسم (FR)', coop.nameFr ?? '-'),
                  _buildInfoRow('العنوان', coop.address ?? '-'),
                  _buildInfoRow('الهاتف', coop.phone ?? '-'),
                  _buildInfoRow('البريد الإلكتروني', coop.email ?? '-'),
                  _buildInfoRow('ICE', coop.ice ?? '-'),
                  _buildInfoRow('RC', coop.rc ?? '-'),
                ]),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
