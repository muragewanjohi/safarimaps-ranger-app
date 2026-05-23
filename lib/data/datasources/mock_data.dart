import '../models/dashboard_models.dart';

class MockData {
  static const ranger = RangerProfile(
    id: 'ranger_001',
    name: 'Sarah Johnson',
    role: 'Senior Wildlife Ranger',
    rangerId: 'RGR-001',
    team: 'Alpha Team',
    joinDate: '2019-03-15',
    currentLocation: 'Sector A-12',
    avatar: 'SJ',
  );

  static const dashboardStats = DashboardStats(
    activeIncidents: 7,
    wildlifeTracked: 234,
    touristLocations: 42,
    rangersActive: 12,
    hotelsLodges: 8,
    reportsToday: 18,
  );

  static const emergencyAlerts = [
    EmergencyAlert(
      id: 1,
      type: 'Tour Van Stuck',
      severity: 'High',
      description: '8 Tourists',
      location: 'Swamp Trail Junction',
      timeAgo: '15 min ago',
      status: 'Active',
    ),
    EmergencyAlert(
      id: 2,
      type: 'Missing Family',
      severity: 'Critical',
      description: 'Lost on Trail',
      location: 'Elephant Valley Trail',
      timeAgo: '25 min ago',
      status: 'Active',
      urgent: true,
    ),
  ];

  static const recentIncidents = [
    IncidentSummary(
      id: 1,
      type: 'Tour Van Stuck',
      description: '8 Tourists',
      location: 'Swamp Trail Junction',
      timeAgo: '15 min ago',
      severity: 'High',
      status: 'Active',
    ),
    IncidentSummary(
      id: 2,
      type: 'Missing Family',
      description: 'Lost on Trail',
      location: 'Elephant Valley Trail',
      timeAgo: '25 min ago',
      severity: 'Critical',
      status: 'Active',
    ),
  ];

  static const recentLocations = [
    LocationItem(
      id: 1,
      title: 'African Elephant Herd',
      category: 'Wildlife',
      description: 'Large herd of 12 elephants near watering hole',
      coordinates: '-2.1534, 34.6857',
      reportedBy: 'Sarah Johnson',
      icon: 'pets',
      iconColor: '#4CAF50',
      type: 'African Elephant',
      count: '12',
      location: 'Grid C-8',
      timeAgo: '1 hour ago',
    ),
    LocationItem(
      id: 2,
      title: 'Black Rhino Mother & Calf',
      category: 'Wildlife',
      description: 'Mother rhino with healthy calf',
      coordinates: '-2.1234, 34.7123',
      reportedBy: 'Sarah Johnson',
      icon: 'pets',
      iconColor: '#4CAF50',
      isEndangered: true,
      timeAgo: '2 hours ago',
    ),
  ];

  static const impactStats = ImpactStats(
    incidentsReported: 47,
    wildlifeTracked: 234,
    patrolsCompleted: 156,
    daysActive: 1825,
  );

  static const achievements = [
    Achievement(
      id: 1,
      title: 'Wildlife Guardian',
      description: 'Tracked 100+ wildlife sightings',
      icon: 'shield',
      iconColor: '#4CAF50',
      badgeIcon: 'star',
      badgeColor: '#FFD700',
    ),
    Achievement(
      id: 2,
      title: 'Emergency Responder',
      description: 'Responded to 10+ critical incidents',
      icon: 'emergency',
      iconColor: '#F44336',
      badgeIcon: 'verified',
      badgeColor: '#2196F3',
    ),
  ];

  static Future<void> delay() =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  static String getTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Recently';
    }
  }

  static String iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'wildlife':
        return 'pets';
      case 'attraction':
      case 'attractions':
        return 'attractions';
      case 'hotel':
      case 'hotels':
        return 'hotel';
      case 'dining':
        return 'restaurant';
      case 'viewpoint':
      case 'viewpoints':
        return 'landscape';
      default:
        return 'place';
    }
  }

  static String colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'wildlife':
        return '#4CAF50';
      case 'attraction':
      case 'attractions':
        return '#FF9800';
      case 'hotel':
      case 'hotels':
        return '#9C27B0';
      case 'dining':
        return '#795548';
      case 'viewpoint':
      case 'viewpoints':
        return '#2196F3';
      default:
        return '#666666';
    }
  }
}
