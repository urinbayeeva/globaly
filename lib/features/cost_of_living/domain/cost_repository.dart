import 'city_cost.dart';

abstract class CostRepository {
  Future<List<CityCost>> forCountry({
    required String country,
    required String flag,
  });
}
