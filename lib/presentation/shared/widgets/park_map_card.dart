import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

bool get _showMapsUnavailablePlaceholder {
  if (kIsWeb || Platform.isAndroid) return false;
  return Platform.isIOS && AppConstants.googleMapsIosKey.isEmpty;
}

class ParkMapCard extends StatefulWidget {
  const ParkMapCard({super.key, this.parkId});

  final String? parkId;

  @override
  State<ParkMapCard> createState() => _ParkMapCardState();
}

class _ParkMapCardState extends State<ParkMapCard> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _center = const LatLng(-1.2921, 35.5739);
  bool _showMap = false;

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
    if (oldWidget.parkId != widget.parkId) _loadParkData();
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

      final markers = <Marker>{};
      final pois = parkData['pois'] as List<dynamic>? ?? [];
      for (var i = 0; i < pois.length; i++) {
        final poi = pois[i] as Map<String, dynamic>;
        markers.add(Marker(
          markerId: MarkerId('poi_$i'),
          position: LatLng(
            (poi['lat'] as num).toDouble(),
            (poi['lng'] as num).toDouble(),
          ),
          infoWindow: InfoWindow(title: poi['title'] as String? ?? 'POI'),
        ));
      }

      final routes = parkData['routes'] as List<dynamic>? ?? [];
      final polylines = <Polyline>{};
      for (var i = 0; i < routes.length; i++) {
        final route = routes[i] as List<dynamic>;
        polylines.add(Polyline(
          polylineId: PolylineId('route_$i'),
          color: AppTheme.primaryColor,
          width: 3,
          points: route
              .map((p) => LatLng(
                    (p['lat'] as num).toDouble(),
                    (p['lng'] as num).toDouble(),
                  ))
              .toList(),
        ));
      }

      setState(() {
        _markers = markers;
        _polylines = polylines;
      });
    } catch (_) {
      // Use defaults
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
            ? GoogleMap(
                initialCameraPosition: CameraPosition(target: _center, zoom: 11),
                markers: _markers,
                polylines: _polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.hybrid,
                onMapCreated: (controller) {
                  controller.animateCamera(CameraUpdate.newLatLng(_center));
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
  LatLng _selectedPoint = const LatLng(-1.2921, 35.5739);

  @override
  Widget build(BuildContext context) {
    if (_showMapsUnavailablePlaceholder) {
      return _MapsUnavailableCard(height: widget.height);
    }

    final center = widget.initialRegion ?? _selectedPoint;
    final markers = <Marker>{
      ...widget.markers.map(
        (m) => Marker(
          markerId: MarkerId(m.id),
          position: m.position,
          infoWindow: InfoWindow(title: m.title, snippet: m.description),
        ),
      ),
      if (widget.mode == MapViewMode.select)
        Marker(
          markerId: const MarkerId('selected'),
          position: _selectedPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    final polylines = widget.trailCoordinates.isEmpty
        ? <Polyline>{}
        : {
            Polyline(
              polylineId: const PolylineId('trail'),
              points: widget.trailCoordinates,
              color: AppTheme.primaryColor,
              width: 4,
            ),
          };

    return SizedBox(
      height: widget.height,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 12),
        markers: markers,
        polylines: polylines,
        myLocationEnabled: widget.showUserLocation,
        mapType: MapType.hybrid,
        onTap: widget.mode == MapViewMode.select
            ? (point) {
                setState(() => _selectedPoint = point);
                widget.onLocationSelected?.call(point);
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
                  'Map unavailable',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add GOOGLE_MAPS_IOS_API_KEY to ios/Flutter/Secrets.xcconfig, '
                  'then run a full rebuild.',
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
