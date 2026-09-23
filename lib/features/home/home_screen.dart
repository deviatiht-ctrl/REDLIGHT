import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/icon_mapper.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../providers/catalog_providers.dart';
import '../../providers/core_providers.dart';
import '../../providers/locale_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(categoriesProvider);
    ref.invalidate(popularProductsProvider);
    ref.invalidate(newProductsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.red,
          onRefresh: () => _refresh(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const Spacer(),
                          if (kIsWeb) ...[
                            OutlinedButton.icon(
                              onPressed: () => context.go('/admin'),
                              icon: const Icon(LucideIcons.shieldCheck, size: 16, color: AppColors.red),
                              label: const Text(
                                'Panèl Admin',
                                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.red),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (user?.email != null)
                            Text(
                              user!.email!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMutedDark,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Search bar — tap ale nan katalòg
                      GestureDetector(
                        onTap: () => context.go('/catalog'),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.search,
                                size: 20,
                                color: AppColors.textMutedDark,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                s.t('search_hint'),
                                style: const TextStyle(
                                  color: AppColors.textMutedDark,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle(s.t('categories')),
                      const SizedBox(height: 12),
                      const _CategoryRow(),
                      const SizedBox(height: 28),
                      _SectionTitle(s.t('popular')),
                      const SizedBox(height: 12),
                      const _PopularRow(),
                      const SizedBox(height: 28),
                      _SectionTitle(s.t('new_arrivals')),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: _NewProductsGrid(),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Center(
                    child: Text(
                      AppConstants.poweredBy,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return categories.when(
      loading: () => const SizedBox(
        height: 92,
        child: Row(
          children: [
            ShimmerBox(width: 72, height: 92),
            SizedBox(width: 12),
            ShimmerBox(width: 72, height: 92),
            SizedBox(width: 12),
            ShimmerBox(width: 72, height: 92),
          ],
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (categories) => SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final cat = categories[i];
            return GestureDetector(
              onTap: () {
                ref
                    .read(catalogFilterProvider.notifier)
                    .update(CatalogFilter(categoryId: cat.id));
                context.go('/catalog');
              },
              child: Container(
                width: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(lucideIcon(cat.icon), size: 26, color: AppColors.red),
                    const SizedBox(height: 8),
                    Text(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PopularRow extends ConsumerWidget {
  const _PopularRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(popularProductsProvider);

    return popular.when(
      loading: () => const HorizontalCardShimmer(),
      error: (_, _) => const SizedBox.shrink(),
      data: (products) => SizedBox(
        height: 235,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => ProductCard(product: products[i], width: 170),
        ),
      ),
    );
  }
}

class _NewProductsGrid extends ConsumerWidget {
  const _NewProductsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(newProductsProvider);
    final s = ref.watch(stringsProvider);

    return products.when(
      loading: () => const SliverToBoxAdapter(
        child: SizedBox(height: 480, child: ProductGridShimmer()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: EmptyState(
          icon: LucideIcons.alertCircle,
          title: s.t('products_load_error'),
          subtitle: s.t('connection_error'),
          actionLabel: s.t('retry'),
          onAction: () => ref.invalidate(newProductsProvider),
        ),
      ),
      data: (products) => SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.66,
        ),
        itemCount: products.length,
        itemBuilder: (_, i) => ProductCard(product: products[i]),
      ),
    );
  }
}
