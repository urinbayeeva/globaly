import 'package:equatable/equatable.dart';

class Hotel extends Equatable {
  const Hotel({
    required this.name,
    required this.city,
    required this.priceUsdPerNight,
    required this.stars,
    required this.rating,
    required this.summary,
    required this.bookingHint,
    required this.photoQuery,
  });

  final String name;
  final String city;

  final int priceUsdPerNight;

  final int stars;

  final double rating;
  final String summary;

  final String bookingHint;

  final String photoQuery;

  String get imageUrl {
    if (photoQuery.isEmpty) return '';
    final String q = Uri.encodeComponent(photoQuery);
    return 'https://source.unsplash.com/600x400/?$q';
  }

  @override
  List<Object?> get props => <Object?>[
        name,
        city,
        priceUsdPerNight,
        stars,
        rating,
        summary,
        bookingHint,
        photoQuery,
      ];
}
