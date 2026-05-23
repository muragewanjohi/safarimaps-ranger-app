part of 'incidents_cubit.dart';

class IncidentsState extends Equatable {
  const IncidentsState({
    this.incidents = const [],
    this.isLoading = false,
    this.error,
    this.filter = 'All',
  });

  const IncidentsState.initial() : this();

  final List<IncidentModel> incidents;
  final bool isLoading;
  final String? error;
  final String filter;

  int get criticalCount =>
      incidents.where((i) => i.severity == 'Critical').length;
  int get highCount => incidents.where((i) => i.severity == 'High').length;
  int get activeCount =>
      incidents.where((i) => i.status != 'Resolved').length;

  IncidentsState copyWith({
    List<IncidentModel>? incidents,
    bool? isLoading,
    String? error,
    String? filter,
  }) {
    return IncidentsState(
      incidents: incidents ?? this.incidents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [incidents, isLoading, error, filter];
}
