import '../domain/city_cost.dart';

class CityCostDb {
  CityCostDb();

  List<CityCost> all() => const <CityCost>[
        CityCost(
          city: 'Berlin',
          country: 'Germany',
          flag: '🇩🇪',
          rentMonthly: 950,
          foodMonthly: 280,
          transportMonthly: 60,
          miscMonthly: 220,
        ),
        CityCost(
          city: 'Munich',
          country: 'Germany',
          flag: '🇩🇪',
          rentMonthly: 1250,
          foodMonthly: 320,
          transportMonthly: 70,
          miscMonthly: 260,
        ),
        CityCost(
          city: 'Amsterdam',
          country: 'Netherlands',
          flag: '🇳🇱',
          rentMonthly: 1600,
          foodMonthly: 320,
          transportMonthly: 90,
          miscMonthly: 300,
        ),
        CityCost(
          city: 'Toronto',
          country: 'Canada',
          flag: '🇨🇦',
          rentMonthly: 1800,
          foodMonthly: 400,
          transportMonthly: 120,
          miscMonthly: 320,
        ),
        CityCost(
          city: 'New York',
          country: 'United States',
          flag: '🇺🇸',
          rentMonthly: 2900,
          foodMonthly: 500,
          transportMonthly: 130,
          miscMonthly: 400,
        ),
        CityCost(
          city: 'London',
          country: 'United Kingdom',
          flag: '🇬🇧',
          rentMonthly: 2300,
          foodMonthly: 380,
          transportMonthly: 200,
          miscMonthly: 380,
        ),
        CityCost(
          city: 'Seoul',
          country: 'South Korea',
          flag: '🇰🇷',
          rentMonthly: 700,
          foodMonthly: 350,
          transportMonthly: 50,
          miscMonthly: 260,
        ),
        CityCost(
          city: 'Dubai',
          country: 'UAE',
          flag: '🇦🇪',
          rentMonthly: 1500,
          foodMonthly: 380,
          transportMonthly: 80,
          miscMonthly: 320,
        ),
        CityCost(
          city: 'Istanbul',
          country: 'Türkiye',
          flag: '🇹🇷',
          rentMonthly: 500,
          foodMonthly: 220,
          transportMonthly: 40,
          miscMonthly: 180,
        ),
      ];
}
