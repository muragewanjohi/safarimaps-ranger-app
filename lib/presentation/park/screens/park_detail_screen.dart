import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/park_model.dart';
import '../../profile/bloc/profile_cubit.dart';

class ParkDetailScreen extends StatefulWidget {
  const ParkDetailScreen({super.key, required this.parkId});

  final String parkId;

  @override
  State<ParkDetailScreen> createState() => _ParkDetailScreenState();
}

class _ParkDetailScreenState extends State<ParkDetailScreen> {
  late final ParkDetailCubit _cubit;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _hoursController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ParkDetailCubit>()..loadPark(widget.parkId);
  }

  void _populateFields(ParkModel? park) {
    if (park == null) return;
    _nameController.text = park.name;
    _descriptionController.text = park.description ?? '';
    _locationController.text = park.location ?? '';
    _hoursController.text = park.operatingHours ?? '';
    _areaController.text = park.area ?? park.size ?? '';
  }

  Future<void> _savePark() async {
    final park = _cubit.state.park;
    if (park == null) return;

    await _cubit.updatePark(park.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      operatingHours: _hoursController.text.trim(),
      area: _areaController.text.trim(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Park details saved')),
      );
    }
  }

  void _showAddEntryDialog() {
    final nameController = TextEditingController();
    final coordsController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Park Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Entry Name'),
            ),
            TextField(
              controller: coordsController,
              decoration: const InputDecoration(
                labelText: 'Coordinates',
                hintText: '1.4000° S, 35.6000° E',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _cubit.addEntry(ParkEntryModel(
                id: '',
                parkId: widget.parkId,
                name: nameController.text.trim(),
                entryType: 'Entry',
                status: 'Primary',
                coordinates: coordsController.text.trim(),
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _hoursController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ParkDetailCubit, ParkDetailState>(
        listener: (context, state) {
          if (state.park != null && _nameController.text.isEmpty) {
            _populateFields(state.park);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.park?.name ?? 'Park Details'),
              actions: [
                if (state.isSaving)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _savePark,
                  ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Park Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            )),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                        ),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                        ),
                        TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                        TextField(
                          controller: _hoursController,
                          decoration:
                              const InputDecoration(labelText: 'Operating Hours'),
                        ),
                        TextField(
                          controller: _areaController,
                          decoration: const InputDecoration(labelText: 'Area'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Park Entries',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                )),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _showAddEntryDialog,
                            ),
                          ],
                        ),
                        ...state.entries.map(
                          (entry) => Card(
                            child: ListTile(
                              leading: Icon(
                                entry.entryType == 'Exit'
                                    ? Icons.exit_to_app
                                    : Icons.login,
                                color: AppTheme.primaryColor,
                              ),
                              title: Text(entry.name),
                              subtitle: Text(
                                '${entry.status} • ${entry.coordinates}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _cubit.deleteEntry(entry.id),
                              ),
                            ),
                          ),
                        ),
                        if (state.entries.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No park entries configured'),
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
