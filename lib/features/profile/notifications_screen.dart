import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Notifications — preference toggles for the kinds of alerts the user gets.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _prefs = <String, bool>{
    'Order updates': true,
    'Offers & discounts': true,
    'New arrivals': false,
    'Price drops on wishlist': true,
    'Newsletter': false,
  };

  static const _subtitles = <String, String>{
    'Order updates': 'Shipping, delivery and returns',
    'Offers & discounts': 'Deals picked for you',
    'New arrivals': 'Be first to shop fresh drops',
    'Price drops on wishlist': 'When saved items get cheaper',
    'Newsletter': 'Skincare tips & brand stories',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const BackButton(), title: const Text('Notifications')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: Gap.pagePadding, vertical: 8),
          children: _prefs.keys.map((key) {
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              value: _prefs[key]!,
              onChanged: (v) => setState(() => _prefs[key] = v),
              title: Text(key,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text(_subtitles[key]!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
