import 'package:equatable/equatable.dart';

class CityCost extends Equatable {
  const CityCost({
    required this.city,
    required this.country,
    required this.flag,
    required this.rentMonthly,
    required this.foodMonthly,
    required this.transportMonthly,
    required this.miscMonthly,
    this.currency = 'USD',
  });

  final String city;
  final String country;
  final String flag;
  final int rentMonthly;
  final int foodMonthly;
  final int transportMonthly;
  final int miscMonthly;
  final String currency;

  int get total => rentMonthly + foodMonthly + transportMonthly + miscMonthly;

  @override
  List<Object?> get props => <Object?>[
        city,
        country,
        flag,
        rentMonthly,
        foodMonthly,
        transportMonthly,
        miscMonthly,
        currency,
      ];
}
