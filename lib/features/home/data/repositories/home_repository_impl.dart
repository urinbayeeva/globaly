import '../../domain/entities/home_snapshot.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_local_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._ds);
  final HomeLocalDataSource _ds;

  @override
  HomeSnapshot loadSnapshot({
    required String? userName,
    required String? destinationLabel,
    required String? destinationFlag,
    required String? purposeLabel,
    required String? purposeCode,
    required double? languageScore,
  }) =>
      _ds.snapshot(
        userName: userName,
        destinationLabel: destinationLabel,
        destinationFlag: destinationFlag,
        purposeLabel: purposeLabel,
        purposeCode: purposeCode,
        languageScore: languageScore,
      );
}
