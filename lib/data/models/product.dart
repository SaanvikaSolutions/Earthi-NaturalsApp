class Product {
  final String id;
  final String name;
  final String category;
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
    required this.price,
    required this.mrp,
    required this.rating,
    required this.reviews,
    required this.description,
    this.sizes = const ['25 ml', '50 ml', '100 ml', '250 ml'],
  });

  int get discountPercent =>
      mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0;
}

class CartItem {
  final Product product;
  final String size;
  int qty;

  CartItem({required this.product, required this.size, this.qty = 1});

  int get lineTotal => product.price * qty;
}
