/// Swivi koli — pozisyon kounye a + ETA + anprevu.
/// Tab `order_tracking` (1 ranje pa kòmand, admin mete ajou).
class OrderTracking {
  final String orderId;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime? etaAt;
  final String? delayNote;
  final DateTime? updatedAt;

  const OrderTracking({
    required this.orderId,
    this.location,
    this.latitude,
    this.longitude,
    this.etaAt,
    this.delayNote,
    this.updatedAt,
  });

  bool get hasPosition => latitude != null && longitude != null;

  factory OrderTracking.fromJson(Map<String, dynamic> json) => OrderTracking(
    orderId: json['order_id'] as String,
    location: json['location'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    etaAt: DateTime.tryParse(json['eta_at'] as String? ?? ''),
    delayNote: json['delay_note'] as String?,
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
  );
}

/// Etap nan istorik swivi a — checkpoint oswa anprevu (delay).
class TrackingEvent {
  final String id;
  final String kind; // 'checkpoint' | 'delay'
  final String? location;
  final String? note;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const TrackingEvent({
    required this.id,
    required this.kind,
    this.location,
    this.note,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
    id: json['id'] as String,
    kind: json['kind'] as String? ?? 'checkpoint',
    location: json['location'] as String?,
    note: json['note'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
  );
}

/// Pache: pozisyon kounye a + tout etap yo pou yon kòmand.
class OrderTrackingInfo {
  final OrderTracking? tracking;
  final List<TrackingEvent> events;

  const OrderTrackingInfo({this.tracking, this.events = const []});

  bool get isEmpty => tracking == null && events.isEmpty;
}
