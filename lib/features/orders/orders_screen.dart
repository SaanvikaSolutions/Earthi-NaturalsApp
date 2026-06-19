import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/product.dart';

/// My Orders — list of past / in-progress orders.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  // Mock orders derived from the catalogue.
  static final _orders = <_Order>[
    _Order('EN1042', 'Delivered', '12 May 2026',
        [MockData.products[0], MockData.products[2]]),
    _Order('EN1031', 'In transit', '28 Apr 2026',
        [MockData.products[3]]),
    _Order('EN1009', 'Delivered', '02 Apr 2026',
        [MockData.products[1], MockData.products[4], MockData.products[5]]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('My Orders')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(Gap.pagePadding),
          itemCount: _orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
          itemBuilder: (_, i) => _orderCard(context, _orders[i]),
        ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, _Order order) {
    final total = order.items.fold<int>(0, (s, p) => s + p.price);
    final delivered = order.status == 'Delivered';
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Order #${order.id}',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: delivered
                      ? AppColors.discountBg
                      : const Color(0xFFFFE7C2),
                  borderRadius: BorderRadius.circular(Radii.badge),
                ),
                child: Text(order.status,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: delivered
                            ? AppColors.discountText
                            : const Color(0xFF9A6B12))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(order.date,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: Gap.md),
          ...order.items.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: ProductImage(label: p.name),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Text('₹${p.price}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 20),
          Row(
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textMuted)),
              const Spacer(),
              Text('₹$total',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.pill)),
                  ),
                  child: const Text('Track Order'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.pill)),
                  ),
                  child: const Text('Buy Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Order {
  final String id;
  final String status;
  final String date;
  final List<Product> items;
  _Order(this.id, this.status, this.date, this.items);
}
