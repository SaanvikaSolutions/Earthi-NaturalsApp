import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';

/// Edit Profile — opened from the pencil on the Profile header.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController(text: 'Rishika Patel');
  final _phone = TextEditingController(text: '+91 98765 43210');
  final _email = TextEditingController(text: 'rishika@example.com');

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        duration: Duration(milliseconds: 900),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Gap.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Gap.lg),
              _avatar(),
              const SizedBox(height: Gap.xl),
              const _Label('Full Name'),
              AppTextField(hint: 'Full Name', controller: _name),
              const SizedBox(height: Gap.md),
              const _Label('Mobile Number'),
              AppTextField(
                  hint: 'Mobile Number',
                  controller: _phone,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: Gap.md),
              const _Label('Email Address'),
              AppTextField(
                  hint: 'Email Address',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: Gap.xl),
              PrimaryButton(label: 'Save Changes', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() => Center(
        child: Stack(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('RP',
                  style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    size: 18, color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
      );
}
