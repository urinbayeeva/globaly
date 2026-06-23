import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/destination.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/repositories/recommendations_repository.dart';

class TravelState extends Equatable {
  const TravelState({
    this.country = '',
    this.destinations = const <Destination>[],
    this.hotels = const <Hotel>[],
    this.loadingDestinations = false,
    this.loadingHotels = false,
    this.error,
  });

  final String country;
  final List<Destination> destinations;
  final List<Hotel> hotels;
  final bool loadingDestinations;
  final bool loadingHotels;
  final String? error;

  TravelState copyWith({
    String? country,
    List<Destination>? destinations,
    List<Hotel>? hotels,
    bool? loadingDestinations,
    bool? loadingHotels,
    Object? error = _sentinel,
  }) =>
      TravelState(
        country: country ?? this.country,
        destinations: destinations ?? this.destinations,
        hotels: hotels ?? this.hotels,
        loadingDestinations: loadingDestinations ?? this.loadingDestinations,
        loadingHotels: loadingHotels ?? this.loadingHotels,
        error: identical(error, _sentinel) ? this.error : error as String?,
      );

  @override
  List<Object?> get props => <Object?>[
        country,
        destinations,
        hotels,
        loadingDestinations,
        loadingHotels,
        error,
      ];
}

const Object _sentinel = Object();

class TravelCubit extends Cubit<TravelState> {
  TravelCubit(this._repo) : super(const TravelState());

  final RecommendationsRepository _repo;

  void load(String country) {
    if (state.country == country &&
        (state.destinations.isNotEmpty || state.loadingDestinations)) {
      return;
    }
    emit(
      TravelState(
        country: country,
        loadingDestinations: true,
        loadingHotels: true,
      ),
    );
    _fetchDestinations(country);
    _fetchHotels(country);
  }

  Future<void> _fetchDestinations(String country) async {
    try {
      final List<Destination> list = await _repo.destinations(country);
      if (isClosed || state.country != country) return;
      emit(state.copyWith(destinations: list, loadingDestinations: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loadingDestinations: false));
    }
  }

  Future<void> _fetchHotels(String country) async {
    try {
      final List<Hotel> list = await _repo.hotels(country);
      if (isClosed || state.country != country) return;
      emit(state.copyWith(hotels: list, loadingHotels: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loadingHotels: false));
    }
  }
}
