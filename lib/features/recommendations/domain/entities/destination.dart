import 'package:equatable/equatable.dart';

class Destination extends Equatable {
  const Destination({
    required this.name,
    required this.region,
    required this.summary,
    required this.bestSeason,
  });

  final String name;
  final String region;
  final String summary;

  final String bestSeason;

  @override
  List<Object?> get props => <Object?>[name, region, summary, bestSeason];
}
