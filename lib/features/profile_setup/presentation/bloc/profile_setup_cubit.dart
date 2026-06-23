import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/prefs.dart';
import '../../../profile/domain/repositories/user_profile_repository.dart';
import '../../data/datasources/countries_db.dart';
import '../../domain/entities/country.dart';
import '../../domain/entities/purpose.dart';

class ProfileSetupState extends Equatable {
  const ProfileSetupState({
    required this.countries,
    this.query = '',
    this.selectedCountry,
    this.selectedPurpose,
  });

  final List<Country> countries;
  final String query;
  final Country? selectedCountry;
  final Purpose? selectedPurpose;

  List<Country> get filtered {
    if (query.trim().isEmpty) return countries;
    final String q = query.toLowerCase();
    return countries
        .where(
          (Country c) =>
              c.name.toLowerCase().contains(q) ||
              c.code.toLowerCase().contains(q),
        )
        .toList();
  }

  ProfileSetupState copyWith({
    List<Country>? countries,
    String? query,
    Country? selectedCountry,
    Purpose? selectedPurpose,
  }) =>
      ProfileSetupState(
        countries: countries ?? this.countries,
        query: query ?? this.query,
        selectedCountry: selectedCountry ?? this.selectedCountry,
        selectedPurpose: selectedPurpose ?? this.selectedPurpose,
      );

  @override
  List<Object?> get props =>
      <Object?>[countries, query, selectedCountry, selectedPurpose];
}

class ProfileSetupCubit extends Cubit<ProfileSetupState> {
  ProfileSetupCubit(this._prefs, CountriesDb db, this._profile)
      : super(ProfileSetupState(countries: db.all()));

  final Prefs _prefs;
  final UserProfileRepository _profile;

  void search(String q) => emit(state.copyWith(query: q));

  void selectCountry(Country c) {
    emit(state.copyWith(selectedCountry: c));

    _prefs.setString(Prefs.kDestinationCountry, c.code);

    _profile.saveDestinationCountry(c.code);
  }

  void selectPurpose(Purpose p) {
    emit(state.copyWith(selectedPurpose: p));
    _prefs.setString(Prefs.kPurpose, p.code);
  }
}
