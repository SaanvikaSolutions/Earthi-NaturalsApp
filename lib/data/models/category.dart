/// A subcategory within a [Category] (e.g. "day cream" under "Skin").
class Subcategory {
  final String id;
  final String name;
  const Subcategory({required this.id, required this.name});

  factory Subcategory.fromJson(Map<String, dynamic> json) => Subcategory(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

/// A product category from `GET /api/categories`, with its subcategories.
class Category {
  final String id;
  final String name;
  final List<Subcategory> subcategories;

  const Category({
    required this.id,
    required this.name,
    this.subcategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        subcategories: (json['subcategories'] as List?)
                ?.map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
