import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/utils/validators.dart';
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSizes.xxl),
                Text(
                  'Sign In',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSizes.xl),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSizes.md),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  validator: Validators.required,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: AppSizes.sm),
                TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
                const SizedBox(height: AppSizes.xl),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                ),
                const SizedBox(height: AppSizes.sm),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                ),
                const SizedBox(height: AppSizes.xl),
                TextButton(
                  onPressed: () => context.go(AppRoutes.signup),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
