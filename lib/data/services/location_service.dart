import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  LocationService();

  Position? _lastPosition;

  Future<bool> get hasPermission async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> ensurePermission() async {
    if (await hasPermission) return true;
    return requestPermissions();
  }

  Future<LocationCoordinates?> getCurrentLocation() async {
    try {
      final granted = await requestPermissions();
      if (!granted) {
        return const LocationCoordinates(
          latitude: -1.2921,
          longitude: 35.5739,
        );
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationCoordinates(
          latitude: -1.2921,
          longitude: 35.5739,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _lastPosition = position;
      return LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const LocationCoordinates(
        latitude: -1.2921,
        longitude: 35.5739,
      );
    }
  }

  LocationCoordinates? getLastKnownLocation() {
    if (_lastPosition == null) return null;
    return LocationCoordinates(
      latitude: _lastPosition!.latitude,
      longitude: _lastPosition!.longitude,
    );
  }

  String formatCoordinates(LocationCoordinates coordinates) {
    final lat = coordinates.latitude.toFixed(6);
    final lng = coordinates.longitude.toFixed(6);
    return '$lat°N, $lng°E';
  }

  String formatCoordinatesDisplay(double latitude, double longitude) {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}° $latDir, ${longitude.abs().toStringAsFixed(4)}° $lonDir';
  }

  double calculateDistance(
    LocationCoordinates point1,
    LocationCoordinates point2,
  ) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  bool isWithinPark(
    LocationCoordinates location,
    List<LocationCoordinates> parkBoundaries,
  ) {
    var inside = false;
    for (var i = 0, j = parkBoundaries.length - 1;
        i < parkBoundaries.length;
        j = i++) {
      final xi = parkBoundaries[i].longitude;
      final yi = parkBoundaries[i].latitude;
      final xj = parkBoundaries[j].longitude;
      final yj = parkBoundaries[j].latitude;

      final intersect = ((yi > location.latitude) !=
              (yj > location.latitude)) &&
          (location.longitude <
              (xj - xi) * (location.latitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  Future<String?> getAddressFromCoordinates(
    LocationCoordinates coordinates,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return '${p.street ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''} ${p.country ?? ''}'
          .trim();
    } catch (_) {
      return null;
    }
  }

  Future<LocationCoordinates?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      return LocationCoordinates(
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> openExternalNavigation(
    double latitude,
    double longitude,
    String label,
  ) async {
    // Handled by url_launcher in presentation layer
  }
}

class LocationCoordinates {
  const LocationCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

extension on double {
  String toFixed(int fractionDigits) => toStringAsFixed(fractionDigits);
}

Future<List<int>> readFileBytes(String path) async {
  return File(path).readAsBytes();
}
