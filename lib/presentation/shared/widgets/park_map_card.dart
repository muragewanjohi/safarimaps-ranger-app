import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/injection.dart';
import '../../park/bloc/park_cubit.dart';

// Custom lightweight LatLng model to replace google_maps_flutter dependency
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => '$latitude, $longitude';
}

bool get _showMapsUnavailablePlaceholder {
  return AppConstants.mapboxPublicToken.isEmpty;
}

// Predefined high-fidelity boundary polygons for the national parks
List<LatLng> _getParkBoundary(String? parkId) {
  // Nairobi National Park
  if (parkId == '0dba0933-f39f-4c78-a943-45584f383d20') {
    return const [
      LatLng(-1.355, 36.820),
      LatLng(-1.350, 36.870),
      LatLng(-1.380, 36.930),
      LatLng(-1.430, 36.900),
      LatLng(-1.440, 36.840),
      LatLng(-1.390, 36.800),
      LatLng(-1.355, 36.820), // Closed loop
    ];
  }
  // Masai Mara National Reserve
  if (parkId == '3467cff0-ca7d-4c6c-ad28-2d202f2372ce' || parkId == 'default' || parkId == null) {
    return const [
      LatLng(-1.400, 34.800),
      LatLng(-1.350, 35.100),
      LatLng(-1.450, 35.300),
      LatLng(-1.600, 35.150),
      LatLng(-1.550, 34.900),
      LatLng(-1.400, 34.800), // Closed loop
    ];
  }
  return const [];
}

class ParkMapCard extends StatefulWidget {
  const ParkMapCard({super.key, this.parkId});

  final String? parkId;

  @override
  State<ParkMapCard> createState() => _ParkMapCardState();
}

class _ParkMapCardState extends State<ParkMapCard> {
  LatLng _center = const LatLng(-1.2921, 35.5739);
  List<Map<String, dynamic>> _pois = [];
  List<List<LatLng>> _routes = [];
  bool _showMap = false;

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  @override
  void initState() {
    super.initState();
    _loadParkData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showMap = true);
    });
  }

  @override
  void didUpdateWidget(ParkMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parkId != widget.parkId) {
      _loadParkData();
    }
  }

  Future<void> _loadParkData() async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/park_pois.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final parkData = data[widget.parkId ?? 'default'] as Map<String, dynamic>? ??
          data['default'] as Map<String, dynamic>;

      final center = parkData['center'] as Map<String, dynamic>;
      _center = LatLng(
        (center['lat'] as num).toDouble(),
        (center['lng'] as num).toDouble(),
      );

      final pois = parkData['pois'] as List<dynamic>? ?? [];
      _pois = pois.map((p) => Map<String, dynamic>.from(p)).toList();

      final routes = parkData['routes'] as List<dynamic>? ?? [];
      _routes = routes.map((r) {
        final list = r as List<dynamic>;
        return list.map((p) {
          final pt = p as Map<String, dynamic>;
          return LatLng(
            (pt['lat'] as num).toDouble(),
            (pt['lng'] as num).toDouble(),
          );
        }).toList();
      }).toList();

      if (mounted && _mapboxMap != null) {
        _updateAnnotations();
      }
    } catch (_) {
      // Use defaults
    }
  }

  Future<void> _updateAnnotations() async {
    if (_mapboxMap == null) return;

    // Center camera on park
    await _mapboxMap!.setCamera(CameraOptions(
      center: Point(coordinates: Position(_center.longitude, _center.latitude)),
      zoom: 11.0,
    ));

    // Load POI markers with custom vector pin icons
    if (_pointAnnotationManager != null) {
      await _pointAnnotationManager!.deleteAll();
      final points = _pois.map((poi) {
        return PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              (poi['lng'] as num).toDouble(),
              (poi['lat'] as num).toDouble(),
            ),
          ),
          textField: poi['title'] as String?,
          textOffset: [0.0, 1.5],
          textSize: 11.0,
          textColor: Colors.black.value,
          iconImage: "marker-15", // Standard vector map pin
          iconSize: 1.5,
        );
      }).toList();
      if (points.isNotEmpty) {
        await _pointAnnotationManager!.createMulti(points);
      }
    }

    // Load park boundary and static routes
    if (_polylineAnnotationManager != null) {
      await _polylineAnnotationManager!.deleteAll();
      final lines = <PolylineAnnotationOptions>[];

      // 1. Add park boundary outline
      final boundary = _getParkBoundary(widget.parkId);
      if (boundary.isNotEmpty) {
        lines.add(PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: boundary
                .map((p) => Position(p.longitude, p.latitude))
                .toList(),
          ),
          lineColor: AppTheme.successColor.value, // Emerald green boundary outline
          lineWidth: 4.5,
        ));
      }

      // 2. Add specific routes inside the park
      for (final route in _routes) {
        lines.add(PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: route
                .map((p) => Position(p.longitude, p.latitude))
                .toList(),
          ),
          lineColor: AppTheme.primaryColor.value,
          lineWidth: 3.0,
        ));
      }

      if (lines.isNotEmpty) {
        await _polylineAnnotationManager!.createMulti(lines);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showMapsUnavailablePlaceholder) {
      return const _MapsUnavailableCard(height: 220);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.authBorder),
      ),
      child: SizedBox(
        height: 220,
        child: _showMap
            ? MapWidget(
                key: const ValueKey("park_map_card_mapbox"),
                styleUri: MapboxStyles.OUTDOORS, // Topological clean outdoors view
                onMapCreated: (mapboxMap) async {
                  _mapboxMap = mapboxMap;
                  _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
                  _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
                  _updateAnnotations();
                },
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.authGradientMid,
                ),
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 40,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
      ),
    );
  }
}

class SafariMapView extends StatefulWidget {
  const SafariMapView({
    super.key,
    this.markers = const [],
    this.trailCoordinates = const [],
    this.mode = MapViewMode.view,
    this.onLocationSelected,
    this.initialRegion,
    this.showUserLocation = true,
    this.height = 300,
  });

  final List<MapMarkerData> markers;
  final List<LatLng> trailCoordinates;
  final MapViewMode mode;
  final void Function(LatLng)? onLocationSelected;
  final LatLng? initialRegion;
  final bool showUserLocation;
  final double height;

  @override
  State<SafariMapView> createState() => _SafariMapViewState();
}

class _SafariMapViewState extends State<SafariMapView> {
  LatLng? _selectedPoint;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialRegion ?? const LatLng(-1.2921, 35.5739);
  }

  @override
  void didUpdateWidget(SafariMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRegion != oldWidget.initialRegion && widget.initialRegion != null) {
      _selectedPoint = widget.initialRegion;
      _updateAnnotations();
    } else if (widget.markers != oldWidget.markers || widget.trailCoordinates != oldWidget.trailCoordinates) {
      _updateAnnotations();
    }
  }

  Future<void> _updateAnnotations() async {
    if (_mapboxMap == null) return;

    final center = widget.initialRegion ?? _selectedPoint ?? const LatLng(-1.2921, 35.5739);
    await _mapboxMap!.setCamera(CameraOptions(
      center: Point(coordinates: Position(center.longitude, center.latitude)),
      zoom: 12.0,
    ));

    if (_pointAnnotationManager != null) {
      await _pointAnnotationManager!.deleteAll();
      final annotations = <PointAnnotationOptions>[];

      for (final m in widget.markers) {
        annotations.add(PointAnnotationOptions(
          geometry: Point(coordinates: Position(m.position.longitude, m.position.latitude)),
          textField: m.title,
          textOffset: [0.0, 1.5],
          textSize: 11.0,
          iconImage: "marker-15",
          iconSize: 1.5,
        ));
      }

      if (widget.mode == MapViewMode.select && _selectedPoint != null) {
        annotations.add(PointAnnotationOptions(
          geometry: Point(coordinates: Position(_selectedPoint!.longitude, _selectedPoint!.latitude)),
          textField: 'Selected Position',
          textOffset: [0.0, 1.5],
          textSize: 11.0,
          iconImage: "marker-15",
          iconSize: 1.5,
        ));
      }

      if (annotations.isNotEmpty) {
        await _pointAnnotationManager!.createMulti(annotations);
      }
    }

    if (_polylineAnnotationManager != null) {
      await _polylineAnnotationManager!.deleteAll();
      final lines = <PolylineAnnotationOptions>[];

      // 1. Add park boundary outline
      final parkId = getIt<ParkCubit>().state.selectedPark?.id;
      final boundary = _getParkBoundary(parkId);
      if (boundary.isNotEmpty) {
        lines.add(PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: boundary
                .map((p) => Position(p.longitude, p.latitude))
                .toList(),
          ),
          lineColor: AppTheme.successColor.value,
          lineWidth: 4.5,
        ));
      }

      // 2. Add trail route coordinates if active
      if (widget.trailCoordinates.isNotEmpty) {
        lines.add(PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: widget.trailCoordinates
                .map((p) => Position(p.longitude, p.latitude))
                .toList(),
          ),
          lineColor: AppTheme.primaryColor.value,
          lineWidth: 4.0,
        ));
      }

      if (lines.isNotEmpty) {
        await _polylineAnnotationManager!.createMulti(lines);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showMapsUnavailablePlaceholder) {
      return _MapsUnavailableCard(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      child: MapWidget(
        key: const ValueKey("safari_map_view_mapbox"),
        styleUri: MapboxStyles.OUTDOORS, // Topological clean outdoors view
        onMapCreated: (mapboxMap) async {
          _mapboxMap = mapboxMap;
          _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
          _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
          _updateAnnotations();
        },
        onTapListener: widget.mode == MapViewMode.select
            ? (gestureContext) {
                final coord = gestureContext.point.coordinates;
                final latLng = LatLng(coord.lat.toDouble(), coord.lng.toDouble());
                setState(() {
                  _selectedPoint = latLng;
                });
                widget.onLocationSelected?.call(latLng);
                _updateAnnotations();
              }
            : null,
      ),
    );
  }
}

class _MapsUnavailableCard extends StatelessWidget {
  const _MapsUnavailableCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.authBorder),
      ),
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.authGradientTop,
                AppTheme.authGradientMid,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 36,
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mapbox configuration missing',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add MAPBOX_PUBLIC_TOKEN to env.json, then run a full rebuild.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.authMutedText,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum MapViewMode { view, select, track }

class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.position,
    this.title,
    this.description,
    this.type,
  });

  final String id;
  final LatLng position;
  final String? title;
  final String? description;
  final String? type;
}
