abstract class UserProfileRepository {
  Future<void> saveIelts(double value);

  Future<void> saveSat(int value);

  Future<void> saveEducationLevel(String code);

  Future<void> saveFieldOfStudy(String label);

  Future<void> saveDestinationCountry(String code);
}
