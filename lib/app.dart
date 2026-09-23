import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/dark_theme.dart';
import 'core/theme/light_theme.dart';
import 'features/language/language_screen.dart';
import 'l10n/app_strings.dart';
import 'providers/locale_provider.dart';
import 'features/admin/admin_login_screen.dart';
import 'features/admin/commerce_admin_screen.dart';
import 'features/checkout/payment_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/categories_manager/admin_categories_screen.dart';
import 'features/admin/dashboard/admin_dashboard_screen.dart';
import 'features/admin/orders_manager/admin_orders_screen.dart';
import 'features/admin/products_manager/admin_products_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/favorites/favorites_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/product_detail/product_detail_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/shell/client_shell.dart';
import 'providers/core_providers.dart';
import 'services/supabase_service.dart';
import 'providers/theme_provider.dart';
import 'features/profile/account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;

/// Rebuild router la lè auth chanje (login/logout).
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Stream<AuthState> stream) {
    _sub = stream.listen((state) {
      if (state.event == AuthChangeEvent.passwordRecovery) recovering = true;
      if (state.event == AuthChangeEvent.userUpdated || state.event == AuthChangeEvent.signedOut) recovering = false;
      notifyListeners();
    });
  }

  bool recovering = false;
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final store = ref.watch(localStoreProvider);
  final refresh = _AuthRefreshListenable(
    SupabaseService.client.auth.onAuthStateChange,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final path = state.uri.path;
      final languageChosen = store.languageChosen;
      final onboardingDone = store.onboardingDone;
      final user = SupabaseService.client.auth.currentUser;
      final loggedIn = user != null && !user.isAnonymous;
      if (refresh.recovering && loggedIn && path != '/account/password') return '/account/password';
      if (path.startsWith('/legal/')) return null;

      // Zòn admin: login obligatwa (verifikasyon admin fèt nan AdminShell)
      // Pa pase nan onboarding oswa language picker si se nan admin itilizatè a prale
      if (path.startsWith('/admin')) {
        if (path == '/admin/login') return loggedIn ? '/admin' : null;
        if (!loggedIn) return '/admin/login';
        return null;
      }

      // Sou Web, pa fòse onboarding oswa seleksyon lang mobil
      if (kIsWeb && (path == '/language' || path == '/onboarding')) {
        return loggedIn ? '/' : '/auth';
      }

      // Seleksyon lang anvan tout bagay (premye lanse sou mobil)
      if (!kIsWeb) {
        if (!languageChosen && path != '/language') return '/language';
        if (languageChosen && path == '/language') return '/onboarding';

        // Onboarding anvan tout bagay sou mobil
        if (!onboardingDone && path != '/onboarding' && path != '/language') {
          return '/onboarding';
        }
        if (onboardingDone && path == '/onboarding') return loggedIn ? '/' : '/auth';
      }

      if (!loggedIn && (path.startsWith('/account/') || path.startsWith('/payment/') || path == '/checkout' || path == '/orders')) {
        return '/auth?redirect=${Uri.encodeComponent(path)}';
      }
      if (!loggedIn && !store.guestMode && path != '/auth' && path != '/language' && path != '/onboarding') return '/auth';

      // Deja konekte: pa bezwen wè paj auth la
      if (loggedIn && path == '/auth') {
        final target = state.uri.queryParameters['redirect'];
        return target != null && target.startsWith('/') && !target.startsWith('//') && !target.startsWith('/auth') ? target : '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/account/:section',
        builder: (context, state) => AccountScreen(section: state.pathParameters['section']!),
      ),
      GoRoute(
        path: '/legal/:kind',
        builder: (context, state) => LegalScreen(kind: state.pathParameters['kind']!),
      ),
      GoRoute(
        path: '/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            AuthScreen(redirect: state.uri.queryParameters['redirect']),
      ),

      // --- Panel admin (web) ---
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/products',
            builder: (context, state) => const AdminProductsScreen(),
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (context, state) => const AdminCategoriesScreen(),
          ),
          GoRoute(
            path: '/admin/commerce',
            builder: (context, state) => const CommerceAdminScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
        ],
      ),

      // --- App kliyan (pill nav glassmorphic) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ClientShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (context, state) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Ekran san bottom nav
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment/:id',
        builder: (context, state) => PaymentScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
    ],
  );
});

class RedlightApp extends ConsumerWidget {
  const RedlightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    // intl swiv lang app la (dat, non mwa, elatriye)
    Intl.defaultLocale = locale.toLanguageTag();

    // Tèm sombre pou app kliyan, tèm clè pou /admin.
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final path = router.routerDelegate.currentConfiguration.uri.path;
        final isAdmin = path.startsWith('/admin');
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: isAdmin ? ThemeMode.light : themeMode,
          routerConfig: router,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}
