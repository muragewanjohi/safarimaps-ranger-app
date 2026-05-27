import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/dashboard_models.dart';
import '../../../data/services/location_service.dart';
import '../../park/bloc/park_cubit.dart';
import '../bloc/dashboard_cubit.dart';
import '../../shell/main_shell.dart';
import '../../shared/widgets/empty_section.dart';
import '../../shared/widgets/park_map_card.dart';
import '../../shared/widgets/ranger_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _viewAllEmergencies = false;
  bool _viewAllIncidents = false;
  bool _viewAllSightings = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForLocationPermission();
    });
  }

  Future<void> _promptForLocationPermission() async {
    final locationService = getIt<LocationService>();
    if (await locationService.hasPermission) return;
    if (!mounted) return;

    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable location access'),
        content: const Text(
          'SafariMap GameWarden uses your location for patrol tracking, '
          'incident reports, and map features. You can change this anytime '
          'in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Allow location'),
          ),
        ],
      ),
    );

    if (shouldRequest == true && mounted) {
      await locationService.ensurePermission();
    }
  }

  void _loadData() {
    final parkId = getIt<ParkCubit>().state.selectedPark?.id;
    getIt<DashboardCubit>().loadDashboard(parkId: parkId);
  }

  Future<void> _pickPhotoAndNavigate() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      context.push('/add-location?photo=${Uri.encodeComponent(photo.path)}');
    }
  }

  void _showParkSelector() {
    final parkCubit = getIt<ParkCubit>();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select park'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: parkCubit.state.availableParks.length,
            itemBuilder: (context, index) {
              final park = parkCubit.state.availableParks[index];
              return ListTile(
                title: Text(park.name),
                subtitle: Text(park.location ?? ''),
                onTap: () {
                  parkCubit.selectPark(park);
                  _loadData();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<DashboardCubit>(),
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final parkState = getIt<ParkCubit>().state;
          final parkName = parkState.selectedPark?.name ?? 'Select park';

          return Scaffold(
            appBar: RangerAppBar(
              title: 'Dashboard',
              subtitle: parkName,
              actions: [
                RangerIconAction(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onPressed: _loadData,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _pickPhotoAndNavigate,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Snap photo'),
            ),
            body: RefreshIndicator(
              onRefresh: () async => _loadData(),
              edgeOffset: 72,
              child: state.isLoading && state.ranger == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 96),
                      children: [
                        if (state.isOffline) _OfflineBanner(
                          pendingItems: state.pendingSyncItems,
                        ),
                        _WelcomeCard(
                          ranger: state.ranger,
                          parkName: parkName,
                          onSwitchPark: _showParkSelector,
                          onParkDetails: () => context.push(
                            '/park?id=${parkState.selectedPark?.id ?? ''}',
                          ),
                        ),
                        SectionHeader(
                          title: 'Park overview',
                          action: 'Open map',
                          onAction: () => context.go('/map'),
                        ),
                        ParkMapCard(parkId: parkState.selectedPark?.id),
                        if (state.stats != null) _StatsGrid(stats: state.stats!),
                        SectionHeader(title: 'Visitor emergencies'),
                        _buildFilterToggle(
                          value: _viewAllEmergencies,
                          activeText: 'Showing latest 5 emergency alerts',
                          inactiveText: 'Active in the last 48 hours',
                          onChanged: (v) => setState(() => _viewAllEmergencies = v),
                        ),
                        const SizedBox(height: 6),
                        (() {
                          final now = DateTime.now();
                          final filtered = _viewAllEmergencies
                              ? state.emergencyAlerts.take(5).toList()
                              : state.emergencyAlerts
                                  .where((a) =>
                                      a.createdAt == null ||
                                      now.difference(a.createdAt!).inHours <= 48)
                                  .take(5)
                                  .toList();
                          if (filtered.isEmpty) {
                            return const EmptySectionMessage(
                              icon: Icons.emergency_outlined,
                              message: 'No active emergencies',
                            );
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filtered.map(_EmergencyCard.new).toList(),
                          );
                        })(),
                        SectionHeader(
                          title: 'Recent incidents',
                          action: 'View all',
                          onAction: () => context.go('/reports'),
                        ),
                        _buildFilterToggle(
                          value: _viewAllIncidents,
                          activeText: 'Showing latest 5 incident reports',
                          inactiveText: 'Logged in the last 7 days',
                          onChanged: (v) => setState(() => _viewAllIncidents = v),
                        ),
                        const SizedBox(height: 6),
                        (() {
                          final now = DateTime.now();
                          final filtered = _viewAllIncidents
                              ? state.recentIncidents.take(5).toList()
                              : state.recentIncidents
                                  .where((i) =>
                                      i.createdAt == null ||
                                      now.difference(i.createdAt!).inDays <= 7)
                                  .take(5)
                                  .toList();
                          if (filtered.isEmpty) {
                            return const EmptySectionMessage(
                              icon: Icons.report_outlined,
                              message: 'No recent incidents',
                            );
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filtered.map(_IncidentTile.new).toList(),
                          );
                        })(),
                        SectionHeader(
                          title: 'Recent sightings',
                          action: 'View all',
                          onAction: () => context.go('/map'),
                        ),
                        _buildFilterToggle(
                          value: _viewAllSightings,
                          activeText: 'Showing latest 5 recent sightings',
                          inactiveText: 'Logged in the last 3 days',
                          onChanged: (v) => setState(() => _viewAllSightings = v),
                        ),
                        const SizedBox(height: 6),
                        (() {
                          final now = DateTime.now();
                          final filtered = _viewAllSightings
                              ? state.recentLocations.take(5).toList()
                              : state.recentLocations
                                  .where((l) =>
                                      l.createdAt == null ||
                                      now.difference(l.createdAt!).inDays <= 3)
                                  .take(5)
                                  .toList();
                          if (filtered.isEmpty) {
                            return const EmptySectionMessage(
                              icon: Icons.place_outlined,
                              message: 'No recent sightings logged',
                            );
                          }
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filtered.map(_LocationTile.new).toList(),
                          );
                        })(),
                        SectionHeader(title: 'Quick actions'),
                        _QuickActions(
                          onAddReport: () => context.push('/add-report'),
                          onAddLocation: () => context.push('/add-location'),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterToggle({
    required bool value,
    required String activeText,
    required String inactiveText,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  value ? Icons.history_rounded : Icons.history_toggle_off_rounded,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    value ? activeText : inactiveText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: value ? AppTheme.primaryColor : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 24,
                width: 40,
                child: Transform.scale(
                  scale: 0.75,
                  child: Switch.adaptive(
                    value: value,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.pendingItems});

  final int pendingItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.warningColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline mode — $pendingItems items pending sync',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          if (pendingItems > 0) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.15),
                foregroundColor: const Color(0xFF92400E),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                getIt<DashboardCubit>().syncPendingItems();
              },
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text(
                'Sync Now',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.ranger,
    required this.parkName,
    required this.onSwitchPark,
    required this.onParkDetails,
  });

  final RangerProfile? ranger;
  final String parkName;
  final VoidCallback onSwitchPark;
  final VoidCallback onParkDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primaryColor,
            AppTheme.secondaryColor.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    ranger?.avatar ?? 'R',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        ranger?.name ?? 'Ranger',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((ranger?.role ?? '').isNotEmpty)
                        Text(
                          ranger!.role,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: InkWell(
                onTap: onSwitchPark,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.park_rounded,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parkName,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Tap to switch park',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Park details',
                        onPressed: onParkDetails,
                        icon: Icon(
                          Icons.info_outline_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (ranger != null && ranger!.team.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Team: ${ranger!.team}',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          StatCard(
            label: 'Active incidents',
            value: '${stats.activeIncidents}',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
          ),
          StatCard(
            label: 'Wildlife tracked',
            value: '${stats.wildlifeTracked}',
            icon: Icons.pets_rounded,
            color: AppTheme.successColor,
          ),
          StatCard(
            label: 'Tourist locations',
            value: '${stats.touristLocations}',
            icon: Icons.location_on_rounded,
            color: const Color(0xFF0284C7),
          ),
          StatCard(
            label: 'Rangers active',
            value: '${stats.rangersActive}',
            icon: Icons.groups_rounded,
            color: AppTheme.primaryColor,
          ),
          StatCard(
            label: 'Hotels & lodges',
            value: '${stats.hotelsLodges}',
            icon: Icons.hotel_rounded,
            color: const Color(0xFF7C3AED),
          ),
          StatCard(
            label: 'Reports today',
            value: '${stats.reportsToday}',
            icon: Icons.description_outlined,
            color: AppTheme.warningColor,
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard(this.alert);

  final EmergencyAlert alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: alert.urgent
          ? AppTheme.errorColor.withValues(alpha: 0.06)
          : AppTheme.surfaceColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (alert.urgent ? AppTheme.errorColor : AppTheme.warningColor)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.emergency_rounded,
            color: alert.urgent ? AppTheme.errorColor : AppTheme.warningColor,
          ),
        ),
        title: Text(
          alert.type,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${alert.description}\n${alert.location} • ${alert.timeAgo}'),
        ),
        trailing: SeverityBadge(severity: alert.severity),
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  const _IncidentTile(this.incident);

  final IncidentSummary incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.report_rounded,
            color: AppTheme.warningColor,
          ),
        ),
        title: Text(incident.type),
        subtitle: Text('${incident.location} • ${incident.timeAgo}'),
        trailing: SeverityBadge(severity: incident.severity),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile(this.location);

  final LocationItem location;

  Future<void> _openNavigation(BuildContext context) async {
    try {
      final parts = location.coordinates.split(',');
      if (parts.length != 2) return;

      final latPart = parts[0].trim();
      final lngPart = parts[1].trim();

      final latMatch = RegExp(r'(-?\d+\.?\d*)').firstMatch(latPart);
      final lngMatch = RegExp(r'(-?\d+\.?\d*)').firstMatch(lngPart);

      if (latMatch == null || lngMatch == null) return;

      var lat = double.parse(latMatch.group(1)!);
      var lng = double.parse(lngMatch.group(1)!);

      if (latPart.toUpperCase().contains('S') && lat > 0) lat = -lat;
      if (lngPart.toUpperCase().contains('W') && lng > 0) lng = -lng;

      if (context.mounted) {
        context.push(
          '/directions?to_lat=$lat&to_lng=$lng&to_title=${Uri.encodeComponent(location.title)}&to_category=${Uri.encodeComponent(location.category)}',
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(int.parse(
                    '0xFF${location.iconColor.replaceAll('#', '')}'))
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.place_rounded,
            color: Color(
              int.parse('0xFF${location.iconColor.replaceAll('#', '')}'),
            ),
          ),
        ),
        title: Text(location.title),
        subtitle: Text(location.category),
        trailing: Container(
          width: 80,
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => _openNavigation(context),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.navigation_rounded,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  if (location.timeAgo != null)
                    Text(
                      location.timeAgo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
        onTap: () => _openNavigation(context),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddReport,
    required this.onAddLocation,
  });

  final VoidCallback onAddReport;
  final VoidCallback onAddLocation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.add_alert_rounded,
                  label: 'Report incident',
                  color: AppTheme.errorColor,
                  onTap: onAddReport,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.add_location_alt_rounded,
                  label: 'Add location',
                  color: AppTheme.primaryColor,
                  onTap: onAddLocation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _QuickActionTile(
            icon: Icons.map_rounded,
            label: 'View full map',
            color: const Color(0xFF0284C7),
            onTap: () => context.go('/map'),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.authBorder),
          ),
          child: Row(
            mainAxisAlignment:
                fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.primaryDark,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
