import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/mock/mock_data.dart';

/// Simple in-memory cart for the vertical slice (no backend yet).
/// Uses the Riverpod 3.x [Notifier] API.
class CartController extends Notifier<List<CartItem>> {
  /// Debug-only seeding (--dart-define=SEED=true) to screenshot a populated cart.
  static const _seed = bool.fromEnvironment('SEED', defaultValue: false);

  @override
  List<CartItem> build() {
    if (!_seed) return [];
    return [
      CartItem(product: MockData.products[0], size: '50 ml', qty: 1),
      CartItem(product: MockData.products[2], size: '100 ml', qty: 2),
      CartItem(product: MockData.products[4], size: '50 ml', qty: 1),
    ];
  }

  void add(Product product, String size, {int qty = 1}) {
    final idx = state.indexWhere(
        (i) => i.product.id == product.id && i.size == size);
    if (idx >= 0) {
      final updated = [...state];
      updated[idx].qty += qty;
      state = updated;
    } else {
      state = [...state, CartItem(product: product, size: size, qty: qty)];
    }
  }

  void setQty(CartItem item, int qty) {
    final updated = [...state];
    final idx = updated.indexOf(item);
    if (idx >= 0) {
      updated[idx].qty = qty;
      state = updated;
    }
  }

  void remove(CartItem item) {
    state = state.where((i) => i != item).toList();
  }

  int get totalItems => state.fold(0, (sum, i) => sum + i.qty);
  int get cartTotal => state.fold(0, (sum, i) => sum + i.product.price * i.qty);
  int get mrpTotal => state.fold(0, (sum, i) => sum + i.product.mrp * i.qty);
  int get discount => mrpTotal - cartTotal;
  int get deliveryFee => state.isEmpty ? 0 : 69;
  int get grandTotal => cartTotal + deliveryFee;
}

final cartProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);
