import 'package:flutter/material.dart';

import '../../../profile_setup/data/datasources/countries_db.dart';
import '../../../profile_setup/domain/entities/country.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../../recommendations/domain/entities/document_brief.dart';
import '../../../recommendations/domain/repositories/recommendations_repository.dart';
import '../../domain/entities/document_template.dart';
import '../../domain/repositories/documents_repository.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  DocumentsRepositoryImpl(this._recs, this._countries);

  final RecommendationsRepository _recs;
  final CountriesDb _countries;

  @override
  Future<List<DocumentTemplate>> requiredDocuments({
    required String origin,
    required String destination,
    required Purpose purpose,
  }) async {
    final Country? originCountry = _countries.byCode(origin);
    final Country? destinationCountry = _countries.byCode(destination);
    final String destName = destinationCountry?.name ?? destination;
    final String originName = originCountry?.name ?? origin;

    final List<DocumentBrief> briefs = await _recs.documents(
      country: destName,
      purposeCode: purpose.code,
      originCountry: originName,
    );
    return briefs.map(_fromBrief).toList();
  }

  DocumentTemplate _fromBrief(DocumentBrief b) => DocumentTemplate(
        id: b.id.isEmpty ? b.title.toLowerCase().replaceAll(' ', '_') : b.id,
        title: b.title,
        issuer: b.issuer,
        icon: _iconFor(b.iconHint),
        status: _statusFor(b.statusCode),
        description: b.description,
        validityYears: b.validityYears == 0 ? null : b.validityYears,
        notes: b.notes,
      );

  DocumentStatus _statusFor(String code) {
    switch (code) {
      case 'recommended':
        return DocumentStatus.recommended;
      case 'optional':
        return DocumentStatus.optional;
      case 'required':
      default:
        return DocumentStatus.required;
    }
  }

  IconData _iconFor(String hint) {
    switch (hint) {
      case 'passport':
        return Icons.book_rounded;
      case 'id':
        return Icons.badge_outlined;
      case 'visa':
        return Icons.confirmation_number_outlined;
      case 'diploma':
        return Icons.school_outlined;
      case 'transcript':
        return Icons.description_outlined;
      case 'language':
        return Icons.translate_rounded;
      case 'motivation':
        return Icons.edit_note_rounded;
      case 'finance':
        return Icons.account_balance_outlined;
      case 'cv':
        return Icons.assignment_ind_outlined;
      case 'contract':
        return Icons.handshake_outlined;
      case 'criminal':
        return Icons.gavel_outlined;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'business_plan':
        return Icons.lightbulb_outline_rounded;
      case 'translate':
        return Icons.g_translate_outlined;
      case 'other':
      default:
        return Icons.article_outlined;
    }
  }
}
