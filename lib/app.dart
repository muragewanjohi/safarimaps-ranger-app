import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/park/bloc/park_cubit.dart';

class RangerApp extends StatefulWidget {
  const RangerApp({super.key});

  @override
  State<RangerApp> createState() => _RangerAppState();
}

class _RangerAppState extends State<RangerApp> {
  late final _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthBloc>()),
        BlocProvider.value(value: getIt<ParkCubit>()),
      ],
      child: MaterialApp.router(
        title: 'SafariMap GameWarden',
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
