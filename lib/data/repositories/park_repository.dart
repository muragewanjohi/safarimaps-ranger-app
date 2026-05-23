import '../datasources/park_remote_datasource.dart';
import '../models/park_model.dart';

class ParkRepository {
  ParkRepository(this._dataSource);

  final ParkRemoteDataSource _dataSource;

  Future<List<ParkModel>> getParks() => _dataSource.getParks();

  Future<ParkModel?> getParkById(String id) => _dataSource.getParkById(id);

  Future<ParkModel> updatePark(String id, ParkModel park) =>
      _dataSource.updatePark(id, park.toJson());

  Future<List<ParkEntryModel>> getParkEntries(String parkId) =>
      _dataSource.getParkEntries(parkId);

  Future<ParkEntryModel> createParkEntry(ParkEntryModel entry) =>
      _dataSource.createParkEntry(entry);

  Future<ParkEntryModel> updateParkEntry(
    String id,
    ParkEntryModel entry,
  ) =>
      _dataSource.updateParkEntry(id, entry.toJson());

  Future<void> deleteParkEntry(String id) => _dataSource.deleteParkEntry(id);
}
