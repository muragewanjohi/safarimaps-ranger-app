import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/dashboard_models.dart';
import 'mock_data.dart';

class DataRemoteDataSource {
  DataRemoteDataSource(this._client, {required this.useMockData});

  final SupabaseClient? _client;
  final bool useMockData;
  static const _uuid = Uuid();

  Future<ApiResponse<RangerProfile>> getRangerData() async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: MockData.ranger);
    }

    try {
      final user = _client?.auth.currentUser;
      if (user == null) {
        return const ApiResponse(success: false, error: 'User not authenticated');
      }

      final profile = await _client!
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return ApiResponse(
        success: true,
        data: RangerProfile(
          id: profile['id'] as String,
          name: profile['name'] as String,
          role: profile['role'] as String? ?? 'Ranger',
          rangerId: profile['ranger_id'] as String? ?? '',
          team: profile['team'] as String? ?? '',
          joinDate: profile['join_date'] as String? ?? '',
          currentLocation: profile['park'] as String? ?? 'Sector A',
          avatar: profile['avatar'] as String? ?? 'R',
          park: profile['park'] as String?,
          isActive: profile['is_active'] as bool? ?? true,
        ),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<DashboardStats>> getDashboardStats({String? parkId}) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: MockData.dashboardStats);
    }

    try {
      final counts = await Future.wait([
        _count('incidents', filters: {
          'status': 'Reported',
          'park_id': ?parkId,
        }),
        _count('locations', filters: {
          'park_id': ?parkId,
        }),
        _count('reports'),
        _count('locations', filters: {
          'category': 'Wildlife',
          'park_id': ?parkId,
        }),
        _count('locations', filters: {
          'category': 'Hotel',
          'park_id': ?parkId,
        }),
        _count('profiles', filters: {
          'role': 'Ranger',
          'is_active': true,
        }),
      ]);

      return ApiResponse(
        success: true,
        data: DashboardStats(
          activeIncidents: counts[0],
          touristLocations: counts[1],
          reportsToday: counts[2],
          wildlifeTracked: counts[3],
          hotelsLodges: counts[4],
          rangersActive: counts[5] > 0 ? counts[5] : 1,
        ),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<int> _count(
    String table, {
    Map<String, dynamic> filters = const {},
  }) async {
    var query = _client!.from(table).select('id');
    filters.forEach((key, value) {
      query = query.eq(key, value);
    });
    final result = await query.count(CountOption.exact);
    return result.count;
  }

  Future<ApiResponse<List<EmergencyAlert>>> getEmergencyAlerts({String? parkId}) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: MockData.emergencyAlerts);
    }

    try {
      var query = _client!
          .from('incidents')
          .select()
          .inFilter('severity', ['Critical', 'High'])
          .eq('status', 'Reported');

      if (parkId != null) {
        query = query.eq('park_id', parkId);
      }

      final incidents = await query
          .order('created_at', ascending: false)
          .limit(5);
      final alerts = (incidents as List).map((incident) {
        return EmergencyAlert(
          id: incident['id'],
          type: incident['title'] as String? ??
              incident['category'] as String? ??
              'Alert',
          description: incident['description'] as String? ?? '',
          location: incident['location'] as String? ?? '',
          timeAgo: MockData.getTimeAgo(incident['created_at'] as String?),
          severity: incident['severity'] as String? ?? 'High',
          status: incident['status'] as String? ?? 'Active',
          urgent: incident['severity'] == 'Critical',
          createdAt: DateTime.tryParse(incident['created_at'] as String? ?? ''),
        );
      }).toList();

      return ApiResponse(success: true, data: alerts);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<List<IncidentSummary>>> getRecentIncidents({String? parkId}) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: MockData.recentIncidents);
    }

    try {
      var query = _client!.from('incidents').select();

      if (parkId != null) {
        query = query.eq('park_id', parkId);
      }

      final incidents = await query
          .order('created_at', ascending: false)
          .limit(5);
      final data = (incidents as List).map((incident) {
        return IncidentSummary(
          id: incident['id'],
          type: incident['title'] as String? ??
              incident['category'] as String? ??
              'Incident',
          description: incident['description'] as String? ?? '',
          location: incident['location'] as String? ?? '',
          timeAgo: MockData.getTimeAgo(incident['created_at'] as String?),
          severity: incident['severity'] as String? ?? 'Medium',
          status: incident['status'] as String? ?? 'Reported',
          createdAt: DateTime.tryParse(incident['created_at'] as String? ?? ''),
        );
      }).toList();

      return ApiResponse(success: true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<List<LocationItem>>> getRecentLocations({String? parkId}) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: MockData.recentLocations);
    }

    try {
      var query = _client!.from('locations').select();

      if (parkId != null) {
        query = query.eq('park_id', parkId);
      }

      final locations = await query
          .order('created_at', ascending: false)
          .limit(5);
      final data = (locations as List).map((location) {
        final category = location['category'] as String? ?? 'Wildlife';
        return LocationItem(
          id: location['id'],
          title: location['title'] as String? ??
              location['name'] as String? ??
              'Location',
          category: category,
          description: location['description'] as String? ?? '',
          coordinates: location['coordinates'] as String? ?? '',
          reportedBy: 'Ranger',
          timeAgo: MockData.getTimeAgo(location['created_at'] as String?),
          icon: MockData.iconForCategory(category),
          iconColor: MockData.colorForCategory(category),
          createdAt: DateTime.tryParse(location['created_at'] as String? ?? ''),
        );
      }).toList();

      return ApiResponse(success: true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<List<LocationItem>>> getAllLocations({String? parkId}) async {
    if (useMockData) {
      return const ApiResponse(success: true, data: []);
    }

    try {
      var query = _client!.from('locations').select();

      if (parkId != null) {
        query = query.eq('park_id', parkId);
      }

      final locations = await query.order('created_at', ascending: false);
      final data = (locations as List).map((location) {
        final category = location['category'] as String? ?? 'Wildlife';
        return LocationItem(
          id: location['id'],
          title: location['title'] as String? ??
              location['name'] as String? ??
              'Location',
          category: category,
          description: location['description'] as String? ?? '',
          coordinates: location['coordinates'] as String? ?? '',
          reportedBy: 'Ranger',
          timeAgo: MockData.getTimeAgo(location['created_at'] as String?),
          icon: MockData.iconForCategory(category),
          iconColor: MockData.colorForCategory(category),
        );
      }).toList();

      return ApiResponse(success: true, data: data);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<Map<String, List<LocationItem>>>> getRecentLocationsByCategory({
    String? parkId,
  }) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(
        success: true,
        data: {'Wildlife': MockData.recentLocations},
      );
    }

    try {
      var query = _client!.from('locations').select();

      if (parkId != null) {
        query = query.eq('park_id', parkId);
      }

      final locations = await query.order('created_at', ascending: false);

      final Map<String, List<LocationItem>> grouped = {};
      for (final location in (locations as List)) {
        final category = location['category'] as String? ?? 'Wildlife';
        final item = LocationItem(
          id: location['id'],
          title: location['title'] as String? ??
              location['name'] as String? ??
              'Location',
          category: category,
          description: location['description'] as String? ?? '',
          coordinates: location['coordinates'] as String? ?? '',
          reportedBy: 'Ranger',
          timeAgo: MockData.getTimeAgo(location['created_at'] as String?),
          icon: MockData.iconForCategory(category),
          iconColor: MockData.colorForCategory(category),
        );

        grouped.putIfAbsent(category, () => []);
        if (grouped[category]!.length < 5) {
          grouped[category]!.add(item);
        }
      }

      return ApiResponse(success: true, data: grouped);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<ImpactStats>> getImpactStats() async {
    await MockData.delay();
    return const ApiResponse(success: true, data: MockData.impactStats);
  }

  Future<ApiResponse<List<Achievement>>> getAchievements() async {
    await MockData.delay();
    return const ApiResponse(success: true, data: MockData.achievements);
  }

  Future<ApiResponse<List<IncidentModel>>> getIncidents({String? parkId}) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: []);
    }

    try {
      var query = _client!.from('incidents').select();
      if (parkId != null) query = query.eq('park_id', parkId);
      final data = await query.order('created_at', ascending: false);

      final incidents = (data as List)
          .map((e) => IncidentModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return ApiResponse(success: true, data: incidents);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<IncidentModel>> addIncident(
    IncidentModel incident, {
    String? parkId,
    List<String> photoPaths = const [],
  }) async {
    if (useMockData) {
      await MockData.delay();
      return ApiResponse(
        success: true,
        data: IncidentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: incident.title,
          category: incident.category,
          severity: incident.severity,
          status: incident.status,
          description: incident.description,
          coordinates: incident.coordinates,
        ),
      );
    }

    try {
      final user = _client!.auth.currentUser;
      if (user == null) {
        return const ApiResponse(success: false, error: 'User not authenticated');
      }

      for (final _ in photoPaths) {
        // Photos uploaded separately if needed
      }

      final insertData = incident.toInsertJson(
        reportedBy: user.id,
        parkId: parkId,
      );

      final result = await _client
          .from('incidents')
          .insert(insertData)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      return ApiResponse(
        success: true,
        data: IncidentModel.fromJson(Map<String, dynamic>.from(result)),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<LocationItem>> addLocation(
    NewLocationInput location, {
    String? parkId,
  }) async {
    if (useMockData) {
      await MockData.delay();
      final dbCategory = _mapCategory(location.category);
      String titleText = '';
      if (location.category == 'Attractions' &&
          location.attractionName != null &&
          location.attractionName!.trim().isNotEmpty) {
        titleText = location.attractionName!.trim();
      } else if (location.category == 'Hotels' &&
          location.hotelName != null &&
          location.hotelName!.trim().isNotEmpty) {
        titleText = location.hotelName!.trim();
      }

      if (titleText.isEmpty) {
        titleText = location.subcategory.trim();
      }

      if (titleText.isEmpty) {
        titleText = dbCategory;
      }

      return ApiResponse(
        success: true,
        data: LocationItem(
          id: DateTime.now().millisecondsSinceEpoch,
          title: titleText,
          category: dbCategory,
          description: location.description,
          coordinates: location.coordinates,
          reportedBy: 'Current User',
          icon: MockData.iconForCategory(location.category),
          iconColor: MockData.colorForCategory(location.category),
          timeAgo: 'Just now',
        ),
      );
    }

    try {
      final user = _client!.auth.currentUser;
      if (user == null) {
        return const ApiResponse(success: false, error: 'User not authenticated');
      }

      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = profile['role'] as String? ?? '';
      if (!['Ranger', 'Admin', 'Park_Manager'].contains(role)) {
        return ApiResponse(
          success: false,
          error: "User role '$role' does not have permission to add locations",
        );
      }

      var targetParkId = parkId;
      if (targetParkId == null) {
        final parks = await _client.from('parks').select('id').limit(1);
        if ((parks as List).isEmpty) {
          return const ApiResponse(success: false, error: 'No parks available');
        }
        targetParkId = parks.first['id'] as String;
      }

      final dbCategory = _mapCategory(location.category);
      String titleText = '';
      if (location.category == 'Attractions' &&
          location.attractionName != null &&
          location.attractionName!.trim().isNotEmpty) {
        titleText = location.attractionName!.trim();
      } else if (location.category == 'Hotels' &&
          location.hotelName != null &&
          location.hotelName!.trim().isNotEmpty) {
        titleText = location.hotelName!.trim();
      }

      if (titleText.isEmpty) {
        titleText = location.subcategory.trim();
      }

      if (titleText.isEmpty) {
        titleText = dbCategory;
      }

      final result = await _client.from('locations').insert({
        'title': titleText,
        'category': dbCategory,
        'subcategory': location.subcategory,
        'description': location.description,
        'coordinates': location.coordinates,
        'count': location.count != null ? int.tryParse(location.count!) : null,
        'operating_hours': location.operatingHours,
        'contact': location.contact,
        'best_time_to_visit': location.bestTimeToVisit,
        'reported_by': user.id,
        'park_id': targetParkId,
      }).select().single().timeout(const Duration(seconds: 15));

      final locationId = result['id'] as String;

      final photoErrors = <String>[];
      for (var i = 0; i < location.photos.length; i++) {
        final photoPath = location.photos[i];
        final url = await _uploadPhoto(
          'location-photos',
          photoPath,
          objectPath: '$locationId/${_uuid.v4()}.jpg',
        );
        if (url == null) {
          photoErrors.add('Photo ${i + 1} failed to upload');
          continue;
        }

        try {
          await _client.from('location_photos').insert({
            'location_id': locationId,
            'photo_url': url,
            'taken_by': user.id,
            'photo_name': photoPath.split(Platform.pathSeparator).last,
          }).timeout(const Duration(seconds: 15));
        } catch (e) {
          photoErrors.add('Photo ${i + 1} failed to save: $e');
        }
      }

      return ApiResponse(
        success: true,
        data: LocationItem(
          id: locationId,
          title: titleText,
          category: dbCategory,
          description: location.description,
          coordinates: location.coordinates,
          reportedBy: 'Ranger',
          icon: MockData.iconForCategory(dbCategory),
          iconColor: MockData.colorForCategory(dbCategory),
          timeAgo: 'Just now',
        ),
        message: photoErrors.isEmpty
            ? null
            : 'Location saved, but some photos could not be attached.',
        error: photoErrors.isEmpty ? null : photoErrors.join('\n'),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<String?> _uploadPhoto(
    String bucket,
    String filePath, {
    String? objectPath,
  }) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final fileName = objectPath ?? '${_uuid.v4()}.jpg';
      await _client!.storage.from(bucket).uploadBinary(
            fileName,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          ).timeout(const Duration(seconds: 15));
      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  String _mapCategory(String category) {
    switch (category) {
      case 'Attractions':
        return 'Attraction';
      case 'Hotels':
        return 'Hotel';
      case 'Viewpoints':
        return 'Viewpoint';
      default:
        return category;
    }
  }

  Future<ApiResponse<IncidentModel>> updateIncident(IncidentModel incident) async {
    if (useMockData) {
      await MockData.delay();
      return ApiResponse(success: true, data: incident);
    }

    try {
      final user = _client!.auth.currentUser;
      if (user == null) {
        return const ApiResponse(success: false, error: 'User not authenticated');
      }

      final updateData = {
        'title': incident.title,
        'category': incident.category,
        'severity': incident.severity,
        'status': incident.status,
        'description': incident.description,
        'coordinates': incident.coordinates,
        'tourists_affected': incident.touristsAffected ?? 0,
        'operator': incident.tourOperator,
        'transport': incident.transport,
        'medical_condition': incident.medicalCondition,
        'location': incident.location,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _client
          .from('incidents')
          .update(updateData)
          .eq('id', incident.id)
          .select()
          .single()
          .timeout(const Duration(seconds: 15));

      return ApiResponse(
        success: true,
        data: IncidentModel.fromJson(Map<String, dynamic>.from(result)),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<List<IncidentNoteModel>>> getIncidentNotes(String incidentId) async {
    if (useMockData) {
      await MockData.delay();
      return const ApiResponse(success: true, data: []);
    }

    try {
      final data = await _client!
          .from('incident_notes')
          .select('*, profiles(name)')
          .eq('incident_id', incidentId)
          .order('created_at', ascending: true);

      final notes = (data as List).map((e) {
        final profile = e['profiles'] as Map?;
        final createdByName = profile != null ? profile['name'] as String? : null;
        final json = Map<String, dynamic>.from(e);
        if (createdByName != null) {
          json['created_by_name'] = createdByName;
        }
        return IncidentNoteModel.fromJson(json);
      }).toList();

      return ApiResponse(success: true, data: notes);
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<ApiResponse<IncidentNoteModel>> addIncidentNote(String incidentId, String noteText) async {
    if (useMockData) {
      await MockData.delay();
      return ApiResponse(
        success: true,
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
      final user = _client!.auth.currentUser;
      if (user == null) {
        return const ApiResponse(success: false, error: 'User not authenticated');
      }

      final result = await _client
          .from('incident_notes')
          .insert({
            'incident_id': incidentId,
            'note': noteText,
            'created_by': user.id,
          })
          .select('*, profiles(name)')
          .single()
          .timeout(const Duration(seconds: 15));

      final profile = result['profiles'] as Map?;
      final createdByName = profile != null ? profile['name'] as String? : null;
      final json = Map<String, dynamic>.from(result);
      if (createdByName != null) {
        json['created_by_name'] = createdByName;
      }

      return ApiResponse(
        success: true,
        data: IncidentNoteModel.fromJson(json),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }
}
