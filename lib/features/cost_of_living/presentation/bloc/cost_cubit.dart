import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/city_cost.dart';
import '../../domain/cost_repository.dart';

class CostState extends Equatable {
  const CostState({
    this.country = '',
    this.cities = const <CityCost>[],
    this.loading = false,
    this.error,
  });

  final String country;
  final List<CityCost> cities;
  final bool loading;
  final String? error;

  CostState copyWith({
    String? country,
    List<CityCost>? cities,
    bool? loading,
    Object? error = _sentinel,
  }) =>
      CostState(
        country: country ?? this.country,
        cities: cities ?? this.cities,
        loading: loading ?? this.loading,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  @override
  List<Object?> get props => <Object?>[country, cities, loading, error];
}

const Object _sentinel = Object();

class CostCubit extends Cubit<CostState> {
  CostCubit(this._repo) : super(const CostState());

  final CostRepository _repo;

  Future<void> load({required String country, required String flag}) async {
    if (country.isEmpty) {
      emit(const CostState(error: 'Pick a destination country first'));
      return;
    }
    if (state.country == country &&
        (state.cities.isNotEmpty || state.loading)) {
      return;
    }

    emit(CostState(country: country, loading: true));
    try {
      final List<CityCost> cities =
          await _repo.forCountry(country: country, flag: flag);
      if (isClosed || state.country != country) return;
      final List<CityCost> sorted = List<CityCost>.of(cities)
        ..sort((CityCost a, CityCost b) => a.total.compareTo(b.total));
      emit(
        state.copyWith(
          cities: sorted,
          loading: false,
          error: sorted.isEmpty ? 'No cost data for $country yet.' : null,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          error: 'Could not load cost of living right now.',
        ),
      );
    }
  }
}
