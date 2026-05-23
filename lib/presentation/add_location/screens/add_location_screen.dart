import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../data/services/location_service.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.initialPhotoPath != null) {
      _photos.add(widget.initialPhotoPath!);
    }
    _fillGps();
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
    if (photo != null) {
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
    final success =
        await context.read<AddLocationCubit>().submit(parkId: parkId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location added successfully')),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Location')),
      body: BlocBuilder<AddLocationCubit, AddLocationState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subcategoryController,
                  decoration: const InputDecoration(labelText: 'Subcategory *'),
                ),
                if (_category == 'Wildlife')
                  TextField(
                    controller: _countController,
                    decoration: const InputDecoration(labelText: 'Count'),
                  ),
                if (_category == 'Attractions')
                  TextField(
                    controller: _attractionController,
                    decoration:
                        const InputDecoration(labelText: 'Attraction Name'),
                  ),
                if (_category == 'Hotels')
                  TextField(
                    controller: _hotelController,
                    decoration: const InputDecoration(labelText: 'Hotel Name'),
                  ),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description *'),
                ),
                TextField(
                  controller: _hoursController,
                  decoration: const InputDecoration(labelText: 'Operating Hours'),
                ),
                TextField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact'),
                ),
                TextField(
                  controller: _bestTimeController,
                  decoration:
                      const InputDecoration(labelText: 'Best Time to Visit'),
                ),
                const SizedBox(height: 16),
                SafariMapView(
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: const Text('Gallery'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: _photos
                      .map((p) => Chip(label: Text(p.split('/').last)))
                      .toList(),
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
                  child: Text(
                      state.isSubmitting ? 'Submitting...' : 'Add Location'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
