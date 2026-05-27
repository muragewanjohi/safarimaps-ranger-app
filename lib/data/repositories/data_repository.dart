import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/di/injection.dart';
import '../../presentation/profile/bloc/profile_cubit.dart';
import '../datasources/data_remote_datasource.dart';
import '../datasources/local_database.dart';
import '../models/dashboard_models.dart';

class DataRepository {
  DataRepository(this._dataSource, this._localDatabase);

  final DataRemoteDataSource _dataSource;
  final LocalDatabase _localDatabase;

  Future<ApiResponse<RangerProfile>> getRangerData() =>
      _dataSource.getRangerData();

  Future<ApiResponse<DashboardStats>> getDashboardStats({String? parkId}) =>
      _dataSource.getDashboardStats(parkId: parkId);

  Future<ApiResponse<List<EmergencyAlert>>> getEmergencyAlerts({String? parkId}) =>
      _dataSource.getEmergencyAlerts(parkId: parkId);

  Future<ApiResponse<List<IncidentSummary>>> getRecentIncidents({String? parkId}) =>
      _dataSource.getRecentIncidents(parkId: parkId);

  Future<ApiResponse<List<LocationItem>>> getRecentLocations({String? parkId}) =>
      _dataSource.getRecentLocations(parkId: parkId);

  Future<ApiResponse<List<LocationItem>>> getAllLocations({String? parkId}) =>
      _dataSource.getAllLocations(parkId: parkId);

  Future<ApiResponse<Map<String, List<LocationItem>>>> getRecentLocationsByCategory({String? parkId}) =>
      _dataSource.getRecentLocationsByCategory(parkId: parkId);

  Future<ApiResponse<ImpactStats>> getImpactStats() =>
      _dataSource.getImpactStats();

  Future<ApiResponse<List<Achievement>>> getAchievements() =>
      _dataSource.getAchievements();

  Future<ApiResponse<List<IncidentModel>>> getIncidents({String? parkId}) =>
      _dataSource.getIncidents(parkId: parkId);

  Future<ApiResponse<IncidentModel>> addIncident(
    IncidentModel incident, {
    String? parkId,
    List<String> photoPaths = const [],
  }) async {
    final isOffline = getIt<ProfileCubit>().state.offlineMode;
    if (isOffline) {
      await _localDatabase.cacheIncident(incident, parkId: parkId, photoPaths: photoPaths);
      return ApiResponse(
        success: true,
        message: 'Saved offline. It will sync when connection is restored.',
        data: incident,
      );
    }

    try {
      final response = await _dataSource.addIncident(incident, parkId: parkId, photoPaths: photoPaths);
      if (!response.success) {
        if (_isNetworkError(response.error)) {
          await _localDatabase.cacheIncident(incident, parkId: parkId, photoPaths: photoPaths);
          return ApiResponse(
            success: true,
            message: 'Saved offline (network error). It will sync when connection is restored.',
            data: incident,
          );
        }
      }
      return response;
    } catch (e) {
      if (_isNetworkError(e.toString())) {
        await _localDatabase.cacheIncident(incident, parkId: parkId, photoPaths: photoPaths);
        return ApiResponse(
          success: true,
          message: 'Saved offline (network error). It will sync when connection is restored.',
          data: incident,
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<LocationItem>> addLocation(
    NewLocationInput location, {
    String? parkId,
  }) async {
    final isOffline = getIt<ProfileCubit>().state.offlineMode;
    if (isOffline) {
      await _localDatabase.cacheLocation(location, parkId: parkId);
      final titleText = location.attractionName ?? location.hotelName ?? location.subcategory;
      return ApiResponse(
        success: true,
        message: 'Saved offline. It will sync when connection is restored.',
        data: LocationItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: titleText.trim().isNotEmpty ? titleText.trim() : 'Location',
          category: location.category,
          description: location.description,
          coordinates: location.coordinates,
          reportedBy: 'Ranger',
          icon: 'map-marker',
          iconColor: '#10B981',
          timeAgo: 'Just now',
        ),
      );
    }

    try {
      final response = await _dataSource.addLocation(location, parkId: parkId);
      if (!response.success) {
        if (_isNetworkError(response.error)) {
          await _localDatabase.cacheLocation(location, parkId: parkId);
          final titleText = location.attractionName ?? location.hotelName ?? location.subcategory;
          return ApiResponse(
            success: true,
            message: 'Saved offline (network error). It will sync when connection is restored.',
            data: LocationItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: titleText.trim().isNotEmpty ? titleText.trim() : 'Location',
              category: location.category,
              description: location.description,
              coordinates: location.coordinates,
              reportedBy: 'Ranger',
              icon: 'map-marker',
              iconColor: '#10B981',
              timeAgo: 'Just now',
            ),
          );
        }
      }
      return response;
    } catch (e) {
      if (_isNetworkError(e.toString())) {
        await _localDatabase.cacheLocation(location, parkId: parkId);
        final titleText = location.attractionName ?? location.hotelName ?? location.subcategory;
        return ApiResponse(
          success: true,
          message: 'Saved offline (network error). It will sync when connection is restored.',
          data: LocationItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: titleText.trim().isNotEmpty ? titleText.trim() : 'Location',
            category: location.category,
            description: location.description,
            coordinates: location.coordinates,
            reportedBy: 'Ranger',
            icon: 'map-marker',
            iconColor: '#10B981',
            timeAgo: 'Just now',
          ),
        );
      }
      rethrow;
    }
  }

  Future<int> getPendingSyncCount() => _localDatabase.getPendingCount();

  Future<ApiResponse<IncidentModel>> updateIncident(
    IncidentModel incident, {
    String? parkId,
  }) async {
    final isOffline = getIt<ProfileCubit>().state.offlineMode;
    if (isOffline) {
      await _localDatabase.cacheIncident(incident, parkId: parkId);
      return ApiResponse(
        success: true,
        message: 'Updated offline. It will sync when connection is restored.',
        data: incident,
      );
    }

    try {
      final response = await _dataSource.updateIncident(incident);
      if (!response.success && _isNetworkError(response.error)) {
        await _localDatabase.cacheIncident(incident, parkId: parkId);
        return ApiResponse(
          success: true,
          message: 'Updated offline (network error). It will sync when connection is restored.',
          data: incident,
        );
      }
      return response;
    } catch (e) {
      if (_isNetworkError(e.toString())) {
        await _localDatabase.cacheIncident(incident, parkId: parkId);
        return ApiResponse(
          success: true,
          message: 'Updated offline (network error). It will sync when connection is restored.',
          data: incident,
        );
      }
      rethrow;
    }
  }

  Future<ApiResponse<List<IncidentNoteModel>>> getIncidentNotes(String incidentId) async {
    final isOffline = getIt<ProfileCubit>().state.offlineMode;
    if (isOffline) {
      final pending = await _localDatabase.getPendingNotes();
      final list = pending
          .where((row) => row['incident_id'] == incidentId)
          .map((row) => IncidentNoteModel(
                id: row['id'].toString(),
                incidentId: row['incident_id'] as String,
                note: row['note'] as String,
                createdBy: 'Sarah Johnson',
                createdAt: row['created_at'] as String,
              ))
          .toList();
      return ApiResponse(success: true, data: list);
    }

    try {
      final response = await _dataSource.getIncidentNotes(incidentId);
      if (!response.success && _isNetworkError(response.error)) {
        final pending = await _localDatabase.getPendingNotes();
        final list = pending
            .where((row) => row['incident_id'] == incidentId)
            .map((row) => IncidentNoteModel(
                  id: row['id'].toString(),
                  incidentId: row['incident_id'] as String,
                  note: row['note'] as String,
                  createdBy: 'Sarah Johnson',
                  createdAt: row['created_at'] as String,
                ))
            .toList();
        return ApiResponse(success: true, data: list);
      }
      return response;
    } catch (e) {
      if (_isNetworkError(e.toString())) {
        final pending = await _localDatabase.getPendingNotes();
        final list = pending
            .where((row) => row['incident_id'] == incidentId)
            .map((row) => IncidentNoteModel(
                  id: row['id'].toString(),
                  incidentId: row['incident_id'] as String,
                  note: row['note'] as String,
                  createdBy: 'Sarah Johnson',
                  createdAt: row['created_at'] as String,
                ))
            .toList();
        return ApiResponse(success: true, data: list);
      }
      rethrow;
    }
  }

  Future<ApiResponse<IncidentNoteModel>> addIncidentNote(String incidentId, String noteText) async {
    final isOffline = getIt<ProfileCubit>().state.offlineMode;
    if (isOffline) {
      await _localDatabase.cacheNote(incidentId, noteText);
      return ApiResponse(
        success: true,
        message: 'Note saved offline. It will sync when connection is restored.',
        data: IncidentNoteModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          incidentId: incidentId,
          note: noteText,
          createdBy: 'Sarah Johnson',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    }

    try {
      final response = await _dataSource.addIncidentNote(incidentId, noteText);
      if (!response.success && _isNetworkError(response.error)) {
        await _localDatabase.cacheNote(incidentId, noteText);
        return ApiResponse(
          success: true,
          message: 'Note saved offline (network error). It will sync when connection is restored.',
          data: IncidentNoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            incidentId: incidentId,
            note: noteText,
            createdBy: 'Sarah Johnson',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      return response;
    } catch (e) {
      if (_isNetworkError(e.toString())) {
        await _localDatabase.cacheNote(incidentId, noteText);
        return ApiResponse(
          success: true,
          message: 'Note saved offline (network error). It will sync when connection is restored.',
          data: IncidentNoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            incidentId: incidentId,
            note: noteText,
            createdBy: 'Sarah Johnson',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }
      rethrow;
    }
  }

  Future<bool> syncPendingItems() async {
    try {
      final incidents = await _localDatabase.getPendingIncidents();
      final locations = await _localDatabase.getPendingLocations();
      final notes = await _localDatabase.getPendingNotes();

      if (incidents.isEmpty && locations.isEmpty && notes.isEmpty) return true;

      // Sync incidents
      for (final row in incidents) {
        final id = row['id'] as int;
        final dataStr = row['data'] as String;
        final photoPathsStr = row['photo_paths'] as String;
        final parkId = row['park_id'] as String?;

        final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(dataStr));
        final List<String> photoPaths = List<String>.from(jsonDecode(photoPathsStr));
        final incident = IncidentModel.fromJson(data);

        final response = incident.id.isEmpty
            ? await _dataSource.addIncident(incident, parkId: parkId, photoPaths: photoPaths)
            : await _dataSource.updateIncident(incident);
            
        if (response.success) {
          await _localDatabase.deletePendingIncident(id);
        } else {
          return false;
        }
      }

      // Sync locations
      for (final row in locations) {
        final id = row['id'] as int;
        final dataStr = row['data'] as String;
        final parkId = row['park_id'] as String?;

        final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(dataStr));
        final location = NewLocationInput.fromJson(data);

        final response = await _dataSource.addLocation(location, parkId: parkId);
        if (response.success) {
          await _localDatabase.deletePendingLocation(id);
        } else {
          return false;
        }
      }

      // Sync notes
      for (final row in notes) {
        final noteId = row['id'] as int;
        final incidentId = row['incident_id'] as String;
        final noteText = row['note'] as String;

        final response = await _dataSource.addIncidentNote(incidentId, noteText);
        if (response.success) {
          await _localDatabase.deletePendingNote(noteId);
        } else {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Sync pending items failed: $e');
      return false;
    }
  }

  bool _isNetworkError(String? error) {
    if (error == null) return false;
    final lowercase = error.toLowerCase();
    return lowercase.contains('socketexception') ||
           lowercase.contains('network') ||
           lowercase.contains('timeout') ||
           lowercase.contains('failed to connect') ||
           lowercase.contains('connection refused') ||
           lowercase.contains('connection timed out');
  }
}

