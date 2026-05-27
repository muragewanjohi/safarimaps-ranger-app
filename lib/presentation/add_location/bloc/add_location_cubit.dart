import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/dashboard_models.dart';
import '../../../data/repositories/data_repository.dart';

class AddLocationCubit extends Cubit<AddLocationState> {
  AddLocationCubit(this._dataRepository) : super(const AddLocationState.initial());

  final DataRepository _dataRepository;

  void update({
    String? category,
    String? subcategory,
    String? description,
    String? coordinates,
    String? count,
    String? attractionName,
    String? operatingHours,
    String? hotelName,
    String? contact,
    String? bestTimeToVisit,
    List<String>? photos,
  }) {
    emit(state.copyWith(
      category: category ?? state.category,
      subcategory: subcategory ?? state.subcategory,
      description: description ?? state.description,
      coordinates: coordinates ?? state.coordinates,
      count: count ?? state.count,
      attractionName: attractionName ?? state.attractionName,
      operatingHours: operatingHours ?? state.operatingHours,
      hotelName: hotelName ?? state.hotelName,
      contact: contact ?? state.contact,
      bestTimeToVisit: bestTimeToVisit ?? state.bestTimeToVisit,
      photos: photos ?? state.photos,
    ));
  }

  Future<bool> submit({String? parkId}) async {
    emit(state.copyWith(isSubmitting: true, error: null));
    final input = NewLocationInput(
      category: state.category,
      subcategory: state.subcategory,
      description: state.description,
      coordinates: state.coordinates,
      count: state.count,
      attractionName: state.attractionName,
      operatingHours: state.operatingHours,
      hotelName: state.hotelName,
      contact: state.contact,
      bestTimeToVisit: state.bestTimeToVisit,
      photos: state.photos,
    );

    final response = await _dataRepository.addLocation(input, parkId: parkId);
    if (response.success) {
      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        successMessage: response.message,
      ));
      return true;
    }

    emit(state.copyWith(
      isSubmitting: false,
      error: response.error ?? 'Failed to add location',
    ));
    return false;
  }
}

class AddLocationState extends Equatable {
  const AddLocationState({
    this.category = 'Wildlife',
    this.subcategory = '',
    this.description = '',
    this.coordinates = '',
    this.count,
    this.attractionName,
    this.operatingHours,
    this.hotelName,
    this.contact,
    this.bestTimeToVisit,
    this.photos = const [],
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
    this.successMessage,
  });

  const AddLocationState.initial() : this();

  final String category;
  final String subcategory;
  final String description;
  final String coordinates;
  final String? count;
  final String? attractionName;
  final String? operatingHours;
  final String? hotelName;
  final String? contact;
  final String? bestTimeToVisit;
  final List<String> photos;
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;
  final String? successMessage;

  AddLocationState copyWith({
    String? category,
    String? subcategory,
    String? description,
    String? coordinates,
    String? count,
    String? attractionName,
    String? operatingHours,
    String? hotelName,
    String? contact,
    String? bestTimeToVisit,
    List<String>? photos,
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    String? successMessage,
  }) {
    return AddLocationState(
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      coordinates: coordinates ?? this.coordinates,
      count: count ?? this.count,
      attractionName: attractionName ?? this.attractionName,
      operatingHours: operatingHours ?? this.operatingHours,
      hotelName: hotelName ?? this.hotelName,
      contact: contact ?? this.contact,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      photos: photos ?? this.photos,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        category,
        subcategory,
        description,
        coordinates,
        count,
        attractionName,
        operatingHours,
        hotelName,
        contact,
        bestTimeToVisit,
        photos,
        isSubmitting,
        isSuccess,
        error,
        successMessage,
      ];
}
