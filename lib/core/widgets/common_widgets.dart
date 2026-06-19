import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Price row: bold current price, struck MRP, green discount badge.
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.price,
    required this.mrp,
    this.priceSize = 16,
    this.discountPercent,
  });

  final int price;
  final int mrp;
  final double priceSize;
  final int? discountPercent;

  int get _percent =>
      discountPercent ?? (mrp > 0 ? (((mrp - price) / mrp) * 100).round() : 0);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('₹$price',
            style: TextStyle(
                fontSize: priceSize, fontWeight: FontWeight.w700)),
        if (mrp > price) ...[
          const SizedBox(width: 6),
          Text('₹$mrp',
              style: TextStyle(
                fontSize: priceSize - 3,
                color: AppColors.priceStrike,
                decoration: TextDecoration.lineThrough,
              )),
          const SizedBox(width: 6),
          DiscountBadge(percent: _percent),
        ],
      ],
    );
  }
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.discountBg,
        borderRadius: BorderRadius.circular(Radii.badge),
      ),
      child: Text('$percent% off',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.discountText,
          )),
    );
  }
}

/// Star rating + review count (e.g. ★ 4.8  259 reviews).
class RatingRow extends StatelessWidget {
  const RatingRow({
    super.key,
    required this.rating,
    required this.reviews,
    this.size = 13,
  });

  final double rating;
  final int reviews;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.star, size: size + 1, color: AppColors.star),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1),
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w600)),
        const SizedBox(width: 5),
        Text('$reviews reviews',
            style: TextStyle(fontSize: size, color: AppColors.textMuted)),
      ],
    );
  }
}

/// Image placeholder with a soft beige tint (stands in for product photos
/// until real assets are wired in).
class ProductImage extends StatelessWidget {
  const ProductImage({super.key, this.radius = Radii.card, this.label});
  final double radius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: const Color(0xFFEDE6DC),
        child: const Center(
          child: Icon(Icons.spa, color: Color(0xFFB9A88F), size: 34),
        ),
      ),
    );
  }
}

/// Quantity stepper (– n +).
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(value > 1 ? value - 1 : 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$value',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          _btn(Icons.add, () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16),
        ),
      );
}
