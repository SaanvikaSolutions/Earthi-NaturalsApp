import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Help & Support — contact options plus an FAQ accordion where only one
/// question is open at a time.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  /// Index of the open FAQ, or null when all are collapsed.
  int? _openIndex;

  static const _faqs = <List<String>>[
    [
      'How long does delivery take?',
      'Orders are usually delivered within 3–5 business days. You can track '
          'live status from My Orders.'
    ],
    [
      'What is your return policy?',
      'Unopened products can be returned within 7 days of delivery for a full '
          'refund or exchange.'
    ],
    [
      'Are the products natural?',
      'Yes — every Earthi Naturals product is free from harmful chemicals and '
          'made with Ayurvedic ingredients.'
    ],
    [
      'How do I cancel an order?',
      'You can cancel any order before it is shipped from the My Orders screen.'
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.pagePadding),
          children: [
            // Live Chat is intentionally absent until a chat provider is
            // integrated — a button that opens nothing is worse than no button.
            Row(
              children: [
                Expanded(
                  child: _contact(
                    Icons.call_outlined,
                    'Call Us',
                    onTap: () => _launch(
                      context,
                      Uri(scheme: 'tel', path: SupportContact.phone),
                      'No phone app is available on this device',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _contact(
                    Icons.mail_outline,
                    'Email',
                    onTap: () => _launch(
                      context,
                      Uri(
                        scheme: 'mailto',
                        path: SupportContact.email,
                        queryParameters: const {
                          'subject': 'Earthi Naturals — Support request',
                        },
                      ),
                      'No mail app is set up on this device',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            const Text('Frequently asked questions',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.sm),
            for (var i = 0; i < _faqs.length; i++)
              Theme(
                data:
                    Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  // Rebuilding with a key tied to the open item lets
                  // initiallyExpanded collapse whichever tile was open.
                  key: ValueKey('faq-$i-${_openIndex == i}'),
                  initiallyExpanded: _openIndex == i,
                  onExpansionChanged: (expanded) =>
                      setState(() => _openIndex = expanded ? i : null),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12, right: 24),
                  iconColor: AppColors.primary,
                  collapsedIconColor: AppColors.textMuted,
                  title: Text(_faqs[i][0],
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_faqs[i][1],
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Hands [uri] to the platform, telling the user when nothing can handle it
  /// (e.g. a tablet with no dialer, or no mail account configured).
  static Future<void> _launch(
      BuildContext context, Uri uri, String unavailableMessage) async {
    final launched = await launchUrl(uri).catchError((_) => false);
    if (launched || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(unavailableMessage)));
  }

  Widget _contact(IconData icon, String label,
          {required VoidCallback onTap}) =>
      Material(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(Radii.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.md),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );
}
