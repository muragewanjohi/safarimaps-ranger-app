import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/park_model.dart';
import '../../../data/repositories/park_repository.dart';

part 'park_state.dart';

class ParkCubit extends Cubit<ParkState> {
  ParkCubit(this._parkRepository) : super(const ParkState.initial()) {
    loadParks();
  }

  final ParkRepository _parkRepository;

  Future<void> loadParks() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final parks = await _parkRepository.getParks();
      emit(state.copyWith(
        isLoading: false,
        availableParks: parks,
        selectedPark: state.selectedPark ?? (parks.isNotEmpty ? parks.first : null),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectPark(ParkModel park) {
    emit(state.copyWith(selectedPark: park));
  }
}
