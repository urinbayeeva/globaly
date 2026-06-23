import '../../../../core/i18n/app_strings.dart';
import '../../domain/entities/home_snapshot.dart';

abstract class HomeLocalDataSource {
  HomeSnapshot snapshot({
    required String? userName,
    required String? destinationLabel,
    required String? destinationFlag,
    required String? purposeLabel,
    required String? purposeCode,
    required double? languageScore,
  });
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  HomeLocalDataSourceImpl();

  @override
  HomeSnapshot snapshot({
    required String? userName,
    required String? destinationLabel,
    required String? destinationFlag,
    required String? purposeLabel,
    required String? purposeCode,
    required double? languageScore,
  }) {
    final int hour = DateTime.now().hour;
    final String greeting;
    if (hour < 12) {
      greeting = T.t('greet.morning');
    } else if (hour < 18) {
      greeting = T.t('greet.afternoon');
    } else {
      greeting = T.t('greet.evening');
    }

    final bool hasCountry =
        destinationLabel != null && destinationLabel.isNotEmpty;
    final String combinedLabel = <String>[
      if (hasCountry) destinationLabel,
      if (purposeLabel != null && purposeLabel.isNotEmpty) purposeLabel,
    ].join(' · ');

    final bool hasScore = languageScore != null;
    final bool isSat = hasScore && languageScore >= 100;
    final double pct = hasScore ? _percentFromScore(languageScore, isSat) : 0;

    final String code = purposeCode ?? 'study';
    final String nbaTitle =
        _nbaTitleFor(code, hasCountry ? destinationLabel : '');

    return HomeSnapshot(
      greeting: greeting,
      userName: (userName == null) ? '' : userName.trim(),
      destinationLabel:
          combinedLabel.isEmpty ? T.t('greet.pickDestination') : combinedLabel,
      destinationFlag: destinationFlag ?? '',
      destinationCountryName: hasCountry ? destinationLabel : '',
      destinationSelected: hasCountry,
      purposeCode: code,
      scoreValue: pct,
      hasLanguageScore: hasScore,
      languageScoreIsSat: isSat,
      nbaStepLabel: T.t('home.nba.upNext'),
      nbaTitle: nbaTitle,
      nbaTimeEstimate: T.t('nba.timeEstimate'),
    );
  }

  String _nbaTitleFor(String purposeCode, String country) {
    final String where = country.isEmpty ? T.t('nba.fallbackPlace') : country;
    final String key;
    switch (purposeCode) {
      case 'work':
        key = 'nba.title.work';
        break;
      case 'tourism':
        key = 'nba.title.tourism';
        break;
      case 'business':
        key = 'nba.title.business';
        break;
      case 'family':
        key = 'nba.title.family';
        break;
      case 'study':
      default:
        key = 'nba.title.study';
    }
    return T.t(key).replaceAll('{0}', where);
  }

  double _percentFromScore(double raw, bool isSat) {
    final double pct;
    if (isSat) {
      pct = 50 + ((raw - 1000) / 600) * 49;
    } else {
      pct = 50 + (raw - 5) * 12;
    }
    return (pct.clamp(0, 99) / 100).toDouble();
  }
}
