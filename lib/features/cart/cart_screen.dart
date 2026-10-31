import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/format.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.t('cart_title'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: cart.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(20),
                  child: ListShimmer(),
                ),
                error: (_, _) => EmptyState(
                  icon: LucideIcons.alertCircle,
                  title: s.t('cart_load_error'),
                ),
                data: (items) => items.isEmpty
                    ? EmptyState(
                        icon: LucideIcons.shoppingCart,
                        title: s.t('cart_empty'),
                        subtitle: s.t('cart_empty_sub'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) =>
                            _CartTile(item: items[i]),
                      ),
              ),
            ),
            if ((cart.value ?? const []).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1B1E26)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C3240)
                          : const Color(0xFFE5E7EB),
                      width: 1.2,
                    ),
                    boxShadow: AppShadows.elevated(Theme.of(context).brightness == Brightness.dark),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            s.t('total'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textMutedDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            formatPrice(total),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: s.t('checkout'),
                        icon: LucideIcons.chevronRight,
                        onPressed: () => context.push('/checkout'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E26) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: AppShadows.elevated(isDark),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14171E) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(6),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => _fallback(context),
                  )
                : _fallback(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(product.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniQtyButton(
                      icon: LucideIcons.minus,
                      onTap: () => ref
                          .read(cartProvider.notifier)
                          .setQuantity(product.id, item.quantity - 1),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _MiniQtyButton(
                      icon: LucideIcons.plus,
                      onTap: item.quantity >= product.stock
                          ? null
                          : () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(product.id, item.quantity + 1),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        ref
                            .read(cartProvider.notifier)
                            .remove(product.id);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.outline,
    alignment: Alignment.center,
    child: const Icon(
      LucideIcons.package,
      size: 24,
      color: AppColors.textMutedDark,
    ),
  );
}

class _MiniQtyButton extends StatelessWidget {
  const _MiniQtyButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? Theme.of(context).disabledColor : Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
