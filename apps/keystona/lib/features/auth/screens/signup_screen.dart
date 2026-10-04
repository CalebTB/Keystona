import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
          );
      if (mounted) {
        context.go(AppRoutes.onboarding);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AuroraSpacing.screenPadH,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AuroraSpacing.space10),

                // ── Screen title ──────────────────────────────────────────────
                Text('Create Account', style: AuroraType.h1),

                const SizedBox(height: AuroraSpacing.space2),

                Text(
                  'Start managing your home smarter.',
                  style: AuroraType.body.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space10),

                // ── Full name ─────────────────────────────────────────────────
                _AuroraFormField(
                  label: 'Full Name',
                  isRequired: true,
                  child: TextFormField(
                    controller: _fullNameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    style: AuroraType.body,
                    cursorColor: AuroraColors.coral,
                    decoration: _inputDecoration('Jane Smith'),
                    validator: Validators.required,
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space7),

                // ── Email ─────────────────────────────────────────────────────
                _AuroraFormField(
                  label: 'Email',
                  isRequired: true,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    style: AuroraType.body,
                    cursorColor: AuroraColors.coral,
                    decoration: _inputDecoration('your@email.com'),
                    validator: Validators.email,
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space7),

                // ── Password ──────────────────────────────────────────────────
                _AuroraFormField(
                  label: 'Password',
                  isRequired: true,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    style: AuroraType.body,
                    cursorColor: AuroraColors.coral,
                    decoration: _inputDecoration('Min. 8 characters'),
                    validator: Validators.required,
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space7),

                // ── Confirm password ──────────────────────────────────────────
                _AuroraFormField(
                  label: 'Confirm Password',
                  isRequired: true,
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _createAccount(),
                    style: AuroraType.body,
                    cursorColor: AuroraColors.coral,
                    decoration: _inputDecoration('Repeat your password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space10),

                // ── Create account CTA ────────────────────────────────────────
                PrimaryButton(
                  label: 'Create Account',
                  onPressed: _createAccount,
                  loading: _isLoading,
                  expand: true,
                ),

                const SizedBox(height: AuroraSpacing.space10),

                // ── Sign in link ──────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AuroraType.body.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: AuroraType.body.copyWith(
                              color: AuroraColors.coral,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

InputDecoration _inputDecoration(String hint) => InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AuroraColors.paper,
      hintText: hint,
      hintStyle: AuroraType.body.copyWith(color: AuroraColors.inkTertiary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AuroraSpacing.space7,
        vertical: AuroraSpacing.space5,
      ),
      border: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.inkBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.inkBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.coral, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.coral, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AuroraRadius.md,
        borderSide: const BorderSide(color: AuroraColors.coral, width: 2),
      ),
    );

/// Aurora-styled label above a form field.
class _AuroraFormField extends StatelessWidget {
  const _AuroraFormField({
    required this.label,
    required this.child,
    this.isRequired = false,
  });

  final String label;
  final bool isRequired;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRequired)
          RichText(
            text: TextSpan(
              text: label.toUpperCase(),
              style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AuroraColors.coral),
                ),
              ],
            ),
          )
        else
          Text(
            label.toUpperCase(),
            style: AuroraType.label.copyWith(color: AuroraColors.inkSecondary),
          ),
        const SizedBox(height: AuroraSpacing.space1),
        child,
      ],
    );
  }
}
