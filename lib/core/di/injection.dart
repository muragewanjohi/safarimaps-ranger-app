import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/data_remote_datasource.dart';
import '../../data/datasources/park_remote_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/data_repository.dart';
import '../../data/repositories/park_repository.dart';
import '../../data/services/location_service.dart';
import '../../presentation/add_location/bloc/add_location_cubit.dart';
import '../../presentation/auth/bloc/auth_bloc.dart';
import '../../presentation/home/bloc/dashboard_cubit.dart';
import '../../presentation/park/bloc/park_cubit.dart';
import '../../presentation/profile/bloc/profile_cubit.dart';
import '../../presentation/reports/bloc/incidents_cubit.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final supabaseClient = _safeSupabaseClient();

  getIt
    ..registerLazySingleton<LocationService>(LocationService.new)
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<DataRemoteDataSource>(
      () => DataRemoteDataSource(
        supabaseClient,
        useMockData: AppConstants.useMockData,
      ),
    )
    ..registerLazySingleton<ParkRemoteDataSource>(
      () => ParkRemoteDataSource(supabaseClient),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt<AuthRemoteDataSource>()),
    )
    ..registerLazySingleton<DataRepository>(
      () => DataRepository(getIt<DataRemoteDataSource>()),
    )
    ..registerLazySingleton<ParkRepository>(
      () => ParkRepository(getIt<ParkRemoteDataSource>()),
    )
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<ParkCubit>(
      () => ParkCubit(getIt<ParkRepository>()),
    )
    ..registerLazySingleton<DashboardCubit>(
      () => DashboardCubit(getIt<DataRepository>()),
    )
    ..registerFactory<IncidentsCubit>(
      () => IncidentsCubit(getIt<DataRepository>()),
    )
    ..registerFactory<AddReportCubit>(
      () => AddReportCubit(getIt<DataRepository>()),
    )
    ..registerFactory<AddLocationCubit>(
      () => AddLocationCubit(getIt<DataRepository>()),
    )
    ..registerFactory<ProfileCubit>(
      () => ProfileCubit(getIt<DataRepository>()),
    )
    ..registerFactory<ParkDetailCubit>(
      () => ParkDetailCubit(getIt<ParkRepository>()),
    )
    ..registerFactory<MapCubit>(MapCubit.new);
}

SupabaseClient? _safeSupabaseClient() {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}
