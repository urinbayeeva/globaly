import 'package:equatable/equatable.dart';

class VisaInfo extends Equatable {
  const VisaInfo({
    required this.visaTypeName,
    required this.visaTypeCode,
    required this.processingWeeks,
    required this.applicationFeeUsd,
    required this.totalCostUsd,
    required this.notes,
  });

  final String visaTypeName;

  final String visaTypeCode;

  final int processingWeeks;

  final int applicationFeeUsd;

  final int totalCostUsd;

  final String notes;

  @override
  List<Object?> get props => <Object?>[
        visaTypeName,
        visaTypeCode,
        processingWeeks,
        applicationFeeUsd,
        totalCostUsd,
        notes,
      ];
}
