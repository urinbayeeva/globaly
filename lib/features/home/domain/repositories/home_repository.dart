import '../entities/home_snapshot.dart';

abstract class HomeRepository {
  HomeSnapshot loadSnapshot({
    required String? userName,
    required String? destinationLabel,
    required String? destinationFlag,
    required String? purposeLabel,
    required String? purposeCode,
    required double? languageScore,
  });
}
