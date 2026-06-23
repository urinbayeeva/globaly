import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/visa_info.dart';
import '../../domain/repositories/recommendations_repository.dart';

class VisaInfoState extends Equatable {
  const VisaInfoState({
    this.country = '',
    this.purposeCode = '',
    this.info,
    this.loading = false,
  });

  final String country;
  final String purposeCode;
  final VisaInfo? info;
  final bool loading;

  @override
  List<Object?> get props => <Object?>[country, purposeCode, info, loading];
}

class VisaInfoCubit extends Cubit<VisaInfoState> {
  VisaInfoCubit(this._repo) : super(const VisaInfoState());

  final RecommendationsRepository _repo;

  Future<void> load({
    required String country,
    required String purposeCode,
  }) async {
    if (country.isEmpty) return;
    if (state.country == country &&
        state.purposeCode == purposeCode &&
        (state.info != null || state.loading)) {
      return;
    }
    emit(
      VisaInfoState(
        country: country,
        purposeCode: purposeCode,
        loading: true,
      ),
    );
    final VisaInfo? info = await _repo.visaInfo(
      country: country,
      purposeCode: purposeCode,
    );
    if (isClosed) return;
    emit(
      VisaInfoState(
        country: country,
        purposeCode: purposeCode,
        info: info,
      ),
    );
  }
}
