import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
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

  void _showPlaceholderAction(String action) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text('$action functionality coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(state.error!,
                                style: const TextStyle(color: AppTheme.errorColor)),
                          ),
                        ...state.incidents.map(
                          (incident) => _IncidentCard(
                            incident: incident,
                            onUpdate: () => _showPlaceholderAction('Update Status'),
                            onNote: () => _showPlaceholderAction('Add Note'),
                            onEscalate: () => _showPlaceholderAction('Escalate'),
                          ),
                        ),
                        if (state.incidents.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: Text('No incidents reported')),
                          ),
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

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({
    required this.incident,
    required this.onUpdate,
    required this.onNote,
    required this.onEscalate,
  });

  final IncidentModel incident;
  final VoidCallback onUpdate;
  final VoidCallback onNote;
  final VoidCallback onEscalate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                SeverityBadge(severity: incident.severity),
              ],
            ),
            const SizedBox(height: 8),
            Text(incident.description),
            if (incident.location != null)
              Text('Location: ${incident.location}',
                  style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(onPressed: onUpdate, child: const Text('Update Status')),
                OutlinedButton(onPressed: onNote, child: const Text('Add Note')),
                OutlinedButton(onPressed: onEscalate, child: const Text('Escalate')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
