import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand_logo.dart';
import '../../data/api/api_client.dart';
import 'auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _toast('Name, email and password are required');
      return;
    }
    if (password != _confirm.text.trim()) {
      _toast('Passwords do not match');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signup(
            name: name,
            email: email,
            password: password,
            phone: _phone.text.trim(),
          );
      if (!mounted) return;
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        _toast(error is ApiException ? error.message : 'Sign up failed');
      } else {
        context.go('/home');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              const Center(child: BrandLogo(width: 200)),
              const SizedBox(height: 0),
              AppTextField(hint: 'Full Name', controller: _name),
              const SizedBox(height: Gap.md),
              AppTextField(
                  hint: 'Mobile Number',
                  controller: _phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: Gap.md),
              AppTextField(
                  hint: 'Email Address',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false),
              const SizedBox(height: Gap.md),
              AppTextField(
                  hint: 'Password', controller: _password, obscure: true),
              const SizedBox(height: Gap.md),
              AppTextField(
                  hint: 'Confirm Password',
                  controller: _confirm,
                  obscure: true),
              const SizedBox(height: 10),
              PrimaryButton(
                label: _submitting ? 'Creating account…' : 'Sign Up',
                onPressed: _submitting ? null : _submit,
              ),
              const SizedBox(height: Gap.md),
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: RichText(
                    text: const TextSpan(
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 15),
                      children: [
                        TextSpan(text: 'Already have an account?  '),
                        TextSpan(
                            text: 'Login',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
