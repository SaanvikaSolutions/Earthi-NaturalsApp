import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand_logo.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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
              const AppTextField(hint: 'Full Name'),
              const SizedBox(height: Gap.md),
              const AppTextField(
                  hint: 'Mobile Number', keyboardType: TextInputType.phone),
              const SizedBox(height: Gap.md),
              const AppTextField(
                  hint: 'Email Address',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: Gap.md),
              const AppTextField(hint: 'Password', obscure: true),
              const SizedBox(height: Gap.md),
              const AppTextField(hint: 'Confirm Password', obscure: true),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Sign Up',
                onPressed: () => context.go('/home'),
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
