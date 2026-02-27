import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_scaffold.dart';
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
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.lg),
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.xl),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                onFieldSubmitted: (_) => _sendResetLink(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSizes.lg),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Reset Link'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
