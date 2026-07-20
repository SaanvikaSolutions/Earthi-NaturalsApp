import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_providers.dart';
import '../api/api_client.dart';
import '../models/order.dart';

/// Manages the signed-in user's orders (requires a bearer token).
class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  /// The user's orders, newest first.
  Future<List<Order>> fetchAll() async {
    final data = await _api.get('/orders');
    return (data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Placing an order goes through PaymentRepository now: an order is created as
  // part of starting a payment and only becomes real once the backend has
  // verified the Razorpay signature.
}

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(ref.watch(apiClientProvider)),
);

/// The signed-in user's orders, loaded from the API.
final ordersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).fetchAll(),
);
