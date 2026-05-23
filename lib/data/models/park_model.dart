class ParkModel {
  const ParkModel({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.established,
    this.area,
    this.size,
    this.coordinates,
    this.operatingHours,
    this.contactInfo,
    this.admissionFees,
    this.rulesAndRegulations,
    this.emergencyContacts,
    this.photos,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? established;
  final String? area;
  final String? size;
  final String? coordinates;
  final String? operatingHours;
  final Map<String, String>? contactInfo;
  final Map<String, String>? admissionFees;
  final List<String>? rulesAndRegulations;
  final Map<String, String>? emergencyContacts;
  final List<String>? photos;
  final String? createdAt;
  final String? updatedAt;

  factory ParkModel.fromJson(Map<String, dynamic> json) {
    return ParkModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      established: json['established'] as String?,
      area: json['area'] as String?,
      size: json['size'] as String?,
      coordinates: json['coordinates'] as String?,
      operatingHours: json['operating_hours'] as String?,
      contactInfo: _mapFromJson(json['contact_info']),
      admissionFees: _mapFromJson(json['admission_fees']),
      rulesAndRegulations: (json['rules_and_regulations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      emergencyContacts: _mapFromJson(json['emergency_contacts']),
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'established': established,
      'area': area,
      'size': size,
      'coordinates': coordinates,
      'operating_hours': operatingHours,
      'contact_info': contactInfo,
      'admission_fees': admissionFees,
      'rules_and_regulations': rulesAndRegulations,
      'emergency_contacts': emergencyContacts,
      'photos': photos,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  ParkModel copyWith({
    String? name,
    String? description,
    String? location,
    String? established,
    String? area,
    String? size,
    String? coordinates,
    String? operatingHours,
    Map<String, String>? contactInfo,
    Map<String, String>? admissionFees,
    List<String>? rulesAndRegulations,
    Map<String, String>? emergencyContacts,
    List<String>? photos,
  }) {
    return ParkModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      established: established ?? this.established,
      area: area ?? this.area,
      size: size ?? this.size,
      coordinates: coordinates ?? this.coordinates,
      operatingHours: operatingHours ?? this.operatingHours,
      contactInfo: contactInfo ?? this.contactInfo,
      admissionFees: admissionFees ?? this.admissionFees,
      rulesAndRegulations: rulesAndRegulations ?? this.rulesAndRegulations,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      photos: photos ?? this.photos,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, String>? _mapFromJson(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  static ParkModel fromFallback(Map<String, dynamic> json) {
    return ParkModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
    );
  }
}

class ParkEntryModel {
  const ParkEntryModel({
    required this.id,
    required this.parkId,
    required this.name,
    required this.entryType,
    required this.status,
    required this.coordinates,
    this.description,
    this.facilities,
    this.isAccessible = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String parkId;
  final String name;
  final String entryType;
  final String status;
  final String coordinates;
  final String? description;
  final List<String>? facilities;
  final bool isAccessible;
  final String? createdAt;
  final String? updatedAt;

  factory ParkEntryModel.fromJson(Map<String, dynamic> json) {
    return ParkEntryModel(
      id: json['id'] as String,
      parkId: json['park_id'] as String,
      name: json['name'] as String,
      entryType: json['entry_type'] as String? ?? 'Entry',
      status: json['status'] as String? ?? 'Primary',
      coordinates: json['coordinates'] as String,
      description: json['description'] as String?,
      facilities: (json['facilities'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      isAccessible: json['is_accessible'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'park_id': parkId,
      'name': name,
      'entry_type': entryType,
      'status': status,
      'coordinates': coordinates,
      'description': description,
      'facilities': facilities,
      'is_accessible': isAccessible,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
