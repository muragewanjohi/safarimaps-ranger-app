import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../park/bloc/park_cubit.dart';
import '../../shared/widgets/ranger_app_bar.dart';
import '../../shell/main_shell.dart';
import '../bloc/profile_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ProfileCubit>()..loadProfile();
  }

  void _showParkSelector() {
    final parkCubit = getIt<ParkCubit>();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Park'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: parkCubit.state.availableParks.length,
            itemBuilder: (context, index) {
              final park = parkCubit.state.availableParks[index];
              return ListTile(
                title: Text(park.name),
                onTap: () {
                  parkCubit.selectPark(park);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parkState = getIt<ParkCubit>().state;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return Scaffold(
            appBar: RangerAppBar(
              title: 'Profile',
              subtitle: parkState.selectedPark?.name,
              actions: [
                RangerIconAction(
                  icon: Icons.more_vert_rounded,
                  tooltip: 'More options',
                  onPressed: _confirmSignOut,
                ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Text(state.ranger?.avatar ?? 'R',
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(state.ranger?.name ?? 'Ranger'),
                          subtitle: Text(
                            '${state.ranger?.role ?? ''}\nID: ${state.ranger?.rangerId ?? '-'}',
                          ),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.park),
                          title: const Text('Current Park'),
                          subtitle: Text(parkState.selectedPark?.name ?? '-'),
                          trailing: const Icon(Icons.swap_horiz),
                          onTap: _showParkSelector,
                        ),
                      ),
                      const SectionHeader(title: 'Impact Stats'),
                      if (state.impactStats != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              StatCard(
                                label: 'Incidents',
                                value: '${state.impactStats!.incidentsReported}',
                                icon: Icons.report,
                                color: AppTheme.warningColor,
                              ),
                              StatCard(
                                label: 'Wildlife',
                                value: '${state.impactStats!.wildlifeTracked}',
                                icon: Icons.pets,
                                color: AppTheme.successColor,
                              ),
                              StatCard(
                                label: 'Patrols',
                                value: '${state.impactStats!.patrolsCompleted}',
                                icon: Icons.directions_walk,
                                color: AppTheme.primaryColor,
                              ),
                              StatCard(
                                label: 'Days Active',
                                value: '${state.impactStats!.daysActive}',
                                icon: Icons.calendar_today,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                      const SectionHeader(title: 'Achievements'),
                      ...state.achievements.map(
                        (a) => Card(
                          child: ListTile(
                            leading: Icon(Icons.emoji_events,
                                color: Color(int.parse(
                                    '0xFF${a.iconColor.replaceAll('#', '')}'))),
                            title: Text(a.title),
                            subtitle: Text(a.description),
                          ),
                        ),
                      ),
                      const SectionHeader(title: 'Preferences'),
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        value: state.pushNotifications,
                        onChanged: _cubit.togglePushNotifications,
                      ),
                      SwitchListTile(
                        title: const Text('Location Sharing'),
                        value: state.locationSharing,
                        onChanged: _cubit.toggleLocationSharing,
                      ),
                      SwitchListTile(
                        title: const Text('Offline Mode'),
                        subtitle: const Text('Placeholder - not functional'),
                        value: state.offlineMode,
                        onChanged: _cubit.toggleOfflineMode,
                      ),
                      SwitchListTile(
                        title: const Text('Auto Sync'),
                        subtitle: const Text('Placeholder - not functional'),
                        value: state.autoSync,
                        onChanged: _cubit.toggleAutoSync,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _confirmSignOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
