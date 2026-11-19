/// Reduces whatever the customer typed to a bare 10-digit Indian mobile number
/// ("+91 98765 43210", "098765-43210", "9876543210" all become "9876543210"),
/// or null if it can't be one.
///
/// Mobile numbers in India start with 6-9. Anything else is rejected rather
/// than passed on, because Razorpay silently drops a contact it can't parse and
/// then asks the customer for it again.
String? normalizeIndianPhone(String? raw) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('91')) {
    digits = digits.substring(2);
  } else if (digits.length == 11 && digits.startsWith('0')) {
    digits = digits.substring(1);
  }
  return RegExp(r'^[6-9]\d{9}$').hasMatch(digits) ? digits : null;
}

/// The form Razorpay's `prefill.contact` reliably accepts: "+91" + 10 digits.
/// Null when [raw] isn't a valid number.
String? razorpayContact(String? raw) {
  final n = normalizeIndianPhone(raw);
  return n == null ? null : '+91$n';
}

/// Validator for phone form fields.
String? validateIndianPhone(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Phone number is required';
  return normalizeIndianPhone(raw) == null
      ? 'Enter a valid 10-digit mobile number'
      : null;
}
