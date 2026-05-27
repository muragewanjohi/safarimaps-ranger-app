import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/data_repository.dart';

part 'incidents_state.dart';

class IncidentsCubit extends Cubit<IncidentsState> {
  IncidentsCubit(this._dataRepository) : super(const IncidentsState.initial());

  final DataRepository _dataRepository;

  Future<void> loadIncidents({String? parkId}) async {
    emit(state.copyWith(isLoading: true, error: null));
    final response = await _dataRepository.getIncidents(parkId: parkId);
    if (response.success) {
      emit(state.copyWith(
        isLoading: false,
        incidents: response.data ?? [],
      ));
    } else {
      emit(state.copyWith(
        isLoading: false,
        error: response.error,
        incidents: [],
      ));
    }
  }

  void setFilter(String filter) {
    emit(state.copyWith(filter: filter));
  }
}

class AddReportCubit extends Cubit<AddReportState> {
  AddReportCubit(this._dataRepository) : super(const AddReportState.initial());

  final DataRepository _dataRepository;

  void updateField({
    String? title,
    String? category,
    String? severity,
    String? status,
    String? description,
    String? coordinates,
    String? location,
    int? touristsAffected,
    String? tourOperator,
    String? transport,
    String? medicalCondition,
    List<String>? tags,
    List<String>? photos,
  }) {
    emit(state.copyWith(
      title: title ?? state.title,
      category: category ?? state.category,
      severity: severity ?? state.severity,
      status: status ?? state.status,
      description: description ?? state.description,
      coordinates: coordinates ?? state.coordinates,
      location: location ?? state.location,
      touristsAffected: touristsAffected ?? state.touristsAffected,
      tourOperator: tourOperator ?? state.tourOperator,
      transport: transport ?? state.transport,
      medicalCondition: medicalCondition ?? state.medicalCondition,
      tags: tags ?? state.tags,
      photos: photos ?? state.photos,
    ));
  }

  Future<void> loadForEdit(String? id) async {
    if (id == null || id.isEmpty) {
      emit(const AddReportState.initial());
      return;
    }
    emit(state.copyWith(isLoading: true, isEditMode: true, incidentId: id, error: null));
    try {
      final incidentsResponse = await _dataRepository.getIncidents();
      IncidentModel? incident;
      if (incidentsResponse.success && incidentsResponse.data != null) {
        for (final element in incidentsResponse.data!) {
          if (element.id == id) {
            incident = element;
            break;
          }
        }
      }
      
      if (incident == null) {
        emit(state.copyWith(isLoading: false, error: 'Incident not found'));
        return;
      }

      final notesResponse = await _dataRepository.getIncidentNotes(id);
      final notes = notesResponse.success ? (notesResponse.data ?? []) : <IncidentNoteModel>[];

      emit(state.copyWith(
        isLoading: false,
        isEditMode: true,
        incidentId: id,
        title: incident.title,
        category: incident.category,
        severity: incident.severity,
        status: incident.status,
        description: incident.description,
        coordinates: incident.coordinates,
        location: incident.location,
        touristsAffected: incident.touristsAffected ?? 0,
        tourOperator: incident.tourOperator,
        transport: incident.transport,
        medicalCondition: incident.medicalCondition,
        tags: incident.tags,
        photos: incident.photos,
        notes: notes,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<bool> addNote(String noteText) async {
    final incidentId = state.incidentId;
    if (incidentId == null || incidentId.isEmpty) return false;
    emit(state.copyWith(isSubmittingNote: true, error: null));
    final response = await _dataRepository.addIncidentNote(incidentId, noteText);
    if (response.success && response.data != null) {
      emit(state.copyWith(
        isSubmittingNote: false,
        notes: [...state.notes, response.data!],
      ));
      return true;
    }
    emit(state.copyWith(
      isSubmittingNote: false,
      error: response.error ?? 'Failed to add note',
    ));
    return false;
  }

  Future<bool> submit({String? parkId}) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    final incident = IncidentModel(
      id: state.incidentId ?? '',
      title: state.title,
      category: state.category,
      severity: state.severity,
      status: state.status,
      description: state.description,
      coordinates: state.coordinates,
      location: state.location,
      touristsAffected: state.touristsAffected,
      tourOperator: state.tourOperator,
      transport: state.transport,
      medicalCondition: state.medicalCondition,
      tags: state.tags,
    );

    final response = state.isEditMode
        ? await _dataRepository.updateIncident(incident, parkId: parkId)
        : await _dataRepository.addIncident(incident, parkId: parkId, photoPaths: state.photos);

    if (response.success) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        successMessage: response.message,
      ));
      return true;
    }

    emit(state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Failed to submit report',
    ));
    return false;
  }
}

class AddReportState extends Equatable {
  const AddReportState({
    this.title = '',
    this.category = 'Wildlife',
    this.severity = 'Medium',
    this.status = 'Reported',
    this.description = '',
    this.coordinates,
    this.location,
    this.touristsAffected = 0,
    this.tourOperator,
    this.transport,
    this.medicalCondition,
    this.tags = const [],
    this.photos = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
    this.successMessage,
    this.isEditMode = false,
    this.incidentId,
    this.notes = const [],
    this.isLoading = false,
    this.isSubmittingNote = false,
  });

  const AddReportState.initial() : this();

  final String title;
  final String category;
  final String severity;
  final String status;
  final String description;
  final String? coordinates;
  final String? location;
  final int touristsAffected;
  final String? tourOperator;
  final String? transport;
  final String? medicalCondition;
  final List<String> tags;
  final List<String> photos;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;
  final String? successMessage;
  final bool isEditMode;
  final String? incidentId;
  final List<IncidentNoteModel> notes;
  final bool isLoading;
  final bool isSubmittingNote;

  AddReportState copyWith({
    String? title,
    String? category,
    String? severity,
    String? status,
    String? description,
    String? coordinates,
    String? location,
    int? touristsAffected,
    String? tourOperator,
    String? transport,
    String? medicalCondition,
    List<String>? tags,
    List<String>? photos,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    String? successMessage,
    bool? isEditMode,
    String? incidentId,
    List<IncidentNoteModel>? notes,
    bool? isLoading,
    bool? isSubmittingNote,
  }) {
    return AddReportState(
      title: title ?? this.title,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      description: description ?? this.description,
      coordinates: coordinates ?? this.coordinates,
      location: location ?? this.location,
      touristsAffected: touristsAffected ?? this.touristsAffected,
      tourOperator: tourOperator ?? this.tourOperator,
      transport: transport ?? this.transport,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      tags: tags ?? this.tags,
      photos: photos ?? this.photos,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      successMessage: successMessage ?? this.successMessage,
      isEditMode: isEditMode ?? this.isEditMode,
      incidentId: incidentId ?? this.incidentId,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingNote: isSubmittingNote ?? this.isSubmittingNote,
    );
  }

  @override
  List<Object?> get props => [
        title,
        category,
        severity,
        status,
        description,
        coordinates,
        location,
        touristsAffected,
        tourOperator,
        transport,
        medicalCondition,
        tags,
        photos,
        isSubmitting,
        isSuccess,
        error,
        successMessage,
        isEditMode,
        incidentId,
        notes,
        isLoading,
        isSubmittingNote,
      ];
}
