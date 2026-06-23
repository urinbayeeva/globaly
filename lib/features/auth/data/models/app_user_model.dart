import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    super.name,
    super.isGuest,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> m) => AppUserModel(
        id: m['id'] as String? ?? '',
        email: m['email'] as String? ?? '',
        name: m['name'] as String?,
        isGuest: m['isGuest'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'email': email,
        'name': name,
        'isGuest': isGuest,
      };
}
