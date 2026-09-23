import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../models/product.dart';
import 'core_providers.dart';

/// Tout kategori yo.
final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(productServiceProvider).fetchCategories(),
);

/// Filtè katalòg la (kategori, rechèch, pri, mak, lòd).
class CatalogFilter {
  final String? categoryId;
  final String query;
  final double? minPrice;
  final double? maxPrice;
  final String? brand;
  final String sort; // newest | price_asc | price_desc | name_asc

  const CatalogFilter({
    this.categoryId,
    this.query = '',
    this.minPrice,
    this.maxPrice,
    this.brand,
    this.sort = 'newest',
  });

  static const _sentinel = Object();

  CatalogFilter copyWith({
    Object? categoryId = _sentinel,
    String? query,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    Object? brand = _sentinel,
    String? sort,
  }) {
    return CatalogFilter(
      categoryId: identical(categoryId, _sentinel)
          ? this.categoryId
          : categoryId as String?,
      query: query ?? this.query,
      minPrice: identical(minPrice, _sentinel)
          ? this.minPrice
          : minPrice as double?,
      maxPrice: identical(maxPrice, _sentinel)
          ? this.maxPrice
          : maxPrice as double?,
      brand: identical(brand, _sentinel) ? this.brand : brand as String?,
      sort: sort ?? this.sort,
    );
  }
}

class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  void update(CatalogFilter filter) => state = filter;
  void reset() => state = const CatalogFilter();
}

final catalogFilterProvider =
    NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
      CatalogFilterNotifier.new,
    );

/// Pwodwi filtè yo (katalòg + rechèch).
final filteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final filter = ref.watch(catalogFilterProvider);
  var products = await ref
      .watch(productServiceProvider)
      .fetchProducts(
        categoryId: filter.categoryId,
        search: filter.query,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        sort: filter.sort,
      );

  final brand = filter.brand;
  if (brand != null) {
    final lower = brand.toLowerCase();
    products = products
        .where(
          (p) => p.compatibleModels.any((m) => m.toLowerCase().startsWith(lower)),
        )
        .toList();
  }
  return products;
});

/// Pi popilè (baze sou vant reyèl).
final popularProductsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productServiceProvider).fetchPopular(),
);

/// Nouvo pwodwi.
final newProductsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productServiceProvider).fetchProducts(limit: 8),
);

/// Yon sèl pwodwi pa id.
final productProvider = FutureProvider.family<Product, String>(
  (ref, id) => ref.watch(productServiceProvider).fetchProduct(id),
);

/// Lis mak machin yo (ekstrè nan compatible_models).
final brandsProvider = FutureProvider<List<String>>((ref) async {
  final products = await ref.watch(productServiceProvider).fetchProducts();
  final brands = <String>{};
  for (final product in products) {
    for (final model in product.compatibleModels) {
      final brand = model.split(' ').first;
      if (brand.isNotEmpty && brand.toLowerCase() != 'universal') {
        brands.add(brand);
      }
    }
  }
  return brands.toList()..sort();
});
