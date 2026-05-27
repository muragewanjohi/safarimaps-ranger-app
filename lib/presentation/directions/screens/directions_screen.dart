import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/location_service.dart';
import '../../shared/widgets/park_map_card.dart';

class DirectionsScreen extends StatefulWidget {
  const DirectionsScreen({
    super.key,
    this.fromLat,
    this.fromLng,
    required this.toLat,
    required this.toLng,
    this.toTitle,
    this.toCategory,
  });

  final double? fromLat;
  final double? fromLng;
  final double toLat;
  final double toLng;
  final String? toTitle;
  final String? toCategory;

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  LatLng? _fromPoint;
  bool _isLoading = true;
  String _travelMode = 'Drive'; // 'Drive' or 'Walk'
  double _distanceKm = 0.0;
  int _durationMin = 0;

  @override
  void initState() {
    super.initState();
    _initCoordinates();
  }

  Future<void> _initCoordinates() async {
    if (widget.fromLat != null && widget.fromLng != null) {
      _fromPoint = LatLng(widget.fromLat!, widget.fromLng!);
    } else {
      final loc = await getIt<LocationService>().getCurrentLocation();
      if (loc != null) {
        _fromPoint = LatLng(loc.latitude, loc.longitude);
      } else {
        // Fallback to Nairobi National Park center or default
        _fromPoint = const LatLng(-1.357, 36.822);
      }
    }
    _calculateRouteMetrics();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateRouteMetrics() {
    if (_fromPoint == null) return;
    
    final distanceMeters = getIt<LocationService>().calculateDistance(
      LocationCoordinates(latitude: _fromPoint!.latitude, longitude: _fromPoint!.longitude),
      LocationCoordinates(latitude: widget.toLat, longitude: widget.toLng),
    );
    final distance = distanceMeters / 1000.0;

    setState(() {
      _distanceKm = distance;
      if (_travelMode == 'Drive') {
        // Average speed inside parks is ~30 km/h due to terrain
        _durationMin = ((distance / 30.0) * 60).round();
      } else {
        // Average walking speed is ~5 km/h
        _durationMin = ((distance / 5.0) * 60).round();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final toTitle = widget.toTitle ?? 'Sighting Location';
    final toCategory = widget.toCategory ?? 'General';
    final fromTitle = 'Current Location';

    final markers = [
      MapMarkerData(
        title: fromTitle,
        position: _fromPoint!,
      ),
      MapMarkerData(
        title: toTitle,
        position: LatLng(widget.toLat, widget.toLng),
      ),
    ];

    final trailCoordinates = [
      _fromPoint!,
      LatLng(widget.toLat, widget.toLng),
    ];

    final stepsCount = (_distanceKm * 1312).round(); // approx 1312 steps per km

    return Scaffold(
      appBar: AppBar(
        title: const Text('Directions'),
        elevation: 0,
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.primaryDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.authBorder)),
              ),
              child: SafariMapView(
                markers: markers,
                trailCoordinates: trailCoordinates,
                initialRegion: LatLng(
                  (_fromPoint!.latitude + widget.toLat) / 2,
                  (_fromPoint!.longitude + widget.toLng) / 2,
                ),
                height: double.infinity,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModeChip('Drive', Icons.directions_car_filled_rounded),
                        const SizedBox(width: 12),
                        _buildModeChip('Walk', Icons.directions_run_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppTheme.authBorder),
                      ),
                      elevation: 0,
                      color: AppTheme.surfaceColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildTimelineRow(
                              icon: Icons.gps_fixed_rounded,
                              iconColor: Colors.blue,
                              label: 'Start Point',
                              value: fromTitle,
                              isLast: false,
                            ),
                            _buildTimelineRow(
                              icon: Icons.place_rounded,
                              iconColor: Colors.red,
                              label: 'Destination',
                              value: '$toTitle ($toCategory)',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Distance',
                            value: '${_distanceKm.toStringAsFixed(1)} km',
                            icon: Icons.straighten_rounded,
                            iconColor: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: 'Duration',
                            value: '$_durationMin min',
                            icon: Icons.schedule_rounded,
                            iconColor: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    if (_travelMode == 'Walk') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.authBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Estimated $stepsCount steps for this walk. Maintain standard hydration.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'End Navigation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String mode, IconData icon) {
    final isSelected = _travelMode == mode;
    return ChoiceChip(
      label: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : AppTheme.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(mode),
        ],
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.primaryDark,
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _travelMode = mode;
            _calculateRouteMetrics();
          });
        }
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppTheme.authBorder,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildTimelineRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.authBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
