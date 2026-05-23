part of 'park_cubit.dart';

class ParkState extends Equatable {
  const ParkState({
    this.selectedPark,
    this.availableParks = const [],
    this.isLoading = false,
    this.error,
  });

  const ParkState.initial() : this();

  final ParkModel? selectedPark;
  final List<ParkModel> availableParks;
  final bool isLoading;
  final String? error;

  ParkState copyWith({
    ParkModel? selectedPark,
    List<ParkModel>? availableParks,
    bool? isLoading,
    String? error,
  }) {
    return ParkState(
      selectedPark: selectedPark ?? this.selectedPark,
      availableParks: availableParks ?? this.availableParks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [selectedPark, availableParks, isLoading, error];
}
