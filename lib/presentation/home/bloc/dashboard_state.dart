part of 'dashboard_cubit.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.ranger,
    this.stats,
    this.emergencyAlerts = const [],
    this.recentIncidents = const [],
    this.recentLocations = const [],
    this.isLoading = false,
    this.error,
    this.isOffline = false,
    this.pendingSyncItems = 0,
  });

  const DashboardState.initial() : this();

  final RangerProfile? ranger;
  final DashboardStats? stats;
  final List<EmergencyAlert> emergencyAlerts;
  final List<IncidentSummary> recentIncidents;
  final List<LocationItem> recentLocations;
  final bool isLoading;
  final String? error;
  final bool isOffline;
  final int pendingSyncItems;

  DashboardState copyWith({
    RangerProfile? ranger,
    DashboardStats? stats,
    List<EmergencyAlert>? emergencyAlerts,
    List<IncidentSummary>? recentIncidents,
    List<LocationItem>? recentLocations,
    bool? isLoading,
    String? error,
    bool? isOffline,
    int? pendingSyncItems,
  }) {
    return DashboardState(
      ranger: ranger ?? this.ranger,
      stats: stats ?? this.stats,
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      recentIncidents: recentIncidents ?? this.recentIncidents,
      recentLocations: recentLocations ?? this.recentLocations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOffline: isOffline ?? this.isOffline,
      pendingSyncItems: pendingSyncItems ?? this.pendingSyncItems,
    );
  }

  @override
  List<Object?> get props => [
        ranger,
        stats,
        emergencyAlerts,
        recentIncidents,
        recentLocations,
        isLoading,
        error,
        isOffline,
        pendingSyncItems,
      ];
}
