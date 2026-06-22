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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // Router auto-redirects to dashboard when isAuthenticatedProvider updates.
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
                Text('Sign In', style: AuroraType.h1),

                const SizedBox(height: AuroraSpacing.space2),

                Text(
                  'Welcome back to Keystona.',
                  style: AuroraType.body.copyWith(
                    color: AuroraColors.inkSecondary,
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space10),

                // ── Email field ───────────────────────────────────────────────
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

                // ── Password field ────────────────────────────────────────────
                _AuroraFormField(
                  label: 'Password',
                  isRequired: true,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _signIn(),
                    style: AuroraType.body,
                    cursorColor: AuroraColors.coral,
                    decoration: _inputDecoration('••••••••'),
                    validator: Validators.required,
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space3),

                // ── Forgot password link ──────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: GhostButton(
                    label: 'Forgot password?',
                    onPressed: () => context.go(AppRoutes.forgotPassword),
                  ),
                ),

                const SizedBox(height: AuroraSpacing.space9),

                // ── Sign in CTA ───────────────────────────────────────────────
                PrimaryButton(
                  label: 'Sign In',
                  onPressed: _signIn,
                  loading: _isLoading,
                  expand: true,
                ),

                const SizedBox(height: AuroraSpacing.space8),

                // ── Divider ───────────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider(color: AuroraColors.inkBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AuroraSpacing.space7,
                      ),
                      child: Text(
                        'OR',
                        style: AuroraType.label.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AuroraColors.inkBorder)),
                  ],
                ),

                const SizedBox(height: AuroraSpacing.space8),

                // ── Social auth ───────────────────────────────────────────────
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continue with Google',
                  onPressed: null,
                ),

                const SizedBox(height: AuroraSpacing.space3),

                _SocialButton(
                  icon: Icons.apple,
                  label: 'Continue with Apple',
                  onPressed: null,
                ),

                const SizedBox(height: AuroraSpacing.space10),

                // ── Sign up link ──────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.signup),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: AuroraType.body.copyWith(
                          color: AuroraColors.inkSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign up',
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

/// Social sign-in button (outlined, paper bg).
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: AuroraColors.ink),
        label: Text(
          label,
          style: AuroraType.bodyLg.copyWith(
            fontWeight: FontWeight.w600,
            color: onPressed == null
                ? AuroraColors.inkTertiary
                : AuroraColors.ink,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AuroraColors.paper,
          side: const BorderSide(
            color: AuroraColors.inkBorder,
            width: 1.5,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AuroraRadius.full),
        ),
      ),
    );
  }
}
