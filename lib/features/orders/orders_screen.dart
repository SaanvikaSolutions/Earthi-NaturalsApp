import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/api/api_client.dart';
import '../../data/models/product.dart';
import '../../data/models/order.dart' as model;
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../cart/cart_controller.dart';

/// My Orders — the signed-in user's orders, loaded from the API.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return PopScope(
      // Reached from the order-confirmation sheet via `go`, there is nothing to
      // pop, so a system back would close the app — send it Home instead.
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(
            leading: BackButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            title: const Text('My Orders')),
        body: SafeArea(
          child: orders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorState(
              onRetry: () => ref.invalidate(ordersProvider),
            ),
            data: (list) {
              if (list.isEmpty) return const _EmptyState();
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(ordersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(Gap.pagePadding),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
                  itemBuilder: (_, i) => _orderCard(context, ref, list[i]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Progress stages an order moves through, in order.
  static const _stages = ['Placed', 'In transit', 'Delivered'];

  /// Shows where the order currently is. The backend tracks a status only —
  /// there is no courier feed — so this reports that status and nothing more.
  void _trackOrder(BuildContext context, model.Order order) {
    final cancelled = order.status == 'Cancelled';
    final currentIndex = _stages.indexOf(order.status);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Gap.pagePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${order.reference}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Placed on ${_formatDate(order.createdAt)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 20),
              if (cancelled)
                _stageRow('Cancelled', done: true, last: true,
                    color: AppColors.remove)
              else
                for (var i = 0; i < _stages.length; i++)
                  _stageRow(_stages[i],
                      done: i <= currentIndex, last: i == _stages.length - 1),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stageRow(String label,
      {required bool done, required bool last, Color? color}) {
    final tint = color ?? AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(done ? Icons.check_circle : Icons.circle_outlined,
                  size: 20, color: done ? tint : AppColors.inputBorder),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: done ? tint : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  color: done ? AppColors.textPrimary : AppColors.textMuted,
                )),
          ),
        ],
      ),
    );
  }

  /// Re-adds every line of a past order to the cart, then opens the cart so the
  /// user can review it before paying. Lines whose product has since left the
  /// catalogue are skipped rather than failing the whole action.
  Future<void> _buyAgain(
      BuildContext context, WidgetRef ref, model.Order order) async {
    final List<Product> catalog;
    try {
      catalog = await ref.read(productCatalogProvider.future);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    final cart = ref.read(cartProvider.notifier);
    var added = 0;
    var unavailable = 0;
    for (final item in order.items) {
      final match =
          catalog.where((p) => p.id == item.productSlug).firstOrNull;
      if (match == null) {
        unavailable++;
        continue;
      }
      // The saved size may have been retired since the order was placed.
      final size = match.sizes.contains(item.size)
          ? item.size
          : (match.sizes.firstOrNull ?? item.size);
      cart.add(match, size, qty: item.qty);
      added++;
    }

    if (!context.mounted) return;
    if (added == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('These products are no longer available')));
      return;
    }
    if (unavailable > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$unavailable item'
              '${unavailable == 1 ? '' : 's'} no longer available')));
    }
    context.push('/cart');
  }

  Widget _orderCard(BuildContext context, WidgetRef ref, model.Order order) {
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
              Text('Order #${order.reference}',
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
          Text(_formatDate(order.createdAt),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: Gap.md),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: ProductImage(label: item.name),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('${item.name}  ×${item.qty}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    Text('₹${item.price * item.qty}',
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
              Text('₹${order.total}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: Gap.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _trackOrder(context, order),
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
                  onPressed: () => _buyAgain(context, ref, order),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No orders yet',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text("Couldn't load your orders",
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
