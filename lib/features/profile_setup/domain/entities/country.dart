import 'package:equatable/equatable.dart';

class Country extends Equatable {
  const Country({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.region,
  });

  final String code;
  final String name;
  final String flagEmoji;
  final String region;

  @override
  List<Object?> get props => <Object?>[code, name, flagEmoji, region];
}
