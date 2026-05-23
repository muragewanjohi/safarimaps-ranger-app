import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_screen_shell.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    final email = _emailController.text.trim();
    final authRepo = getIt<AuthRepository>();

    if (email.isEmpty) {
      _showSnack('Please enter your email address.');
      return;
    }
    if (!authRepo.validateEmail(email)) {
      _showSnack('Please enter a valid email address.');
      return;
    }

    context.read<AuthBloc>().add(AuthResetPasswordRequested(email: email));
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.authTheme(context),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.message != null) {
            _showSnack(state.message!);
          } else if (state.error != null) {
            _showSnack(state.error!);
          }
        },
        builder: (context, state) {
          return AuthScreenShell(
            onBack: () => context.go('/login'),
            title: 'Reset password',
            subtitle:
                'Enter the email linked to your account and we\'ll send a reset link.',
            form: AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthFieldLabel(label: 'Email address'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _handleReset(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      hintText: 'you@park.gov',
                    ),
                  ),
                  if (state.message != null) ...[
                    const SizedBox(height: 20),
                    AuthSuccessBanner(message: state.message!),
                  ],
                  if (state.error != null) ...[
                    const SizedBox(height: 20),
                    AuthErrorBanner(message: state.error!),
                  ],
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Send reset link',
                    loadingLabel: 'Sending…',
                    isLoading: state.isLoading,
                    onPressed: _handleReset,
                  ),
                ],
              ),
            ),
            footer: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to sign in'),
            ),
          );
        },
      ),
    );
  }
}
