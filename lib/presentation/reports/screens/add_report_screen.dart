import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../data/services/location_service.dart';
import '../../park/bloc/park_cubit.dart';
import '../../shared/widgets/park_map_card.dart';
import '../bloc/incidents_cubit.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _touristsController = TextEditingController(text: '0');
  final _operatorController = TextEditingController();
  final _transportController = TextEditingController();
  final _medicalController = TextEditingController();

  String _category = 'Wildlife';
  String _severity = 'Medium';
  String _status = 'Reported';
  final List<String> _photos = [];
  LatLng? _selectedPoint;

  static const _categories = [
    'Wildlife', 'Medical', 'Infrastructure', 'Security', 'Environmental'
  ];
  static const _severities = ['Critical', 'High', 'Medium', 'Low'];
  static const _statuses = ['Reported', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _fillGps();
  }

  Future<void> _fillGps() async {
    final loc = await getIt<LocationService>().getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _selectedPoint = LatLng(loc.latitude, loc.longitude);
      });
      context.read<AddReportCubit>().updateField(
            coordinates: getIt<LocationService>().formatCoordinates(loc),
          );
    }
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 3) return;
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo != null && mounted) {
      setState(() => _photos.add(photo.path));
      context.read<AddReportCubit>().updateField(photos: List.from(_photos));
    }
  }

  Future<void> _submit() async {
    final cubit = context.read<AddReportCubit>();
    cubit.updateField(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      category: _category,
      severity: _severity,
      status: _status,
      touristsAffected: int.tryParse(_touristsController.text) ?? 0,
      tourOperator: _operatorController.text.trim(),
      transport: _transportController.text.trim(),
      medicalCondition: _medicalController.text.trim(),
    );

    final parkId = getIt<ParkCubit>().state.selectedPark?.id;
    final success = await cubit.submit(parkId: parkId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _touristsController.dispose();
    _operatorController.dispose();
    _transportController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Incident Report')),
      body: BlocBuilder<AddReportCubit, AddReportState>(
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title *'),
                    ),
                    const SizedBox(height: 12),
                    _dropdown('Category', _category, _categories,
                        (v) => setState(() => _category = v!)),
                    _dropdown('Severity', _severity, _severities,
                        (v) => setState(() => _severity = v!)),
                    _dropdown('Status', _status, _statuses,
                        (v) => setState(() => _status = v!)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _touristsController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Tourists Affected'),
                    ),
                    TextField(
                      controller: _operatorController,
                      decoration: const InputDecoration(labelText: 'Tour Operator'),
                    ),
                    TextField(
                      controller: _transportController,
                      decoration: const InputDecoration(labelText: 'Transport'),
                    ),
                    TextField(
                      controller: _medicalController,
                      decoration:
                          const InputDecoration(labelText: 'Medical Condition'),
                    ),
                    const SizedBox(height: 16),
                    SafariMapView(
                      mode: MapViewMode.select,
                      initialRegion: _selectedPoint,
                      onLocationSelected: (point) {
                        setState(() => _selectedPoint = point);
                        context.read<AddReportCubit>().updateField(
                              coordinates: getIt<LocationService>()
                                  .formatCoordinatesDisplay(
                                point.latitude,
                                point.longitude,
                              ),
                            );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ..._photos.map(
                          (p) => Chip(
                            label: Text(p.split('/').last),
                            onDeleted: () => setState(() => _photos.remove(p)),
                          ),
                        ),
                        if (_photos.length < 3)
                          ActionChip(
                            avatar: const Icon(Icons.photo, size: 18),
                            label: const Text('Add Photo'),
                            onPressed: _pickPhoto,
                          ),
                      ],
                    ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(state.error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.isSubmitting ? null : _submit,
                      child: Text(state.isSubmitting ? 'Submitting...' : 'Submit Report'),
                    ),
                  ],
                ),
              ),
              if (state.isSubmitting)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Card(
                        margin: const EdgeInsets.all(32),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Submitting Report...',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploading details and photos...',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
