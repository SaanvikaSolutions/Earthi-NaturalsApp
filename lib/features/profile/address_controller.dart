import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'name': name,
        'line': line,
        'phone': phone,
        'isDefault': isDefault,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as String,
        label: json['label'] as String? ?? 'Home',
        name: json['name'] as String? ?? '',
        line: json['line'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        isDefault: json['isDefault'] as bool? ?? false,
      );

  /// Pincode parsed out of [line], used for the cart/checkout summary line.
  String get pincode {
    final match = RegExp(r'(\d{6})').firstMatch(line);
    return match?.group(1) ?? '';
  }
}

/// The address book, saved on the device.
///
/// There is no addresses endpoint on the backend yet, so the list lives in
/// SharedPreferences; swapping it for a repository later only changes this file.
///
/// Two rules the rest of the app relies on:
///  * exactly one address is the default whenever the book isn't empty;
///  * the default only changes when the user asks for it ([setDefault], or
///    ticking "Use as default" in the form) — choosing where *this order* goes
///    is a separate thing, see [selectedAddressIdProvider].
class AddressController extends Notifier<List<Address>> {
  static const _prefsKey = 'saved_addresses_v1';

  /// Shown only on a fresh install, until the user saves or edits something.
  static const _samples = [
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

  /// Set once the user changes anything, so a slow disk read can't overwrite it.
  bool _changed = false;

  @override
  List<Address> build() {
    _load();
    return _samples;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || _changed) return; // nothing saved yet: keep samples
      final list = (jsonDecode(raw) as List)
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
      state = _withOneDefault(list);
    } catch (_) {
      // A corrupt or unreadable save shouldn't stop the app; keep what we have.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _prefsKey, jsonEncode(state.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  /// Applies a change, enforces the one-default rule, and saves to disk.
  void _set(List<Address> next) {
    _changed = true;
    state = _withOneDefault(next);
    _save();
  }

  /// Guarantees exactly one default in a non-empty list: the first one marked
  /// default wins, and if none is marked the first address becomes the default.
  static List<Address> _withOneDefault(List<Address> list) {
    if (list.isEmpty) return list;
    final keep = list.indexWhere((a) => a.isDefault);
    final index = keep >= 0 ? keep : 0;
    return [
      for (var i = 0; i < list.length; i++)
        list[i].isDefault == (i == index)
            ? list[i]
            : list[i].copyWith(isDefault: i == index),
    ];
  }

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
    _set([
      if (entry.isDefault)
        for (final a in state) a.copyWith(isDefault: false)
      else
        ...state,
      entry,
    ]);
  }

  void update(Address address) {
    final wasDefault = state.any((a) => a.id == address.id && a.isDefault);
    // Unticking "default" on the current default would leave the book without
    // one; the default only moves when a different address is made default.
    final makeDefault = address.isDefault || wasDefault;
    _set([
      for (final a in state)
        if (a.id == address.id)
          address.copyWith(isDefault: makeDefault)
        else if (makeDefault)
          a.copyWith(isDefault: false)
        else
          a,
    ]);
  }

  void remove(String id) => _set(state.where((a) => a.id != id).toList());

  void setDefault(String id) {
    if (!state.any((a) => a.id == id)) return;
    _set([
      for (final a in state) a.copyWith(isDefault: a.id == id),
    ]);
  }
}

final addressesProvider =
    NotifierProvider<AddressController, List<Address>>(AddressController.new);

/// The address the customer picked for the order they're placing now, or null
/// if they haven't picked one (then the default is used). This is deliberately
/// separate from the default so choosing where one order goes never changes
/// which address carries the "Default" label.
class SelectedAddressIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
  void clear() => state = null;
}

final selectedAddressIdProvider =
    NotifierProvider<SelectedAddressIdController, String?>(
        SelectedAddressIdController.new);

/// The address orders are delivered to: the one picked for this order if it
/// still exists, otherwise the default. Null if the book is empty.
final selectedAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressesProvider);
  if (list.isEmpty) return null;
  final pickedId = ref.watch(selectedAddressIdProvider);
  return list.where((a) => a.id == pickedId).firstOrNull ??
      list.where((a) => a.isDefault).firstOrNull ??
      list.first;
});
