class DashboardStats {
  const DashboardStats({
    this.activeIncidents = 0,
    this.wildlifeTracked = 0,
    this.touristLocations = 0,
    this.rangersActive = 0,
    this.hotelsLodges = 0,
    this.reportsToday = 0,
  });

  final int activeIncidents;
  final int wildlifeTracked;
  final int touristLocations;
  final int rangersActive;
  final int hotelsLodges;
  final int reportsToday;
}

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.status,
    this.urgent = false,
  });

  final dynamic id;
  final String type;
  final String severity;
  final String description;
  final String location;
  final String timeAgo;
  final String status;
  final bool urgent;
}

class IncidentSummary {
  const IncidentSummary({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.timeAgo,
    required this.severity,
    required this.status,
  });

  final dynamic id;
  final String type;
  final String description;
  final String location;
  final String timeAgo;
  final String severity;
  final String status;
}

class LocationItem {
  const LocationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.coordinates,
    required this.reportedBy,
    required this.icon,
    required this.iconColor,
    this.isEndangered = false,
    this.timeAgo,
    this.rating,
    this.operatingHours,
    this.features,
    this.contact,
    this.type,
    this.count,
    this.location,
    this.photos,
  });

  final dynamic id;
  final String title;
  final String category;
  final String description;
  final String coordinates;
  final String reportedBy;
  final String icon;
  final String iconColor;
  final bool isEndangered;
  final String? timeAgo;
  final String? rating;
  final String? operatingHours;
  final List<String>? features;
  final String? contact;
  final String? type;
  final String? count;
  final String? location;
  final List<String>? photos;
}

class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.status,
    required this.description,
    this.coordinates,
    this.touristsAffected,
    this.tourOperator,
    this.contactInfo,
    this.transport,
    this.medicalCondition,
    this.tags = const [],
    this.photos = const [],
    this.createdAt,
    this.reportedBy,
    this.reportedByName,
    this.parkId,
    this.location,
  });

  final String id;
  final String title;
  final String category;
  final String severity;
  final String status;
  final String description;
  final String? coordinates;
  final int? touristsAffected;
  final String? tourOperator;
  final String? contactInfo;
  final String? transport;
  final String? medicalCondition;
  final List<String> tags;
  final List<String> photos;
  final String? createdAt;
  final String? reportedBy;
  final String? reportedByName;
  final String? parkId;
  final String? location;

  factory IncidentModel.fromJson(Map<String, dynamic> json) {
    return IncidentModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['type'] as String? ?? 'Incident',
      category: json['category'] as String? ?? 'General',
      severity: json['severity'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Reported',
      description: json['description'] as String? ?? '',
      coordinates: json['coordinates'] as String?,
      touristsAffected: json['tourists_affected'] as int?,
      tourOperator: json['operator'] as String? ?? json['tour_operator'] as String?,
      contactInfo: json['contact_info'] as String?,
      transport: json['transport'] as String?,
      medicalCondition: json['medical_condition'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] as String?,
      reportedBy: json['reported_by'] as String?,
      reportedByName: json['reported_by_name'] as String?,
      parkId: json['park_id'] as String?,
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson({
    required String reportedBy,
    String? parkId,
  }) {
    return {
      'title': title,
      'category': category,
      'severity': severity,
      'status': status,
      'description': description,
      'coordinates': coordinates,
      'tourists_affected': touristsAffected ?? 0,
      'operator': tourOperator,
      'transport': transport,
      'medical_condition': medicalCondition,
      'location': location,
      'reported_by': reportedBy,
      if (parkId != null) 'park_id': parkId,
    };
  }
}

class NewLocationInput {
  const NewLocationInput({
    required this.category,
    required this.subcategory,
    required this.description,
    required this.coordinates,
    this.count,
    this.attractionName,
    this.operatingHours,
    this.hotelName,
    this.contact,
    this.bestTimeToVisit,
    this.photos = const [],
  });

  final String category;
  final String subcategory;
  final String description;
  final String coordinates;
  final String? count;
  final String? attractionName;
  final String? operatingHours;
  final String? hotelName;
  final String? contact;
  final String? bestTimeToVisit;
  final List<String> photos;
}

class ImpactStats {
  const ImpactStats({
    this.incidentsReported = 0,
    this.wildlifeTracked = 0,
    this.patrolsCompleted = 0,
    this.daysActive = 0,
  });

  final int incidentsReported;
  final int wildlifeTracked;
  final int patrolsCompleted;
  final int daysActive;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.badgeIcon,
    required this.badgeColor,
  });

  final int id;
  final String title;
  final String description;
  final String icon;
  final String iconColor;
  final String badgeIcon;
  final String badgeColor;
}

class RangerProfile {
  const RangerProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.rangerId,
    required this.team,
    required this.joinDate,
    required this.currentLocation,
    required this.avatar,
    this.park,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String role;
  final String rangerId;
  final String team;
  final String joinDate;
  final String currentLocation;
  final String avatar;
  final String? park;
  final bool isActive;
}

class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  final bool success;
  final T? data;
  final String? error;
  final String? message;
}

class MapLocation {
  const MapLocation({
    required this.latitude,
    required this.longitude,
    this.title,
    this.description,
    this.type,
    this.id,
  });

  final double latitude;
  final double longitude;
  final String? title;
  final String? description;
  final String? type;
  final String? id;
}

class MapRegion {
  const MapRegion({
    required this.latitude,
    required this.longitude,
    required this.latitudeDelta,
    required this.longitudeDelta,
  });

  final double latitude;
  final double longitude;
  final double latitudeDelta;
  final double longitudeDelta;
}
