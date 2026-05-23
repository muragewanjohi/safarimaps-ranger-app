import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/add_location/bloc/add_location_cubit.dart';
import '../../presentation/add_location/screens/add_location_screen.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/auth/screens/auth_splash_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/signup_screen.dart';
import '../../presentation/home/screens/home_screen.dart';
import '../../presentation/map/screens/map_screen.dart';
import '../../presentation/park/bloc/park_cubit.dart';
import '../../presentation/park/screens/park_detail_screen.dart';
import '../../presentation/profile/screens/profile_screen.dart';
import '../../presentation/reports/bloc/incidents_cubit.dart';
import '../../presentation/reports/screens/add_report_screen.dart';
import '../../presentation/reports/screens/reports_screen.dart';
import '../../presentation/shell/main_shell.dart';
import '../di/injection.dart';

class AppRouter {
  static GoRouter create() {
    final authBloc = getIt<AuthBloc>();

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: _AuthRefreshListenable(authBloc),
      redirect: (context, state) {
        final authState = authBloc.state;
        final location = state.matchedLocation;
        final isAuthenticated = authState.isAuthenticated;
        final isBootstrapping = authState.isBootstrapping;
        final isAuthRoute = location == '/login' ||
            location == '/signup' ||
            location == '/forgot-password';
        final isSplash = location == '/splash';

        if (isBootstrapping) {
          return isSplash ? null : '/splash';
        }

        if (!isAuthenticated) {
          return isAuthRoute ? null : '/login';
        }

        if (isAuthRoute || isSplash) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const AuthSplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
            GoRoute(
              path: '/map',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MapScreen(),
              ),
            ),
            GoRoute(
              path: '/reports',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ReportsScreen(),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfileScreen(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/add-report',
          builder: (context, state) => BlocProvider(
            create: (_) => getIt<AddReportCubit>(),
            child: const AddReportScreen(),
          ),
        ),
        GoRoute(
          path: '/add-location',
          builder: (context, state) {
            final photoPath = state.uri.queryParameters['photo'];
            return BlocProvider(
              create: (_) => getIt<AddLocationCubit>(),
              child: AddLocationScreen(initialPhotoPath: photoPath),
            );
          },
        ),
        GoRoute(
          path: '/park',
          builder: (context, state) {
            final parkId = state.uri.queryParameters['id'] ??
                getIt<ParkCubit>().state.selectedPark?.id ??
                '';
            return ParkDetailScreen(parkId: parkId);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: Center(child: Text('Page not found: ${state.uri}')),
      ),
    );
  }
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
