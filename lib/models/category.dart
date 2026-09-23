class Category {
  final String id;
  final String name;
  final String? icon;

  const Category({required this.id, required this.name, this.icon});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String?,
  );

  Map<String, dynamic> toJson() => {'name': name, 'icon': icon};
}
