import 'package:flutter/material.dart';

/// Earthi Naturals brand logo (real artwork from Figma).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.width = 220});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      fit: BoxFit.contain,
    );
  }
}
