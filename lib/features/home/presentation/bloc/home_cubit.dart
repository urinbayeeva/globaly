import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/prefs.dart';
import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../domain/entities/home_snapshot.dart';
import '../../domain/repositories/home_repository.dart';

class HomeState extends Equatable {
  const HomeState({this.snapshot, this.loading = false});
  final HomeSnapshot? snapshot;
  final bool loading;

  HomeState copyWith({HomeSnapshot? snapshot, bool? loading}) => HomeState(
        snapshot: snapshot ?? this.snapshot,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => <Object?>[snapshot, loading];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repo, this._prefs) : super(const HomeState());

  final HomeRepository _repo;
  final Prefs _prefs;

  Prefs get prefs => _prefs;

  void load({String? userName}) {
    emit(state.copyWith(loading: true));
    final String? destCode = _prefs.getString(Prefs.kDestinationCountry);
    final Country? country =
        destCode == null ? null : CountriesDb().byCode(destCode);
    final Purpose purpose = Purpose.fromCode(
      _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code,
    );

    final double? lang = _prefs.getDouble(Prefs.kLanguageScore);
    final HomeSnapshot snap = _repo.loadSnapshot(
      userName: userName,
      destinationLabel: country?.name,
      destinationFlag: country?.flagEmoji,
      purposeLabel: purpose.label,
      purposeCode: purpose.code,
      languageScore: lang,
    );
    emit(HomeState(snapshot: snap));
  }
}
