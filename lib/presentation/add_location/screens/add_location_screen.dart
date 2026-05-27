import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/location_service.dart';
import '../../home/bloc/dashboard_cubit.dart';
import '../../park/bloc/park_cubit.dart';
import '../../shared/widgets/park_map_card.dart';
import '../bloc/add_location_cubit.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key, this.initialPhotoPath});

  final String? initialPhotoPath;

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _subcategoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countController = TextEditingController();
  final _attractionController = TextEditingController();
  final _hotelController = TextEditingController();
  final _hoursController = TextEditingController();
  final _contactController = TextEditingController();
  final _bestTimeController = TextEditingController();

  String _category = 'Wildlife';
  LatLng? _selectedPoint;
  final List<String> _photos = [];

  static const _categories = [
    'Wildlife', 'Attractions', 'Hotels', 'Dining', 'Viewpoints'
  ];

  bool get _isValid =>
      _subcategoryController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhotoPath != null) {
      _photos.add(widget.initialPhotoPath!);
    }
    _fillGps();

    // Listeners to update validation states in real-time
    _subcategoryController.addListener(_updateValidation);
    _descriptionController.addListener(_updateValidation);
  }

  void _updateValidation() {
    setState(() {});
  }

  Future<void> _fillGps() async {
    final loc = await getIt<LocationService>().getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _selectedPoint = LatLng(loc.latitude, loc.longitude);
      });
      context.read<AddLocationCubit>().update(
            coordinates: getIt<LocationService>().formatCoordinates(loc),
          );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= 3) return;
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source);
    if (photo != null && mounted) {
      setState(() => _photos.add(photo.path));
      context.read<AddLocationCubit>().update(photos: List.from(_photos));
    }
  }

  Future<void> _submit() async {
    context.read<AddLocationCubit>().update(
          category: _category,
          subcategory: _subcategoryController.text.trim(),
          description: _descriptionController.text.trim(),
          count: _countController.text.trim(),
          attractionName: _attractionController.text.trim(),
          hotelName: _hotelController.text.trim(),
          operatingHours: _hoursController.text.trim(),
          contact: _contactController.text.trim(),
          bestTimeToVisit: _bestTimeController.text.trim(),
          photos: _photos,
        );

    final parkId = getIt<ParkCubit>().state.selectedPark?.id;
    final cubit = context.read<AddLocationCubit>();
    final success = await cubit.submit(parkId: parkId);
    if (success && mounted) {
      getIt<DashboardCubit>().loadDashboard(parkId: parkId);
      final successMsg = cubit.state.successMessage ?? 'Location added successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _subcategoryController.removeListener(_updateValidation);
    _descriptionController.removeListener(_updateValidation);
    _subcategoryController.dispose();
    _descriptionController.dispose();
    _countController.dispose();
    _attractionController.dispose();
    _hotelController.dispose();
    _hoursController.dispose();
    _contactController.dispose();
    _bestTimeController.dispose();
    super.dispose();
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sighting details',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subcategoryController,
              decoration: const InputDecoration(
                labelText: 'Subcategory *',
                hintText: 'e.g. Elephant, Lion, Ranger Station',
                prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.primaryColor),
              ),
            ),
            if (_category == 'Wildlife') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Count',
                  hintText: 'e.g. 1, 5, 12',
                  prefixIcon: Icon(Icons.pets_outlined, color: AppTheme.primaryColor),
                ),
              ),
            ],
            if (_category == 'Attractions') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _attractionController,
                decoration: const InputDecoration(
                  labelText: 'Attraction Name',
                  prefixIcon: Icon(Icons.landscape_outlined, color: AppTheme.primaryColor),
                ),
              ),
            ],
            if (_category == 'Hotels') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _hotelController,
                decoration: const InputDecoration(
                  labelText: 'Hotel Name',
                  prefixIcon: Icon(Icons.hotel_outlined, color: AppTheme.primaryColor),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description *',
                alignLabelWithHint: true,
                hintText: 'Describe animal behavior, landscape conditions...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 56),
                  child: Icon(Icons.description_outlined, color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    final coordText = _selectedPoint != null
        ? '${_selectedPoint!.latitude.toStringAsFixed(4)}°, ${_selectedPoint!.longitude.toStringAsFixed(4)}°'
        : 'No location selected';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sighting Location',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.primaryDark,
                  ),
                ),
                if (_selectedPoint != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.gps_fixed_rounded, size: 10, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          coordText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 180,
                child: SafariMapView(
                  mode: MapViewMode.select,
                  initialRegion: _selectedPoint,
                  onLocationSelected: (point) {
                    setState(() => _selectedPoint = point);
                    context.read<AddLocationCubit>().update(
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
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoStrip() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Photos (Max 3)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            if (_photos.isEmpty)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'No photos added yet',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final path = _photos[index];
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _photos.removeAt(index);
                              });
                              context
                                  .read<AddLocationCubit>()
                                  .update(photos: List.from(_photos));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _photos.length >= 3 ? null : () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _photos.length >= 3 ? null : () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionalCard() {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text(
            'Additional Details (Optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppTheme.primaryDark,
            ),
          ),
          leading: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
          childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
          children: [
            TextField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Operating Hours',
                prefixIcon: Icon(Icons.access_time_rounded, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact',
                prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bestTimeController,
              decoration: const InputDecoration(
                labelText: 'Best Time to Visit',
                prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Location')),
      body: BlocBuilder<AddLocationCubit, AddLocationState>(
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16).copyWith(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDetailsCard(),
                    const SizedBox(height: 8),
                    _buildMapCard(),
                    const SizedBox(height: 8),
                    _buildPhotoStrip(),
                    const SizedBox(height: 8),
                    _buildOptionalCard(),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12, left: 8),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (state.isSubmitting || !_isValid) ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: AppTheme.primaryDark.withValues(alpha: 0.3),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        state.isSubmitting ? 'Submitting...' : 'Save Sighting',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
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
                                'Saving Location...',
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
}
