import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gcoop/features/auth/screens/login_screen.dart';
import 'package:gcoop/features/auth/screens/setup_cooperative_screen.dart';
import 'package:gcoop/features/auth/screens/change_password_screen.dart';
import 'package:gcoop/features/admin/screens/admin_dashboard_screen.dart';
import 'package:gcoop/features/cooperative/screens/main_screen.dart';
import 'package:gcoop/features/auth/providers/auth_provider.dart';
import 'package:gcoop/features/auth/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);
  final profileAsync = ref.watch(profileProvider);
  final setupCompleteAsync = ref.watch(isCooperativeSetupCompleteProvider);
  final mustChangePassword = ref.watch(mustChangePasswordProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final user = Supabase.instance.client.auth.currentUser;
      final isSplashing = state.matchedLocation == '/splash';
      final isLoggingIn = state.matchedLocation == '/login';
      final isSetup = state.matchedLocation == '/setup';
      final isChangingPassword = state.matchedLocation == '/change-password';

      // 0. إذا كان في صفحة البداية (Splash)، ابقَ فيها حتى تنتهي الـ 3 ثواني
      if (isSplashing) {
        return null;
      }

      // 1. غير مسجل الدخول -> اذهب للدخول
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. انتظر تحميل البيانات
      if (profileAsync.isLoading || setupCompleteAsync.isLoading) {
        return null; 
      }

      // 3. الأولوية الأولى: تغيير كلمة المرور
      if (mustChangePassword) {
        return isChangingPassword ? null : '/change-password';
      }

      // 4. الأولوية الثانية: إعداد التعاونية (المنطق الصارم)
      if (profileAsync.hasValue) {
        final profile = profileAsync.value;
        
        if (profile != null && profile.role == 'admin_cooperative') {
          final isSetupComplete = setupCompleteAsync.value ?? false;
          
          // إذا لم يكمل الإعداد -> اجبره على الذهاب لـ /setup
          if (!isSetupComplete) {
            return isSetup ? null : '/setup';
          }
          
          // إذا أكمل الإعداد وهو يحاول الدخول لصفحة الإعداد، وجهه للرئيسية
          if (isSetup) {
            return '/';
          }
        }
      }

      // 5. تنظيف المسارات الأخرى
      if (isChangingPassword || isSetup) {
        return '/';
      }
      
      // 6. إذا كان في صفحة الدخول ومسجل دخول، وجهه للرئيسية
      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupCooperativeScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          // التصحيح هنا: إضافة data: قبل الدالة
          return profileAsync.when(
            data: (profile) {
              if (profile == null) return const LoginScreen();
              if (profile.role == 'admin') {
                return const AdminDashboardScreen();
              } else {
                return const MainScreen();
              }
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (e, s) => Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('خطأ: $e'),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(profileProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
});