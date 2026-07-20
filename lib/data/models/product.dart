class Product {
  final String id;
  final String name;
  final String category;
  final String subcategory;
  final String imageUrl;
  final int price;
  final int mrp;
  final double rating;
  final int reviews;
  final String description;
  final List<String> sizes;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory = '',
    this.imageUrl = '',
    required this.price,
    required this.mrp,
    required this.rating,
    required this.reviews,
    required this.description,
    this.sizes = const ['25 ml', '50 ml', '100 ml', '250 ml'],
  });

  int get discountPercent =>
      mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;

  /// Builds a [Product] from the API JSON shape (see server/src/models/Product.js).
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      imageUrl: json['image'] as String? ?? '',
      price: (json['price'] as num).round(),
      mrp: (json['mrp'] as num).round(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviews: (json['reviews'] as num?)?.round() ?? 0,
      description: json['description'] as String? ?? '',
      sizes: (json['sizes'] as List?)?.map((e) => e.toString()).toList() ??
          const ['25 ml', '50 ml', '100 ml', '250 ml'],
    );
  }
}

class CartItem {
  final Product product;
  final String size;
  int qty;

  CartItem({required this.product, required this.size, this.qty = 1});

  int get lineTotal => product.price * qty;
}
