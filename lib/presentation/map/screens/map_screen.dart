import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../park/bloc/park_cubit.dart';
import '../../shared/widgets/park_map_card.dart';
import '../../shared/widgets/ranger_app_bar.dart';
import '../../../data/repositories/data_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _filter = 'All Locations';
  bool _showMap = true;
  List<MapLocationItem> _locations = [];

  static const _filters = [
    'All Locations',
    'Wildlife',
    'Attractions',
    'Hotels',
    'Dining',
    'Viewpoints',
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  LatLng? _parseCoordinates(String coords) {
    try {
      final parts = coords.split(',');
      if (parts.length != 2) return null;

      final latPart = parts[0].trim();
      final lngPart = parts[1].trim();

      final latMatch = RegExp(r'(-?\d+\.?\d*)').firstMatch(latPart);
      final lngMatch = RegExp(r'(-?\d+\.?\d*)').firstMatch(lngPart);

      if (latMatch == null || lngMatch == null) return null;

      var lat = double.parse(latMatch.group(1)!);
      var lng = double.parse(lngMatch.group(1)!);

      if (latPart.toUpperCase().contains('S') && lat > 0) lat = -lat;
      if (lngPart.toUpperCase().contains('W') && lng > 0) lng = -lng;

      return LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLocations() async {
    final parkId = getIt<ParkCubit>().state.selectedPark?.id ?? 'default';
    final List<MapLocationItem> allLoaded = [];

    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/park_pois.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final parkData = data[parkId] as Map<String, dynamic>? ??
          data['default'] as Map<String, dynamic>;
      final pois = parkData['pois'] as List<dynamic>? ?? [];

      allLoaded.addAll(pois.map((p) {
        final poi = p as Map<String, dynamic>;
        return MapLocationItem(
          title: poi['title'] as String? ?? 'Location',
          lat: (poi['lat'] as num).toDouble(),
          lng: (poi['lng'] as num).toDouble(),
          category: poi['category'] as String? ?? 'Wildlife',
        );
      }));
    } catch (_) {}

    try {
      final response = await getIt<DataRepository>().getAllLocations(parkId: parkId);
      if (response.success && response.data != null) {
        for (final item in response.data!) {
          final latLng = _parseCoordinates(item.coordinates);
          if (latLng != null) {
            if (!allLoaded.any((l) => l.title == item.title && l.category == item.category)) {
              allLoaded.add(MapLocationItem(
                title: item.title,
                lat: latLng.latitude,
                lng: latLng.longitude,
                category: item.category,
              ));
            }
          }
        }
      }
    } catch (_) {}

    setState(() {
      _locations = allLoaded;
    });
  }

  List<MapLocationItem> get _filteredLocations {
    if (_filter == 'All Locations') return _locations;
    return _locations
        .where((l) => l.category.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
  }

  Future<void> _openNavigation(MapLocationItem item) async {
    final url = Platform.isIOS
        ? Uri.parse(
            'http://maps.apple.com/?daddr=${item.lat},${item.lng}&dirflg=d')
        : Uri.parse(
            'google.navigation:q=${item.lat},${item.lng}&mode=d');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _filteredLocations
        .map(
          (l) => MapMarkerData(
            id: l.title,
            position: LatLng(l.lat, l.lng),
            title: l.title,
            description: l.category,
          ),
        )
        .toList();

    return Scaffold(
      appBar: RangerAppBar(
        title: 'Explore map',
        subtitle: getIt<ParkCubit>().state.selectedPark?.name,
        actions: [
          RangerIconAction(
            icon: _showMap ? Icons.list_rounded : Icons.map_rounded,
            tooltip: _showMap ? 'List view' : 'Map view',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-location'),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Add Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              initialValue: _filter,
              decoration: const InputDecoration(labelText: 'Filter'),
              items: _filters
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _filter = v ?? _filter),
            ),
          ),
          if (_showMap)
            Expanded(
              flex: 2,
              child: SafariMapView(
                markers: markers,
                height: double.infinity,
              ),
            ),
          Expanded(
            flex: _showMap ? 1 : 3,
            child: ListView.builder(
              itemCount: _filteredLocations.length,
              itemBuilder: (context, index) {
                final item = _filteredLocations[index];
                return ListTile(
                  leading: const Icon(Icons.place, color: AppTheme.primaryColor),
                  title: Text(item.title),
                  subtitle: Text(item.category),
                  trailing: IconButton(
                    icon: const Icon(Icons.navigation),
                    onPressed: () => _openNavigation(item),
                  ),
                  onTap: () => _openNavigation(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MapLocationItem {
  const MapLocationItem({
    required this.title,
    required this.lat,
    required this.lng,
    required this.category,
  });

  final String title;
  final double lat;
  final double lng;
  final String category;
}
