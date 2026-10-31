import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/product.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/locale_provider.dart';
import '../theme/colors.dart';
import '../utils/format.dart';
import 'shimmer_loader.dart';

/// Kat pwodwi — imaj, non, pri, badge stock, bouton favori.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, this.width});

  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesProvider.select((s) => s.contains(product.id)),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1E26) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB);

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: AppShadows.elevated(isDark),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/product/${product.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.05,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: isDark ? const Color(0xFF14171E) : const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.all(8),
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: product.imageUrl!,
                                fit: BoxFit.contain,
                                placeholder: (_, _) =>
                                    const ShimmerBox(radius: 0),
                                errorWidget: (_, _, _) => const _ImageFallback(),
                              )
                            : const _ImageFallback(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(favoritesProvider.notifier)
                                .toggle(product.id);
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0x99000000) : const Color(0xB3FFFFFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              LucideIcons.heart,
                              size: 17,
                              color: isFavorite
                                  ? AppColors.red
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatPrice(product.price),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.red,
                              ),
                            ),
                          ),
                          StockBadge(stock: product.stock, compact: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge stock — tradui selon lang aktif la.
class StockBadge extends ConsumerWidget {
  const StockBadge({super.key, required this.stock, this.compact = false});

  final int stock;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final (label, color) = stock <= 0
        ? (s.t('stock_out'), AppColors.red)
        : stock <= 5
        ? (s.t('stock_low'), AppColors.warning)
        : (s.t('stock_in'), AppColors.success);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.package,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 40,
      ),
    );
  }
}
