import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaymentKind { card, upi }

/// A saved payment method.
///
/// Only the masked tail of a card is ever kept — the app has no payment
/// gateway and must never hold a full card number.
class PaymentMethod {
  final String id;
  final PaymentKind kind;
  final String title;
  final String subtitle;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.isDefault = false,
  });

  IconData get icon => kind == PaymentKind.card
      ? Icons.credit_card
      : Icons.account_balance_wallet_outlined;

  PaymentMethod copyWith({bool? isDefault}) => PaymentMethod(
        id: id,
        kind: kind,
        title: title,
        subtitle: subtitle,
        isDefault: isDefault ?? this.isDefault,
      );
}

/// In-memory list of saved payment methods. There is no payments endpoint on
/// the backend yet, so this mirrors the cart/address local-state approach.
class PaymentMethodController extends Notifier<List<PaymentMethod>> {
  @override
  List<PaymentMethod> build() => const [
        PaymentMethod(
          id: 'p1',
          kind: PaymentKind.card,
          title: 'Visa •••• 4242',
          subtitle: 'Expires 08/27',
          isDefault: true,
        ),
        PaymentMethod(
          id: 'p2',
          kind: PaymentKind.upi,
          title: 'UPI — rishika@okhdfc',
          subtitle: 'Linked',
        ),
        PaymentMethod(
          id: 'p3',
          kind: PaymentKind.card,
          title: 'Mastercard •••• 8810',
          subtitle: 'Expires 11/26',
        ),
      ];

  void add(PaymentMethod method) {
    final entry = PaymentMethod(
      id: 'p${DateTime.now().microsecondsSinceEpoch}',
      kind: method.kind,
      title: method.title,
      subtitle: method.subtitle,
      isDefault: method.isDefault || state.isEmpty,
    );
    state = [
      if (entry.isDefault)
        for (final m in state) m.copyWith(isDefault: false)
      else
        ...state,
      entry,
    ];
  }

  void remove(String id) {
    final next = state.where((m) => m.id != id).toList();
    if (next.isNotEmpty && !next.any((m) => m.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    state = next;
  }

  void setDefault(String id) {
    state = [for (final m in state) m.copyWith(isDefault: m.id == id)];
  }
}

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodController, List<PaymentMethod>>(
        PaymentMethodController.new);
