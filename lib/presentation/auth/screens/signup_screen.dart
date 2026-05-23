import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_screen_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rangerIdController = TextEditingController();
  final _teamController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _rangerIdFocusNode = FocusNode();
  final _teamFocusNode = FocusNode();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthErrorCleared());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rangerIdController.dispose();
    _teamController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _rangerIdFocusNode.dispose();
    _teamFocusNode.dispose();
    super.dispose();
  }

  void _handleSignup() {
    final authRepo = getIt<AuthRepository>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final rangerId = _rangerIdController.text.trim().toUpperCase();
    final team = _teamController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Please fill in all required fields.');
      return;
    }
    if (!authRepo.validateEmail(email)) {
      _showSnack('Please enter a valid email address.');
      return;
    }
    final passwordError = authRepo.validatePassword(password);
    if (passwordError != null) {
      _showSnack(passwordError);
      return;
    }
    if (rangerId.isNotEmpty && !authRepo.validateRangerId(rangerId)) {
      _showSnack('Ranger ID must be in format ABC-123');
      return;
    }

    context.read<AuthBloc>().add(AuthSignupRequested(
          email: email,
          password: password,
          name: name,
          rangerId: rangerId.isEmpty ? null : rangerId,
          team: team.isEmpty ? null : team,
        ));
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
            _showSnack('Account created successfully!');
            context.go('/');
          } else if (state.error != null) {
            _showSnack(state.error!);
          }
        },
        builder: (context, state) {
          return AuthScreenShell(
            onBack: () => context.go('/login'),
            title: 'Join the team',
            subtitle: 'Create your ranger account to access patrol tools and reports.',
            form: AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthFieldLabel(label: 'Full name'),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocusNode),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      hintText: 'Jane Ranger',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AuthFieldLabel(label: 'Email address'),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
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
                  const SizedBox(height: 16),
                  const AuthFieldLabel(label: 'Password'),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_rangerIdFocusNode),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      hintText: 'Create a strong password',
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
                  const SizedBox(height: 20),
                  Text(
                    'Optional details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 13,
                          color: AppTheme.authMutedText,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 12),
                  const AuthFieldLabel(label: 'Ranger ID'),
                  TextField(
                    controller: _rangerIdController,
                    focusNode: _rangerIdFocusNode,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                    ],
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_teamFocusNode),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.badge_outlined),
                      hintText: 'ABC-123',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const AuthFieldLabel(label: 'Team'),
                  TextField(
                    controller: _teamController,
                    focusNode: _teamFocusNode,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _handleSignup(),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.groups_outlined),
                      hintText: 'Northern patrol',
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 20),
                    AuthErrorBanner(message: state.error!),
                  ],
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Create account',
                    loadingLabel: 'Creating account…',
                    isLoading: state.isLoading,
                    onPressed: _handleSignup,
                  ),
                ],
              ),
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
