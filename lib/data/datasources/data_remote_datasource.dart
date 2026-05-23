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
          if (parkId != null) 'park_id': parkId,
        }),
        _count('locations', filters: {
          if (parkId != null) 'park_id': parkId,
        }),
        _count('reports'),
        _count('locations', filters: {
          'category': 'Wildlife',
          if (parkId != null) 'park_id': parkId,
        }),
        _count('locations', filters: {
          'category': 'Hotel',
          if (parkId != null) 'park_id': parkId,
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
        );
      }).toList();

      return ApiResponse(success: true, data: data);
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

      final result = await _client!
          .from('incidents')
          .insert(insertData)
          .select()
          .single();

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
      return ApiResponse(
        success: true,
        data: LocationItem(
          id: DateTime.now().millisecondsSinceEpoch,
          title: location.attractionName ??
              location.hotelName ??
              location.subcategory,
          category: _mapCategory(location.category),
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

      final profile = await _client!
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
        final parks = await _client!.from('parks').select('id').limit(1);
        if ((parks as List).isEmpty) {
          return const ApiResponse(success: false, error: 'No parks available');
        }
        targetParkId = parks.first['id'] as String;
      }

      final dbCategory = _mapCategory(location.category);
      final title = location.attractionName ??
          location.hotelName ??
          location.subcategory;

      final result = await _client!.from('locations').insert({
        'title': title,
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
      }).select().single();

      for (final photoPath in location.photos) {
        final url = await _uploadPhoto('location-photos', photoPath);
        if (url != null) {
          await _client!.from('location_photos').insert({
            'location_id': result['id'],
            'photo_url': url,
            'photo_name': photoPath.split(Platform.pathSeparator).last,
          });
        }
      }

      return ApiResponse(
        success: true,
        data: LocationItem(
          id: result['id'],
          title: title,
          category: dbCategory,
          description: location.description,
          coordinates: location.coordinates,
          reportedBy: 'Ranger',
          icon: MockData.iconForCategory(dbCategory),
          iconColor: MockData.colorForCategory(dbCategory),
          timeAgo: 'Just now',
        ),
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  Future<String?> _uploadPhoto(String bucket, String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final fileName = '${_uuid.v4()}.jpg';
      await _client!.storage.from(bucket).uploadBinary(
            fileName,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return _client!.storage.from(bucket).getPublicUrl(fileName);
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
}
