import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/format.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_order.dart';
import '../../models/order_tracking.dart';
import '../../providers/locale_provider.dart';
import '../../providers/orders_provider.dart';

/// Seksyon "Swivi koli a" nan kat kòmand kliyan an:
/// Stepper 5 etap, kat OSM (si gen kowòdone), pozisyon tèks,
/// ETA ak kontè rebours, banner anprevu, epi istorik etap yo.
class OrderTrackingSection extends ConsumerWidget {
  const OrderTrackingSection({super.key, required this.order});

  final AppOrder order;

  /// Tan ki rete anvan ETA a, fòmate selon lang la ("3 h 20 min").
  static String etaRelative(S s, DateTime eta) {
    final diff = eta.difference(DateTime.now());
    if (diff.isNegative) return s.t('tracking_eta_passed');
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final String time;
    if (days > 0) {
      time = s.t('eta_days', {'d': '$days', 'h': '$hours'});
    } else if (diff.inHours > 0) {
      time = s.t('eta_hours', {'h': '${diff.inHours}', 'm': '$minutes'});
    } else if (minutes > 0) {
      time = s.t('eta_minutes', {'m': '$minutes'});
    } else {
      time = s.t('eta_imminent');
    }
    return s.t('tracking_arrives_in', {'time': time});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    if (order.status == 'cancelled') {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.ban, size: 16, color: AppColors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.t('step_cancelled'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final trackingAsync = ref.watch(orderTrackingProvider(order.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(height: 20),
        Row(
          children: [
            const Icon(LucideIcons.truck, size: 16, color: AppColors.red),
            const SizedBox(width: 6),
            Text(
              s.t('order_progress'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _OrderProgressStepper(order: order),
        const SizedBox(height: 14),
        trackingAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (info) {
            final tracking = info.tracking;
            if (info.isEmpty && order.status != 'shipped' && order.status != 'delivered') {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.info, size: 14, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.paymentStatus == 'paid'
                            ? s.t('step_preparing')
                            : s.t('tracking_waiting'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tracking?.delayNote != null) ...[
                  _DelayBanner(note: tracking!.delayNote!),
                  const SizedBox(height: 8),
                ],
                if (tracking?.hasPosition ?? false) ...[
                  _TrackingMap(tracking: tracking!),
                  const SizedBox(height: 8),
                ],
                if (tracking?.location != null || order.status == 'shipped' || order.status == 'delivered')
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.mapPin,
                        size: 15,
                        color: AppColors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          tracking?.location ??
                              (order.status == 'delivered'
                                  ? s.t('preset_delivered')
                                  : s.t('tracking_location_unknown')),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (tracking?.updatedAt != null)
                        Text(
                          s.t('tracking_updated', {
                            'date': formatDate(tracking!.updatedAt),
                          }),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                    ],
                  ),
                if (tracking?.etaAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 15,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${s.t('tracking_eta')}: ${formatDate(tracking!.etaAt)} '
                          '· ${etaRelative(s, tracking.etaAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (info.events.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _EventTimeline(events: info.events),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Stepper 5 etap ki montre nivo pwogresyon kòmand la
class _OrderProgressStepper extends ConsumerWidget {
  const _OrderProgressStepper({required this.order});

  final AppOrder order;

  int _currentStepIndex() {
    switch (order.status) {
      case 'delivered':
        return 4;
      case 'shipped':
        return 3;
      case 'confirmed':
        return 2;
      case 'pending':
        return order.paymentStatus == 'paid' ? 1 : 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final currentStep = _currentStepIndex();

    final steps = [
      (LucideIcons.shoppingBag, s.t('step_placed')),
      (LucideIcons.badgeCheck, s.t('step_confirmed')),
      (LucideIcons.package, s.t('step_preparing')),
      (LucideIcons.truck, s.t('step_shipped')),
      (LucideIcons.home, s.t('step_delivered')),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              final stepIndex = index ~/ 2;
              final isPassed = stepIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed
                      ? AppColors.success
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
              );
            }

            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            final isCurrent = stepIndex == currentStep;
            final item = steps[stepIndex];

            Color color;
            if (isCompleted) {
              color = AppColors.success;
            } else if (isCurrent) {
              color = AppColors.red;
            } else {
              color = Theme.of(context).colorScheme.outline;
            }

            return Tooltip(
              message: item.$2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : isCurrent
                              ? AppColors.red.withValues(alpha: 0.15)
                              : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: color,
                        width: isCurrent ? 2.2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted ? LucideIcons.check : item.$1,
                        size: 14,
                        color: isCompleted
                            ? Colors.white
                            : isCurrent
                                ? AppColors.red
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 52,
                    child: Text(
                      item.$2,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.red
                            : isCompleted
                                ? AppColors.success
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _DelayBanner extends StatelessWidget {
  const _DelayBanner({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            size: 15,
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.tracking});

  final OrderTracking tracking;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(tracking.latitude!, tracking.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 170,
        child: FlutterMap(
          options: MapOptions(initialCenter: point, initialZoom: 12),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.cvisual.redlight_autoparts',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    LucideIcons.package,
                    color: AppColors.red,
                    size: 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTimeline extends ConsumerWidget {
  const _EventTimeline({required this.events});

  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        dense: true,
        title: Text(
          s.t('tracking_history'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        children: [
          for (final e in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    e.kind == 'delay'
                        ? LucideIcons.alertTriangle
                        : LucideIcons.circleDot,
                    size: 13,
                    color: e.kind == 'delay'
                        ? AppColors.warning
                        : AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (e.location != null)
                          Text(
                            e.location!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (e.note != null)
                          Text(
                            e.note!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                        Text(
                          formatDate(e.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
