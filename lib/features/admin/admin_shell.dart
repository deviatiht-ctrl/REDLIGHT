import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../l10n/app_strings.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';

/// Shell panel admin — sidebar goch + kontni (tèm clè).
/// Verifye is_admin() isit la: si se pa admin -> aksè refize.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const _items = [
    (LucideIcons.layoutDashboard, 'dashboard', '/admin'),
    (LucideIcons.sparkles, 'admin_offers', '/admin/offers'),
    (LucideIcons.package, 'products', '/admin/products'),
    (LucideIcons.tag, 'categories', '/admin/categories'),
    (LucideIcons.receipt, 'orders', '/admin/orders'),
    (LucideIcons.creditCard, 'commerce_admin', '/admin/commerce'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final s = ref.watch(stringsProvider);

    return isAdmin.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(body: _accessDenied(context, ref, s)),
      data: (admin) => Scaffold(
        body: admin
            ? Row(
                children: [
                  _AdminSidebar(items: _items, s: s),
                  const VerticalDivider(width: 1),
                  Expanded(child: child),
                ],
              )
            : _accessDenied(context, ref, s),
      ),
    );
  }

  Widget _accessDenied(BuildContext context, WidgetRef ref, S s) {
    return EmptyState(
      icon: LucideIcons.shieldAlert,
      title: s.t('access_denied'),
      subtitle: s.t('not_admin'),
      actionLabel: s.t('sign_out'),
      onAction: () async {
        await ref.read(authServiceProvider).signOut();
        if (context.mounted) context.go('/auth');
      },
    );
  }
}

class _AdminSidebar extends ConsumerWidget {
  const _AdminSidebar({required this.items, required this.s});

  final List<(IconData, String, String)> items;
  final S s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 230,
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMutedLight,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          for (final (icon, labelKey, path) in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: _SidebarItem(
                icon: icon,
                label: s.t(labelKey),
                selected: location == path,
                onTap: () => context.go(path),
              ),
            ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SidebarItem(
                  icon: LucideIcons.store,
                  label: s.t('view_store'),
                  selected: false,
                  onTap: () => context.go('/'),
                ),
                _SidebarItem(
                  icon: LucideIcons.logOut,
                  label: s.t('sign_out'),
                  selected: false,
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.red.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.red : AppColors.textMutedLight,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.red : AppColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
