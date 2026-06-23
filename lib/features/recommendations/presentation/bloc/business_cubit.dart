import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/business_opportunity.dart';
import '../../domain/repositories/recommendations_repository.dart';

class BusinessState extends Equatable {
  const BusinessState({
    this.country = '',
    this.items = const <BusinessOpportunity>[],
    this.loading = false,
    this.error,
    this.selectedIndex,
  });

  final String country;
  final List<BusinessOpportunity> items;
  final bool loading;
  final String? error;
  final int? selectedIndex;

  BusinessState copyWith({
    String? country,
    List<BusinessOpportunity>? items,
    bool? loading,
    Object? error = _sentinel,
    Object? selectedIndex = _sentinel,
  }) =>
      BusinessState(
        country: country ?? this.country,
        items: items ?? this.items,
        loading: loading ?? this.loading,
        error: identical(error, _sentinel) ? this.error : error as String?,
        selectedIndex: identical(selectedIndex, _sentinel)
            ? this.selectedIndex
            : selectedIndex as int?,
      );

  @override
  List<Object?> get props =>
      <Object?>[country, items, loading, error, selectedIndex];
}

const Object _sentinel = Object();

class BusinessCubit extends Cubit<BusinessState> {
  BusinessCubit(this._repo) : super(const BusinessState());

  final RecommendationsRepository _repo;

  void load(String country) {
    if (country.isEmpty) {
      emit(
        state.copyWith(
          country: '',
          items: const <BusinessOpportunity>[],
          loading: false,
          error: 'Pick a destination country first',
        ),
      );
      return;
    }
    if (state.country == country && (state.items.isNotEmpty || state.loading)) {
      return;
    }
    emit(BusinessState(country: country, loading: true));
    _fetch(country);
  }

  Future<void> _fetch(String country) async {
    try {
      final List<BusinessOpportunity> list =
          await _repo.businessOpportunities(country);
      if (isClosed || state.country != country) return;
      emit(
        state.copyWith(
          items: list,
          loading: false,
          error: list.isEmpty
              ? 'No business opportunities returned for $country.'
              : null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          loading: false,
          error: 'Could not load business ideas right now.',
        ),
      );
    }
  }

  void select(int? index) => emit(state.copyWith(selectedIndex: index));
}
