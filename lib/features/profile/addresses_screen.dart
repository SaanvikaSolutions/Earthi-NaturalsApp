import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import 'address_controller.dart';

/// Saved Addresses — list of delivery addresses with add/edit/delete actions.
/// Tapping a card makes it the delivery address used by cart and checkout.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Saved Addresses')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: addresses.isEmpty
                  ? _empty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(Gap.pagePadding),
                      itemCount: addresses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: Gap.md),
                      itemBuilder: (_, i) => _card(context, ref, addresses[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.pagePadding),
              child: PrimaryButton(
                label: 'Add New Address',
                icon: Icons.add,
                onPressed: () => _openForm(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No saved addresses yet',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _card(BuildContext context, WidgetRef ref, Address a) => InkWell(
        onTap: () => ref.read(addressesProvider.notifier).setDefault(a.id),
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            border: Border.all(
                color: a.isDefault ? AppColors.primary : AppColors.divider),
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.chipBg,
                      borderRadius: BorderRadius.circular(Radii.badge),
                    ),
                    child: Text(a.label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  if (a.isDefault) ...[
                    const SizedBox(width: 8),
                    const Text('Default',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  IconButton(
                    tooltip: 'Edit address',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _openForm(context, ref, existing: a),
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textMuted),
                  ),
                  IconButton(
                    tooltip: 'Delete address',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _confirmDelete(context, ref, a),
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(a.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(a.line,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 6),
              Text(a.phone,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ),
      );

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Address a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete address?'),
        content: Text('${a.label} — ${a.line}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.remove),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(addressesProvider.notifier).remove(a.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Address deleted'),
          duration: Duration(milliseconds: 1200)),
    );
  }

  /// Opens the add/edit sheet. Passing [existing] edits in place.
  Future<void> _openForm(BuildContext context, WidgetRef ref,
      {Address? existing}) async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddressForm(existing: existing),
    );
    if (result == null) return;

    final controller = ref.read(addressesProvider.notifier);
    if (existing == null) {
      controller.add(result);
    } else {
      controller.update(result);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing == null ? 'Address added' : 'Address updated'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }
}

/// Add / edit form. Pops the finished [Address], or null when cancelled.
class _AddressForm extends StatefulWidget {
  const _AddressForm({this.existing});
  final Address? existing;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _line =
      TextEditingController(text: widget.existing?.line ?? '');
  late final _phone =
      TextEditingController(text: widget.existing?.phone ?? '');
  late String _label = widget.existing?.label ?? 'Home';
  late bool _isDefault = widget.existing?.isDefault ?? false;

  static const _labels = ['Home', 'Work', 'Other'];

  @override
  void dispose() {
    _name.dispose();
    _line.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    Navigator.pop(
      context,
      existing == null
          ? Address(
              id: '', // assigned by the controller
              label: _label,
              name: _name.text.trim(),
              line: _line.text.trim(),
              phone: _phone.text.trim(),
              isDefault: _isDefault,
            )
          : existing.copyWith(
              label: _label,
              name: _name.text.trim(),
              line: _line.text.trim(),
              phone: _phone.text.trim(),
              isDefault: _isDefault,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard while typing.
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Gap.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.existing == null
                        ? 'Add New Address'
                        : 'Edit Address',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: _labels
                      .map((l) => ChoiceChip(
                            label: Text(l),
                            selected: _label == l,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _label = l),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.chipBg,
                            labelStyle: TextStyle(
                              color: _label == l
                                  ? AppColors.onPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Radii.pill),
                              side: const BorderSide(
                                  color: AppColors.inputBorder),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                _field(_name, 'Full name'),
                const SizedBox(height: 12),
                _field(_line, 'Address', maxLines: 3),
                const SizedBox(height: 12),
                _field(_phone, 'Phone number',
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Use as default delivery address',
                      style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Save Address', onPressed: _save),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
          {int maxLines = 1, TextInputType? keyboardType}) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.words,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? '$label is required' : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.chipBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.input),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
