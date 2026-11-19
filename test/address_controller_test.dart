import 'package:earthi_naturals/features/profile/address_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Address _addr(String label, {bool isDefault = false}) => Address(
    id: '',
    label: label,
    name: 'Test',
    line: '1 Street, City 560001',
    phone: '9876543210',
    isDefault: isDefault);

int _defaults(List<Address> l) => l.where((a) => a.isDefault).length;

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('picking an address for an order does not move the default', () {
    final before = container.read(addressesProvider);
    final defaultId = before.firstWhere((a) => a.isDefault).id;
    final other = before.firstWhere((a) => !a.isDefault);

    container.read(selectedAddressIdProvider.notifier).select(other.id);

    expect(container.read(selectedAddressProvider)!.id, other.id);
    final after = container.read(addressesProvider);
    expect(_defaults(after), 1);
    expect(after.firstWhere((a) => a.isDefault).id, defaultId);
  });

  test('setDefault leaves exactly one default', () {
    final notifier = container.read(addressesProvider.notifier);
    final other = container.read(addressesProvider).firstWhere((a) => !a.isDefault);
    notifier.setDefault(other.id);

    final list = container.read(addressesProvider);
    expect(_defaults(list), 1);
    expect(list.firstWhere((a) => a.isDefault).id, other.id);
  });

  test('deleting the default promotes another one', () {
    final notifier = container.read(addressesProvider.notifier);
    final def = container.read(addressesProvider).firstWhere((a) => a.isDefault);
    notifier.remove(def.id);

    final list = container.read(addressesProvider);
    expect(list, isNotEmpty);
    expect(_defaults(list), 1);
  });

  test('unticking default on the current default keeps it default', () {
    final notifier = container.read(addressesProvider.notifier);
    final def = container.read(addressesProvider).firstWhere((a) => a.isDefault);
    notifier.update(def.copyWith(isDefault: false));

    final list = container.read(addressesProvider);
    expect(_defaults(list), 1);
    expect(list.firstWhere((a) => a.isDefault).id, def.id);
  });

  test('addresses survive an app restart', () async {
    final notifier = container.read(addressesProvider.notifier);
    notifier.add(_addr('Other', isDefault: true));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // A brand-new container is what a restarted app starts with.
    final restarted = ProviderContainer();
    addTearDown(restarted.dispose);
    restarted.read(addressesProvider); // triggers the load
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final list = restarted.read(addressesProvider);
    expect(list.any((a) => a.label == 'Other'), isTrue);
    expect(_defaults(list), 1);
    expect(list.firstWhere((a) => a.isDefault).label, 'Other');
  });
}
