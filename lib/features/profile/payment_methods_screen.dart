import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import 'payment_method_controller.dart';

/// Payment Methods — saved cards, UPI and wallets.
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methods = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Payment Methods')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: methods.isEmpty
                  ? _empty()
                  : ListView.separated(
                      padding: const EdgeInsets.all(Gap.pagePadding),
                      itemCount: methods.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _card(context, ref, methods[i]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.pagePadding),
              child: PrimaryButton(
                label: 'Add Payment Method',
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
            Icon(Icons.credit_card_off_outlined,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No payment methods saved',
                style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );

  Widget _card(BuildContext context, WidgetRef ref, PaymentMethod m) => InkWell(
        onTap: () => ref.read(paymentMethodsProvider.notifier).setDefault(m.id),
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            border: Border.all(
                color: m.isDefault ? AppColors.primary : AppColors.divider),
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.chipBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(m.icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(m.subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (m.isDefault)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text('Default',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              IconButton(
                tooltip: 'Remove payment method',
                visualDensity: VisualDensity.compact,
                onPressed: () => _confirmRemove(context, ref, m),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, PaymentMethod m) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove payment method?'),
        content: Text(m.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.remove),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(paymentMethodsProvider.notifier).remove(m.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment method removed'),
        duration: Duration(milliseconds: 1200)));
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _PaymentForm(),
    );
    if (result == null) return;
    ref.read(paymentMethodsProvider.notifier).add(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment method added'),
        duration: Duration(milliseconds: 1200)));
  }
}

/// Formats card expiry as the user types: digits only, with the `/` inserted
/// automatically after the month. Typing `/` by hand is harmless — it is
/// stripped and re-inserted in the right place — and backspacing through the
/// separator deletes the month digit rather than sticking.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;

    // A lone month >1 can only be a single-digit month, so pad it: "3" -> "03/".
    final String text;
    if (trimmed.isEmpty) {
      text = '';
    } else if (trimmed.length == 1) {
      text = int.parse(trimmed) > 1 ? '0$trimmed/' : trimmed;
    } else if (trimmed.length == 2) {
      // Deleting the slash shouldn't immediately re-add it.
      final deleting = newValue.text.length < oldValue.text.length;
      text = deleting ? trimmed : '$trimmed/';
    } else {
      text = '${trimmed.substring(0, 2)}/${trimmed.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Add-payment sheet. Pops the finished [PaymentMethod], or null if cancelled.
class _PaymentForm extends StatefulWidget {
  const _PaymentForm();

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _upiId = TextEditingController();
  PaymentKind _kind = PaymentKind.card;
  bool _isDefault = false;

  @override
  void dispose() {
    _cardNumber.dispose();
    _expiry.dispose();
    _upiId.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    late final PaymentMethod method;
    if (_kind == PaymentKind.card) {
      final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
      // Only the last four digits are retained; see PaymentMethod.
      method = PaymentMethod(
        id: '',
        kind: PaymentKind.card,
        title: '${_brandOf(digits)} •••• ${digits.substring(digits.length - 4)}',
        subtitle: 'Expires ${_expiry.text.trim()}',
        isDefault: _isDefault,
      );
    } else {
      method = PaymentMethod(
        id: '',
        kind: PaymentKind.upi,
        title: 'UPI — ${_upiId.text.trim()}',
        subtitle: 'Linked',
        isDefault: _isDefault,
      );
    }
    Navigator.pop(context, method);
  }

  /// Best-effort brand from the leading digits (display only).
  static String _brandOf(String digits) {
    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return 'Mastercard';
    if (RegExp(r'^3[47]').hasMatch(digits)) return 'Amex';
    if (RegExp(r'^6').hasMatch(digits)) return 'RuPay';
    return 'Card';
  }

  String? _validateCard(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) {
      return 'Enter a valid card number';
    }
    return null;
  }

  String? _validateExpiry(String? v) {
    final text = (v ?? '').trim();
    if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(text)) {
      return 'Use MM/YY';
    }
    final now = DateTime.now();
    final month = int.parse(text.substring(0, 2));
    final year = 2000 + int.parse(text.substring(3));
    // Cards stay valid through the last day of the printed month.
    if (DateTime(year, month + 1, 0).isBefore(now)) return 'Card has expired';
    return null;
  }

  String? _validateUpi(String? v) {
    final text = (v ?? '').trim();
    if (!RegExp(r'^[\w.\-]{2,}@[A-Za-z]{2,}$').hasMatch(text)) {
      return 'Enter a valid UPI ID (name@bank)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isCard = _kind == PaymentKind.card;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Gap.pagePadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Payment Method',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SegmentedButton<PaymentKind>(
                  segments: const [
                    ButtonSegment(
                        value: PaymentKind.card,
                        icon: Icon(Icons.credit_card),
                        label: Text('Card')),
                    ButtonSegment(
                        value: PaymentKind.upi,
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        label: Text('UPI')),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (s) => setState(() => _kind = s.first),
                ),
                const SizedBox(height: 16),
                if (isCard) ...[
                  TextFormField(
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    validator: _validateCard,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                    ],
                    decoration: _decoration('Card number'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiry,
                    keyboardType: TextInputType.number,
                    validator: _validateExpiry,
                    inputFormatters: [_ExpiryFormatter()],
                    decoration: _decoration('Expiry (MM/YY)'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only the last four digits are saved. No payment is taken '
                    'until a gateway is connected.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ] else
                  TextFormField(
                    controller: _upiId,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateUpi,
                    decoration: _decoration('UPI ID (name@bank)'),
                  ),
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v ?? false),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Use as default payment method',
                      style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Save', onPressed: _save),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.chipBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: BorderSide.none,
        ),
      );
}
