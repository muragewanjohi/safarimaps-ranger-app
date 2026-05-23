import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/park_model.dart';

class ParkRemoteDataSource {
  ParkRemoteDataSource(this._client);

  final SupabaseClient? _client;

  Future<List<ParkModel>> getParks() async {
    if (_client == null) return _fallbackParks();

    try {
      final data = await _client!.from('parks').select().order('name');
      final parks = (data as List)
          .map((e) => ParkModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return parks.isEmpty ? _fallbackParks() : parks;
    } catch (_) {
      return _fallbackParks();
    }
  }

  Future<ParkModel?> getParkById(String id) async {
    if (_client == null) {
      try {
        return _fallbackParks().firstWhere((p) => p.id == id);
      } catch (_) {
        return _fallbackParks().isNotEmpty ? _fallbackParks().first : null;
      }
    }

    try {
      final data = await _client!
          .from('parks')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return ParkModel.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<ParkModel> updatePark(String id, Map<String, dynamic> updates) async {
    final data = await _client!
        .from('parks')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return ParkModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<ParkEntryModel>> getParkEntries(String parkId) async {
    if (_client == null) return [];

    try {
      final data = await _client!
          .from('park_entries')
          .select()
          .eq('park_id', parkId)
          .order('status', ascending: false)
          .order('name');

      return (data as List)
          .map((e) => ParkEntryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ParkEntryModel> createParkEntry(ParkEntryModel entry) async {
    final data = await _client!
        .from('park_entries')
        .insert(entry.toJson())
        .select()
        .single();
    return ParkEntryModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ParkEntryModel> updateParkEntry(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final data = await _client!
        .from('park_entries')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .select()
        .single();
    return ParkEntryModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteParkEntry(String id) async {
    await _client!.from('park_entries').delete().eq('id', id);
  }

  List<ParkModel> _fallbackParks() {
    return AppConstants.fallbackParks
        .map((p) => ParkModel.fromFallback(p))
        .toList();
  }
}
