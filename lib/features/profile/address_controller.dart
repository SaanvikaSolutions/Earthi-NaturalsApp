import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A saved delivery address.
class Address {
  final String id;
  final String label;
  final String name;
  final String line;
  final String phone;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.name,
    required this.line,
    required this.phone,
    this.isDefault = false,
  });

  Address copyWith({
    String? label,
    String? name,
    String? line,
    String? phone,
    bool? isDefault,
  }) =>
      Address(
        id: id,
        label: label ?? this.label,
        name: name ?? this.name,
        line: line ?? this.line,
        phone: phone ?? this.phone,
        isDefault: isDefault ?? this.isDefault,
      );

  /// Pincode parsed out of [line], used for the cart/checkout summary line.
  String get pincode {
    final match = RegExp(r'(\d{6})').firstMatch(line);
    return match?.group(1) ?? '';
  }
}

/// In-memory address book. There is no addresses endpoint on the backend yet,
/// so this mirrors the cart's local-state approach; swapping it for a
/// repository later only changes this file.
class AddressController extends Notifier<List<Address>> {
  @override
  List<Address> build() => const [
        Address(
          id: 'a1',
          label: 'Home',
          name: 'Rishika Patel',
          line: '12 Lotus Residency, MG Road, Bengaluru, Karnataka 560001',
          phone: '+91 98765 43210',
          isDefault: true,
        ),
        Address(
          id: 'a2',
          label: 'Work',
          name: 'Rishika Patel',
          line: '4th Floor, Tech Park, Whitefield, Bengaluru, Karnataka 560066',
          phone: '+91 98765 43210',
        ),
      ];

  String _newId() => 'a${DateTime.now().microsecondsSinceEpoch}';

  void add(Address address) {
    final entry = Address(
      id: _newId(),
      label: address.label,
      name: address.name,
      line: address.line,
      phone: address.phone,
      // The first address saved is the default by definition.
      isDefault: address.isDefault || state.isEmpty,
    );
    state = [
      if (entry.isDefault)
        for (final a in state) a.copyWith(isDefault: false)
      else
        ...state,
      entry,
    ];
  }

  void update(Address address) {
    state = [
      for (final a in state)
        if (a.id == address.id)
          address
        else if (address.isDefault)
          a.copyWith(isDefault: false)
        else
          a,
    ];
  }

  void remove(String id) {
    final next = state.where((a) => a.id != id).toList();
    // Never leave the book without a default to fall back on.
    if (next.isNotEmpty && !next.any((a) => a.isDefault)) {
      next[0] = next[0].copyWith(isDefault: true);
    }
    state = next;
  }

  void setDefault(String id) {
    state = [
      for (final a in state) a.copyWith(isDefault: a.id == id),
    ];
  }
}

final addressesProvider =
    NotifierProvider<AddressController, List<Address>>(AddressController.new);

/// The address orders are delivered to, or null if the book is empty.
final selectedAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesProvider);
  if (list.isEmpty) return null;
  return list.where((a) => a.isDefault).firstOrNull ?? list.first;
});
