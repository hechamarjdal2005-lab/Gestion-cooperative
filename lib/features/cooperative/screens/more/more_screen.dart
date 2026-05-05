import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gcoop/core/providers/locale_provider.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/core/constants/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

import 'package:gcoop/features/cooperative/screens/clients/clients_screen.dart';
import 'package:gcoop/features/cooperative/screens/suppliers/suppliers_screen.dart';
import 'package:gcoop/features/cooperative/screens/more/cooperative_info_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _updateLogo(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final profile = await ref.read(profileProvider.future);
      if (profile?.cooperativeId == null) return;

      final file = File(picked.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'logos/$fileName';

      await Supabase.instance.client.storage
          .from('company-logos')
          .upload(path, file);

      final url = Supabase.instance.client.storage
          .from('company-logos')
          .getPublicUrl(path);

      await Supabase.instance.client
          .from('cooperatives')
          .update({'logo_url': url})
          .eq('id', profile!.cooperativeId!);

      ref.invalidate(cooperativeProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final cooperativeAsync = ref.watch(cooperativeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المزيد')),
      body: ListView(
        children: [
          cooperativeAsync.when(
            data: (coop) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _updateLogo(context, ref),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: coop?.logoUrl != null
                          ? CachedNetworkImageProvider(coop!.logoUrl!)
                          : null,
                      child: coop?.logoUrl == null
                          ? const Icon(Icons.business, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    coop?.name ?? 'Cooperative',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const SizedBox(),
          ),
          _buildSectionHeader('الإدارة'),
          _buildListTile(context, Icons.people, 'الزبناء', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
          }),
          _buildListTile(context, Icons.local_shipping, 'الموردين', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SuppliersScreen()));
          }),
          _buildListTile(context, Icons.business, 'معلومات التعاونية', () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CooperativeInfoScreen()));
          }),
          const Divider(),
          _buildSectionHeader('الإعدادات'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة / Langue'),
            trailing: DropdownButton<String>(
              value: locale.languageCode,
              onChanged: (lang) {
                if (lang != null) {
                  ref.read(localeProvider.notifier).setLocale(lang);
                }
              },
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
            ),
          ),
          _buildListTile(context, Icons.backup, 'نسخة احتياطية', () {}),
          const Divider(),
          _buildListTile(context, Icons.logout, 'تسجيل الخروج', () {
            Supabase.instance.client.auth.signOut();
          }, textColor: Colors.red),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
