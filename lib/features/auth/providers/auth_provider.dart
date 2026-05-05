import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gcoop/shared/models/profile.dart';
import 'package:gcoop/shared/models/cooperative.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  // Watch authStateProvider to re-run this provider when auth state changes
  final authState = ref.watch(authStateProvider);
  
  // Use the user from the current session or directly from Supabase client
  final user = authState.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
  
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  } catch (e) {    // If there's an error fetching the profile, we'll let the FutureProvider
    // handle the error state instead of returning null silently.
    rethrow;
  }
});

final cooperativeProvider = FutureProvider<Cooperative?>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  if (profile?.cooperativeId == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('cooperatives')
        .select()
        .eq('id', profile!.cooperativeId!)
        .maybeSingle();

    if (response == null) return null;
    return Cooperative.fromJson(response);
  } catch (e) {    return null;
  }
});

final isCooperativeSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(profileProvider.future);
  
  // Only cooperative admins need setup
  if (profile == null || profile.role != 'admin_cooperative') {
    return true;
  }

  final coop = await ref.watch(cooperativeProvider.future);
  
  if (coop == null) return false; // Needs setup
  
  // Check if nameAr is filled (as requested by user)
  return coop.nameAr != null && coop.nameAr!.isNotEmpty;
});

final mustChangePasswordProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final profile = profileAsync.value;
  
  if (profile == null) return false;
  
  // Only cooperative users are forced to change password
  if (profile.role != 'admin_cooperative') {
    return false;
  }
  
  return profile.mustChangePassword;
});
