class Category {
  final String id;
  final String name;
  final String? icon;
  final String? imageUrl;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
    imageUrl: (json['image_url'] ?? json['imageUrl']) as String?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'image_url': ?imageUrl,
  };
}
