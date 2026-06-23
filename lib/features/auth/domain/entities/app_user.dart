import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.isGuest = false,
  });

  final String id;
  final String email;
  final String? name;
  final bool isGuest;

  factory AppUser.guest() => const AppUser(
        id: 'guest',
        email: 'guest@globaly.app',
        name: 'Guest',
        isGuest: true,
      );

  @override
  List<Object?> get props => <Object?>[id, email, name, isGuest];
}
