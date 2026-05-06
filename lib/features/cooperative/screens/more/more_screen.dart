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
import 'package:gcoop/features/cooperative/screens/more/about_screen.dart';
import 'package:gcoop/features/cooperative/screens/more/support_screen.dart';
import 'package:gcoop/l10n/app_localizations.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _updateLogo(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.logoUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cooperativeAsync = ref.watch(cooperativeProvider);
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    const primaryBlue = Color(0xFF1E3A8A);
    const accentOrange = Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.more,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Compact Profile/Logo Header
            cooperativeAsync.when(
              data: (coop) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _updateLogo(context, ref),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                          image: coop?.logoUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(coop!.logoUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: coop?.logoUrl == null
                            ? const Icon(Icons.business, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      coop?.nameAr ?? coop?.name ?? l10n.cooperative,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const SizedBox(),
            ),

            // Grid Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildGridItem(
                    label: l10n.cooperativeInfo,
                    icon: Icons.account_balance,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CooperativeInfoScreen())),
                  ),
                  _buildGridItem(
                    label: l10n.clientsAndSuppliers,
                    icon: Icons.local_shipping,
                    onTap: () => _showContactOptions(context),
                  ),
                  _buildGridItem(
                    label: l10n.helpAndSupport,
                    icon: Icons.help_outline,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())),
                  ),
                  _buildGridItem(
                    label: l10n.settings,
                    icon: Icons.settings,
                    onTap: () => _showLanguageDialog(context, ref, locale.languageCode),
                  ),
                  _buildGridItem(
                    label: l10n.aboutApp,
                    icon: Icons.info_outline,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen())),
                  ),
                  _buildGridItem(
                    label: l10n.logout,
                    icon: Icons.logout,
                    iconColor: accentOrange,
                    labelColor: accentOrange,
                    onTap: () => Supabase.instance.client.auth.signOut(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1E3A8A),
    Color labelColor = const Color(0xFF374151),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 32),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.people_outline, color: Color(0xFF1E3A8A)),
            title: Text(l10n.clients),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ClientsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF1E3A8A)),
            title: Text(l10n.suppliers),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SuppliersScreen()));
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, String currentLang) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(l10n.language, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l10n.arabic),
            trailing: currentLang == 'ar' ? const Icon(Icons.check, color: Color(0xFF1E3A8A)) : null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale('ar');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text(l10n.french),
            trailing: currentLang == 'fr' ? const Icon(Icons.check, color: Color(0xFF1E3A8A)) : null,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale('fr');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
