import 'package:equatable/equatable.dart';

class University extends Equatable {
  const University({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.stateProvince,
    required this.domain,
    required this.websiteUrl,
    required this.imageUrl,
    required this.logoUrl,
    required this.about,
  });

  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String flag;
  final String stateProvince;
  final String domain;
  final String websiteUrl;
  final String imageUrl;
  final String logoUrl;
  final String about;

  University copyWith({
    String? imageUrl,
    String? logoUrl,
    String? about,
  }) =>
      University(
        id: id,
        name: name,
        country: country,
        countryCode: countryCode,
        flag: flag,
        stateProvince: stateProvince,
        domain: domain,
        websiteUrl: websiteUrl,
        imageUrl: imageUrl ?? this.imageUrl,
        logoUrl: logoUrl ?? this.logoUrl,
        about: about ?? this.about,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        country,
        countryCode,
        flag,
        stateProvince,
        domain,
        websiteUrl,
        imageUrl,
        logoUrl,
        about,
      ];
}
