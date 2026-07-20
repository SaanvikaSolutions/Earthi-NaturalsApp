import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_logo.dart';
import '../auth/auth_controller.dart';

/// Splash / flash screen — shows the brand logo while we restore any saved
/// session, then routes to home (signed in) or onboarding (signed out).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Kick off session restore (reads any persisted token + fetches the user).
    ref.read(authControllerProvider);
    _timer = Timer(const Duration(milliseconds: 3000), _advance);
  }

  Future<void> _advance() async {
    if (!mounted) return;
    // Make sure the bootstrap request has settled before deciding the route.
    final auth = await ref.read(authControllerProvider.future);
    if (!mounted) return;
    context.go(auth != null ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: const Center(child: BrandLogo(width: 240)),
    );
  }
}
