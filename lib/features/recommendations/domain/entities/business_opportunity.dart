import 'package:equatable/equatable.dart';

class BusinessOpportunity extends Equatable {
  const BusinessOpportunity({
    required this.city,
    required this.region,
    required this.lat,
    required this.lng,
    required this.summary,
    required this.ideas,
    required this.demandLevel,
  });

  final String city;
  final String region;
  final double lat;
  final double lng;

  final String summary;

  final List<String> ideas;

  final String demandLevel;

  @override
  List<Object?> get props =>
      <Object?>[city, region, lat, lng, summary, ideas, demandLevel];
}
