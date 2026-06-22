import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/aurora_colors.dart';
import '../../../core/theme/aurora_radius.dart';
import '../../../core/theme/aurora_spacing.dart';
import '../../../core/theme/aurora_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/aurora/aurora.dart';
import '../../../core/widgets/snackbar_service.dart';
import '../../../services/providers/service_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .resetPassword(_emailController.text.trim());
      if (mounted) {
        SnackbarService.showSuccess(
          context,
          'Check your email for a reset link',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Failed to send reset link. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reset Password',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AuroraSpacing.screenPadH,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AuroraSpacing.space7),

              // ── Description ───────────────────────────────────────────────
              Text(
                "Enter your email address and we'll send you a link to reset your password.",
                style: AuroraType.body.copyWith(
                  color: AuroraColors.inkSecondary,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AuroraSpacing.space8),

              // ── Email field ───────────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'EMAIL',
                      style: AuroraType.label
                          .copyWith(color: AuroraColors.inkSecondary),
                      children: const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: AuroraColors.coral),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AuroraSpacing.space1),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    onFieldSubmitted: (_) => _sendResetLink(),
                    style: AuroraType.body,
                    cursorColor: AuroraColors.coral,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AuroraColors.paper,
                      hintText: 'your@email.com',
                      hintStyle: AuroraType.body.copyWith(
                        color: AuroraColors.inkTertiary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AuroraSpacing.space7,
                        vertical: AuroraSpacing.space5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AuroraRadius.md,
                        borderSide: const BorderSide(
                          color: AuroraColors.inkBorder,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AuroraRadius.md,
                        borderSide: const BorderSide(
                          color: AuroraColors.inkBorder,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AuroraRadius.md,
                        borderSide: const BorderSide(
                          color: AuroraColors.coral,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: AuroraRadius.md,
                        borderSide: const BorderSide(
                          color: AuroraColors.coral,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: AuroraRadius.md,
                        borderSide: const BorderSide(
                          color: AuroraColors.coral,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: Validators.email,
                  ),
                ],
              ),

              const SizedBox(height: AuroraSpacing.space9),

              // ── Send CTA — coral PrimaryButton (navigation, not form save) ─
              PrimaryButton(
                label: 'Send Reset Link',
                onPressed: _sendResetLink,
                loading: _isLoading,
                expand: true,
              ),

              const SizedBox(height: AuroraSpacing.space7),
            ],
          ),
        ),
      ),
    );
  }
}
