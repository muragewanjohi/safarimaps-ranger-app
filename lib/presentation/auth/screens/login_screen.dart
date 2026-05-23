import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_screen_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final authRepo = getIt<AuthRepository>();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter both email and password.');
      return;
    }
    if (!authRepo.validateEmail(email)) {
      _showSnack('Please enter a valid email address.');
      return;
    }

    context.read<AuthBloc>().add(
          AuthLoginRequested(email: email, password: password),
        );
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
          if (state.isAuthenticated) {
            context.go('/');
          } else if (state.error != null) {
            _showSnack(state.error!);
          }
        },
        builder: (context, state) {
          return AuthScreenShell(
            title: 'SafariMap GameWarden',
            subtitle: 'Sign in to manage patrols, reports, and park operations.',
            form: AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthFieldLabel(label: 'Email address'),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocusNode),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                      hintText: 'you@park.gov',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const AuthFieldLabel(label: 'Password'),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Hide password' : 'Show password',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (state.error != null) ...[
                    AuthErrorBanner(message: state.error!),
                    const SizedBox(height: 16),
                  ],
                  AuthPrimaryButton(
                    label: 'Sign in',
                    loadingLabel: 'Signing in…',
                    isLoading: state.isLoading,
                    onPressed: _handleLogin,
                  ),
                ],
              ),
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
