class TodayOffer {
  final String id;
  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? productId;
  final String buttonText;
  final double buttonAlignmentX; // -1.0 (left) .. 1.0 (right)
  final double buttonAlignmentY; // -1.0 (top) .. 1.0 (bottom)
  final String buttonColor;
  final String buttonTextColor;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  const TodayOffer({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.productId,
    this.buttonText = 'SHOP NOW',
    this.buttonAlignmentX = -0.7,
    this.buttonAlignmentY = 0.65,
    this.buttonColor = '#FF5000',
    this.buttonTextColor = '#FFFFFF',
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory TodayOffer.fromJson(Map<String, dynamic> json) => TodayOffer(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        imageUrl: json['image_url'] as String? ?? '',
        productId: json['product_id'] as String?,
        buttonText: json['button_text'] as String? ?? 'SHOP NOW',
        buttonAlignmentX: (json['button_align_x'] as num?)?.toDouble() ?? -0.7,
        buttonAlignmentY: (json['button_align_y'] as num?)?.toDouble() ?? 0.65,
        buttonColor: json['button_color'] as String? ?? '#FF5000',
        buttonTextColor: json['button_text_color'] as String? ?? '#FFFFFF',
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'product_id': productId,
        'button_text': buttonText,
        'button_align_x': buttonAlignmentX,
        'button_align_y': buttonAlignmentY,
        'button_color': buttonColor,
        'button_text_color': buttonTextColor,
        'is_active': isActive,
        'sort_order': sortOrder,
      };

  TodayOffer copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? productId,
    String? buttonText,
    double? buttonAlignmentX,
    double? buttonAlignmentY,
    String? buttonColor,
    String? buttonTextColor,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) =>
      TodayOffer(
        id: id ?? this.id,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        imageUrl: imageUrl ?? this.imageUrl,
        productId: productId ?? this.productId,
        buttonText: buttonText ?? this.buttonText,
        buttonAlignmentX: buttonAlignmentX ?? this.buttonAlignmentX,
        buttonAlignmentY: buttonAlignmentY ?? this.buttonAlignmentY,
        buttonColor: buttonColor ?? this.buttonColor,
        buttonTextColor: buttonTextColor ?? this.buttonTextColor,
        isActive: isActive ?? this.isActive,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
}
