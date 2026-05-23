import '../datasources/data_remote_datasource.dart';
import '../models/dashboard_models.dart';

class DataRepository {
  DataRepository(this._dataSource);

  final DataRemoteDataSource _dataSource;

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
  }) =>
      _dataSource.addIncident(incident, parkId: parkId, photoPaths: photoPaths);

  Future<ApiResponse<LocationItem>> addLocation(
    NewLocationInput location, {
    String? parkId,
  }) =>
      _dataSource.addLocation(location, parkId: parkId);
}
