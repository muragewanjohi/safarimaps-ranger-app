import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/data_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._dataRepository) : super(const DashboardState.initial());

  final DataRepository _dataRepository;

  Future<void> loadDashboard({String? parkId}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final results = await Future.wait([
        _dataRepository.getRangerData(),
        _dataRepository.getDashboardStats(parkId: parkId),
        _dataRepository.getEmergencyAlerts(parkId: parkId),
        _dataRepository.getRecentIncidents(parkId: parkId),
        _dataRepository.getRecentLocations(parkId: parkId),
      ]);

      final rangerResponse = results[0] as ApiResponse<RangerProfile>;
      final statsResponse = results[1] as ApiResponse<DashboardStats>;
      final alertsResponse = results[2] as ApiResponse<List<EmergencyAlert>>;
      final incidentsResponse = results[3] as ApiResponse<List<IncidentSummary>>;
      final locationsResponse = results[4] as ApiResponse<List<LocationItem>>;

      emit(state.copyWith(
        isLoading: false,
        ranger: rangerResponse.data,
        stats: statsResponse.data,
        emergencyAlerts: alertsResponse.data ?? [],
        recentIncidents: incidentsResponse.data ?? [],
        recentLocations: locationsResponse.data ?? [],
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
