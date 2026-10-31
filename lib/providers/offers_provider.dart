import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/today_offer.dart';
import '../services/offers_service.dart';
import '../services/supabase_service.dart';
import 'core_providers.dart';

final offersServiceProvider = Provider<OffersService>(
  (ref) => OffersService(
    SupabaseService.client,
    ref.watch(sharedPreferencesProvider),
  ),
);

final todayOffersProvider = FutureProvider<List<TodayOffer>>(
  (ref) => ref.watch(offersServiceProvider).fetchOffers(onlyActive: true),
);

final adminOffersProvider = FutureProvider<List<TodayOffer>>(
  (ref) => ref.watch(offersServiceProvider).fetchOffers(onlyActive: false),
);
