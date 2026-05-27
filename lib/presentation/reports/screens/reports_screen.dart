import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/mock_data.dart';
import '../../../data/models/dashboard_models.dart';
import '../../park/bloc/park_cubit.dart';
import '../../shared/widgets/ranger_app_bar.dart';
import '../../shell/main_shell.dart';
import '../bloc/incidents_cubit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final IncidentsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<IncidentsCubit>();
    _load();
  }

  void _load() {
    final parkId = getIt<ParkCubit>().state.selectedPark?.id;
    _cubit.loadIncidents(parkId: parkId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<IncidentsCubit, IncidentsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: RangerAppBar(
              title: 'Incident reports',
              subtitle: getIt<ParkCubit>().state.selectedPark?.name,
              actions: [
                RangerIconAction(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onPressed: _load,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => context.push('/add-report'),
              icon: const Icon(Icons.add),
              label: const Text('New Report'),
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async => _load(),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 80),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              _SummaryCard(
                                label: 'Critical',
                                count: state.criticalCount,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(width: 8),
                              _SummaryCard(
                                label: 'High',
                                count: state.highCount,
                                color: AppTheme.warningColor,
                              ),
                              const SizedBox(width: 8),
                              _SummaryCard(
                                label: 'Active',
                                count: state.activeCount,
                                color: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                        _StatusFilterBar(
                          selectedFilter: state.filter,
                          onFilterChanged: (filter) {
                            _cubit.setFilter(filter);
                          },
                        ),
                        const SizedBox(height: 12),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(state.error!,
                                style: const TextStyle(color: AppTheme.errorColor)),
                          ),
                        (() {
                          final filtered = state.filter == 'All'
                              ? state.incidents
                              : state.incidents
                                  .where((i) => i.status == state.filter)
                                  .toList();

                          if (filtered.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                              child: Center(
                                child: Text(
                                  'No matching incidents reported',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: filtered.map((incident) {
                              return _IncidentCard(
                                incident: incident,
                                onTap: () => context.push('/add-report?id=${incident.id}'),
                              );
                            }).toList(),
                          );
                        })(),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  )),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  static const _filters = ['All', 'Reported', 'In Progress', 'Resolved'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.primaryDark,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              onSelected: (selected) {
                if (selected) {
                  onFilterChanged(filter);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : AppTheme.authBorder,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    switch (status) {
      case 'Reported':
        color = const Color(0xFFEFF6FF);
        textColor = const Color(0xFF1D4ED8);
        break;
      case 'In Progress':
        color = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        break;
      case 'Resolved':
        color = const Color(0xFFECFDF5);
        textColor = const Color(0xFF047857);
        break;
      default:
        color = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.onTap,
  });

  final IncidentModel incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeAgo = MockData.getTimeAgo(incident.createdAt);
    final hasLocation = incident.location != null && incident.location!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.authBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            incident.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      incident.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                    if (hasLocation || timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${hasLocation ? incident.location : 'Unknown Location'}${timeAgo.isNotEmpty ? ' • $timeAgo' : ''}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusBadge(status: incident.status),
                        const SizedBox(width: 8),
                        SeverityBadge(severity: incident.severity),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
