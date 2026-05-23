import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/dashboard_models.dart';
import '../../../data/models/park_model.dart';
import '../../../data/repositories/data_repository.dart';
import '../../../data/repositories/park_repository.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._dataRepository) : super(const ProfileState.initial());

  final DataRepository _dataRepository;

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true));
    final results = await Future.wait([
      _dataRepository.getRangerData(),
      _dataRepository.getImpactStats(),
      _dataRepository.getAchievements(),
    ]);
    emit(state.copyWith(
      isLoading: false,
      ranger: results[0].data as RangerProfile?,
      impactStats: results[1].data as ImpactStats?,
      achievements: results[2].data as List<Achievement>? ?? [],
    ));
  }

  void togglePushNotifications(bool value) =>
      emit(state.copyWith(pushNotifications: value));

  void toggleLocationSharing(bool value) =>
      emit(state.copyWith(locationSharing: value));

  void toggleOfflineMode(bool value) =>
      emit(state.copyWith(offlineMode: value));

  void toggleAutoSync(bool value) => emit(state.copyWith(autoSync: value));
}

class ProfileState extends Equatable {
  const ProfileState({
    this.ranger,
    this.impactStats,
    this.achievements = const [],
    this.isLoading = false,
    this.pushNotifications = true,
    this.locationSharing = true,
    this.offlineMode = false,
    this.autoSync = true,
  });

  const ProfileState.initial() : this();

  final RangerProfile? ranger;
  final ImpactStats? impactStats;
  final List<Achievement> achievements;
  final bool isLoading;
  final bool pushNotifications;
  final bool locationSharing;
  final bool offlineMode;
  final bool autoSync;

  ProfileState copyWith({
    RangerProfile? ranger,
    ImpactStats? impactStats,
    List<Achievement>? achievements,
    bool? isLoading,
    bool? pushNotifications,
    bool? locationSharing,
    bool? offlineMode,
    bool? autoSync,
  }) {
    return ProfileState(
      ranger: ranger ?? this.ranger,
      impactStats: impactStats ?? this.impactStats,
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      locationSharing: locationSharing ?? this.locationSharing,
      offlineMode: offlineMode ?? this.offlineMode,
      autoSync: autoSync ?? this.autoSync,
    );
  }

  @override
  List<Object?> get props => [
        ranger,
        impactStats,
        achievements,
        isLoading,
        pushNotifications,
        locationSharing,
        offlineMode,
        autoSync,
      ];
}

class ParkDetailCubit extends Cubit<ParkDetailState> {
  ParkDetailCubit(this._parkRepository) : super(const ParkDetailState.initial());

  final ParkRepository _parkRepository;

  Future<void> loadPark(String parkId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final park = await _parkRepository.getParkById(parkId);
      final entries = await _parkRepository.getParkEntries(parkId);
      emit(state.copyWith(
        isLoading: false,
        park: park,
        entries: entries,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> updatePark(ParkModel park) async {
    emit(state.copyWith(isSaving: true));
    try {
      final updated = await _parkRepository.updatePark(park.id, park);
      emit(state.copyWith(isSaving: false, park: updated));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  Future<void> addEntry(ParkEntryModel entry) async {
    final created = await _parkRepository.createParkEntry(entry);
    emit(state.copyWith(entries: [...state.entries, created]));
  }

  Future<void> deleteEntry(String id) async {
    await _parkRepository.deleteParkEntry(id);
    emit(state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    ));
  }
}

class ParkDetailState extends Equatable {
  const ParkDetailState({
    this.park,
    this.entries = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  const ParkDetailState.initial() : this();

  final ParkModel? park;
  final List<ParkEntryModel> entries;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  ParkDetailState copyWith({
    ParkModel? park,
    List<ParkEntryModel>? entries,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return ParkDetailState(
      park: park ?? this.park,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }

  @override
  List<Object?> get props => [park, entries, isLoading, isSaving, error];
}

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(const MapState.initial());

  void setFilter(String filter) => emit(state.copyWith(filter: filter));
  void toggleMapVisibility() =>
      emit(state.copyWith(showMap: !state.showMap));
  void setMarkers(List<MapLocation> markers) =>
      emit(state.copyWith(markers: markers));
}

class MapState extends Equatable {
  const MapState({
    this.filter = 'All Locations',
    this.showMap = true,
    this.markers = const [],
  });

  const MapState.initial() : this();

  final String filter;
  final bool showMap;
  final List<MapLocation> markers;

  MapState copyWith({
    String? filter,
    bool? showMap,
    List<MapLocation>? markers,
  }) {
    return MapState(
      filter: filter ?? this.filter,
      showMap: showMap ?? this.showMap,
      markers: markers ?? this.markers,
    );
  }

  @override
  List<Object?> get props => [filter, showMap, markers];
}
