import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/mock_data.dart';
import '../../../data/services/location_service.dart';
import '../../park/bloc/park_cubit.dart';
import '../../shared/widgets/park_map_card.dart';
import '../bloc/incidents_cubit.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key, this.incidentId});

  final String? incidentId;

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
  bool _initializedFromEdit = false;

  static const _categories = [
    'Wildlife', 'Medical', 'Infrastructure', 'Security', 'Environmental'
  ];
  static const _severities = ['Critical', 'High', 'Medium', 'Low'];
  static const _statuses = ['Reported', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    if (widget.incidentId == null) {
      _fillGps();
    }
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

  LatLng? _parseCoordinatesString(String? coords) {
    if (coords == null || coords.isEmpty) return null;
    try {
      final clean = coords
          .replaceAll('°N', '')
          .replaceAll('°E', '')
          .replaceAll('°S', '')
          .replaceAll('°W', '')
          .trim();
      final parts = clean.split(',');
      if (parts.length >= 2) {
        final lat = double.tryParse(parts[0].trim());
        final lng = double.tryParse(parts[1].trim());
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      }
    } catch (_) {}
    return null;
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
      final successMsg = cubit.state.successMessage ?? 
          (cubit.state.isEditMode ? 'Report updated successfully' : 'Report submitted successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
      context.pop();
    }
  }

  void _showAddNoteDialog() {
    final cubit = context.read<AddReportCubit>();
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Note to Incident'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter note details...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogContext);
                final success = await cubit.addNote(text);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note added successfully')),
                  );
                }
              }
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.authBorder, width: 1),
      ),
      elevation: 0,
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1, color: AppTheme.authBorder),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddReportCubit, AddReportState>(
      listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
      listener: (context, state) {
        if (state.isEditMode && !_initializedFromEdit) {
          _titleController.text = state.title;
          _descriptionController.text = state.description;
          _locationController.text = state.location ?? '';
          _touristsController.text = state.touristsAffected.toString();
          _operatorController.text = state.tourOperator ?? '';
          _transportController.text = state.transport ?? '';
          _medicalController.text = state.medicalCondition ?? '';
          setState(() {
            _category = state.category;
            _severity = state.severity;
            _status = state.status;
            _selectedPoint = _parseCoordinatesString(state.coordinates);
            _photos.clear();
            _photos.addAll(state.photos);
            _initializedFromEdit = true;
          });
        }
      },
      builder: (context, state) {
        final titleText = state.isEditMode ? 'Update Incident Report' : 'New Incident Report';
        final buttonText = state.isSubmitting 
            ? (state.isEditMode ? 'Updating...' : 'Submitting...')
            : (state.isEditMode ? 'Update Report' : 'Submit Report');

        return Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            elevation: 0,
            backgroundColor: AppTheme.surfaceColor,
            foregroundColor: AppTheme.primaryDark,
          ),
          floatingActionButton: state.isEditMode && !state.isLoading
              ? FloatingActionButton.extended(
                  onPressed: _showAddNoteDialog,
                  icon: const Icon(Icons.add_comment_rounded),
                  label: const Text('Add Note'),
                )
              : null,
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionCard(
                            title: 'Incident Information',
                            icon: Icons.assignment_outlined,
                            children: [
                              TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title *',
                                  prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _dropdown(
                                'Category',
                                _category,
                                _categories,
                                Icons.category_outlined,
                                (v) => setState(() => _category = v!),
                              ),
                              const SizedBox(height: 4),
                              _dropdown(
                                'Severity',
                                _severity,
                                _severities,
                                Icons.warning_amber_rounded,
                                (v) => setState(() => _severity = v!),
                              ),
                              if (state.isEditMode) ...[
                                const SizedBox(height: 4),
                                _dropdown(
                                  'Status',
                                  _status,
                                  _statuses,
                                  Icons.rule_folder_outlined,
                                  (v) => setState(() => _status = v!),
                                ),
                              ],
                              const SizedBox(height: 4),
                              TextField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Description *',
                                  prefixIcon: Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ],
                          ),
                          _buildSectionCard(
                            title: 'Geospatial Location',
                            icon: Icons.location_on_outlined,
                            children: [
                              TextField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location Name',
                                  prefixIcon: Icon(Icons.place_outlined, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.authBorder),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SafariMapView(
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
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (state.coordinates != null && state.coordinates!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.authBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.gps_fixed_rounded, size: 16, color: AppTheme.primaryColor),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'GPS: ${state.coordinates}',
                                            style: TextStyle(
                                              fontFamily: AppTheme.monoStyle().fontFamily,
                                              fontSize: 12,
                                              color: Colors.blueGrey.shade700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (state.isEditMode && _selectedPoint != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final lat = _selectedPoint!.latitude;
                                      final lng = _selectedPoint!.longitude;
                                      context.push(
                                        '/directions?to_lat=$lat&to_lng=$lng&to_title=${Uri.encodeComponent(state.title)}&to_category=${Uri.encodeComponent(state.category)}',
                                      );
                                    },
                                    icon: const Icon(Icons.directions_rounded),
                                    label: const Text('Get Directions'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ..._photos.map(
                                    (p) => Chip(
                                      label: Text(p.split('/').last),
                                      onDeleted: () => setState(() => _photos.remove(p)),
                                    ),
                                  ),
                                  if (_photos.length < 3 && !state.isEditMode)
                                    ActionChip(
                                      avatar: const Icon(Icons.photo, size: 18, color: AppTheme.primaryColor),
                                      label: const Text('Add Photo'),
                                      onPressed: _pickPhoto,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          _buildSectionCard(
                            title: 'Impact & Logistics',
                            icon: Icons.people_outline_rounded,
                            children: [
                              TextField(
                                controller: _touristsController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Tourists Affected',
                                  prefixIcon: Icon(Icons.group_outlined, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _operatorController,
                                decoration: const InputDecoration(
                                  labelText: 'Tour Operator',
                                  prefixIcon: Icon(Icons.business_outlined, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _transportController,
                                decoration: const InputDecoration(
                                  labelText: 'Transport Details',
                                  prefixIcon: Icon(Icons.directions_car_outlined, color: AppTheme.primaryColor),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _medicalController,
                                decoration: const InputDecoration(
                                  labelText: 'Medical Condition',
                                  prefixIcon: Icon(Icons.medical_services_outlined, color: AppTheme.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          if (state.isEditMode) ...[
                            _buildSectionCard(
                              title: 'Incident Timeline / Notes',
                              icon: Icons.history_toggle_off_rounded,
                              children: [
                                if (state.notes.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Column(
                                      children: [
                                        Icon(Icons.comment_bank_outlined, size: 48, color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No notes logged for this incident yet.',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.notes.length,
                                    itemBuilder: (context, index) {
                                      final note = state.notes[index];
                                      final authorInitials = note.createdBy != null && note.createdBy!.isNotEmpty
                                          ? note.createdBy!.substring(0, 1).toUpperCase()
                                          : 'R';

                                      return Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppTheme.primaryColor,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  authorInitials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (index < state.notes.length - 1)
                                                Container(
                                                  width: 2,
                                                  height: 48,
                                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 16),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: AppTheme.authBorder),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        note.createdBy ?? 'Ranger',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.primaryDark,
                                                        ),
                                                      ),
                                                      Text(
                                                        MockData.getTimeAgo(note.createdAt),
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    note.note,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF334155),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(state.error!,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: state.isSubmitting ? null : _submit,
                            child: Text(buttonText),
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
                                      state.isEditMode ? 'Updating Report...' : 'Submitting Report...',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Uploading details...',
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
                ),
        );
      },
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
