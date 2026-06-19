import '../models/product.dart';

/// Mock catalogue drawn from the product names seen across the Figma screens.
class MockData {
  static const List<Product> products = [
    Product(
      id: 'p1',
      name: 'Anti-aging Serum',
      category: 'Skin care',
      price: 949,
      mrp: 1099,
      rating: 4.7,
      reviews: 259,
      description:
          'A premium anti-aging serum formulated with effective herbs and oils. '
          'It firms, smooths and revitalises skin, free from harmful chemicals. '
          'Experience nature\'s power for radiant, youthful skin.',
    ),
    Product(
      id: 'p2',
      name: 'Revitalizing Cleanser',
      category: 'Skin care',
      price: 499,
      mrp: 699,
      rating: 4.6,
      reviews: 188,
      description:
          'A gentle yet effective cleanser that removes impurities while '
          'preserving your skin\'s natural moisture barrier.',
    ),
    Product(
      id: 'p3',
      name: 'Brightening Hair Serum',
      category: 'Hair care',
      price: 659,
      mrp: 999,
      rating: 4.8,
      reviews: 456,
      description:
          'This premium hair serum is formulated with effective herbs and oils. '
          'It fortifies roots, minimises loss, and encourages healthy growth, '
          'free from harmful chemicals.',
    ),
    Product(
      id: 'p4',
      name: 'Ayurvedic Hair Growth Oil',
      category: 'Hair care',
      price: 1699,
      mrp: 3599,
      rating: 4.9,
      reviews: 12000,
      description:
          'A time-honoured Ayurvedic blend that nourishes the scalp, '
          'strengthens roots and promotes thicker, healthier hair growth.',
    ),
    Product(
      id: 'p5',
      name: 'Unisex Day Cream',
      category: 'Skin care',
      price: 749,
      mrp: 899,
      rating: 4.5,
      reviews: 312,
      description:
          'A lightweight daily moisturiser that hydrates and protects, '
          'suitable for all skin types.',
    ),
    Product(
      id: 'p6',
      name: 'Nourishing Scalp Oil',
      category: 'Hair care',
      price: 986,
      mrp: 2599,
      rating: 4.6,
      reviews: 568,
      description:
          'Deeply nourishing scalp oil that soothes, conditions and revitalises '
          'for a healthier scalp environment.',
    ),
  ];

  static List<Product> get bestSellers => products.take(4).toList();
  static List<Product> get justDropped => products.reversed.take(4).toList();

  static const List<String> concerns = [
    'Acne Control',
    'Hair Fall',
    'Oiliness',
    'Anti-aging',
    'Dryness',
  ];

  static const List<String> concernIcons = [
    'assets/images/concern_acne.png',
    'assets/images/concern_hairfall.png',
    'assets/images/concern_oiliness.png',
    'assets/images/concern_antiaging.png',
    'assets/images/concern_dryness.png',
  ];

  static const List<String> categories = [
    'Skin care',
    'Hair care',
    'Body Care',
    'Baby Care',
  ];
}
