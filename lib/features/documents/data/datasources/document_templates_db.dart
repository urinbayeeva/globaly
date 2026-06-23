import 'package:flutter/material.dart';

import '../../../profile_setup/domain/entities/purpose.dart';
import '../../domain/entities/document_template.dart';

class DocumentTemplatesDb {
  DocumentTemplatesDb();

  List<DocumentTemplate> templatesFor({
    required String originCode,
    required String destinationCode,
    required Purpose purpose,
  }) {
    final List<DocumentTemplate> docs = <DocumentTemplate>[
      _passport(originCode),
      _nationalId(originCode),
    ];

    if (purpose == Purpose.study) {
      docs.addAll(<DocumentTemplate>[
        _diploma(),
        _transcript(),
        _languageCertificate(destinationCode),
        _motivationLetter(),
        _financialProof(),
      ]);
    } else if (purpose == Purpose.work) {
      docs.addAll(<DocumentTemplate>[
        _cv(),
        _diploma(),
        _employmentContract(),
        _criminalRecord(),
      ]);
    } else if (purpose == Purpose.family) {
      docs.addAll(<DocumentTemplate>[
        _marriageOrBirth(),
        _financialProof(),
      ]);
    } else if (purpose == Purpose.business) {
      docs.addAll(<DocumentTemplate>[
        _businessPlan(),
        _financialProof(),
      ]);
    }

    docs.add(_visa(destinationCode, purpose));
    return docs;
  }

  DocumentTemplate _passport(String origin) => DocumentTemplate(
        id: 'passport',
        title: _passportTitle(origin),
        issuer: _passportIssuer(origin),
        icon: Icons.book_rounded,
        status: DocumentStatus.required,
        validityYears: 10,
        extendable: true,
        notes: const <String>[
          'Must be valid 6 months past intended departure.',
          'Renewal via your country\'s consulate or e-services.',
        ],
      );

  String _passportTitle(String origin) {
    switch (origin) {
      case 'UZ':
        return 'Uzbek international passport';
      case 'RU':
        return 'Russian Federation passport';
      case 'KZ':
        return 'Kazakh international passport';
      case 'KG':
        return 'Kyrgyz international passport';
      case 'TJ':
        return 'Tajik international passport';
      default:
        return 'International passport';
    }
  }

  String _passportIssuer(String origin) {
    switch (origin) {
      case 'UZ':
        return 'IIB / e-passport.gov.uz';
      case 'RU':
        return 'МВД РФ';
      case 'KZ':
        return 'eGov.kz';
      default:
        return 'Local government';
    }
  }

  DocumentTemplate _nationalId(String origin) => DocumentTemplate(
        id: 'id',
        title: _idTitle(origin),
        issuer: 'Civil registry',
        icon: Icons.badge_outlined,
        status: DocumentStatus.recommended,
        validityYears: 10,
        extendable: true,
        notes: const <String>[
          'Keep an original + a notarised copy.',
        ],
      );
  String _idTitle(String origin) {
    switch (origin) {
      case 'UZ':
        return 'Uzbek ID-card';
      case 'RU':
        return 'Internal passport';
      case 'KZ':
        return 'Kazakh ID-card';
      default:
        return 'National ID';
    }
  }

  DocumentTemplate _diploma() => const DocumentTemplate(
        id: 'diploma',
        title: 'Diploma + supplement',
        issuer: 'University',
        icon: Icons.school_outlined,
        status: DocumentStatus.required,
        convertibleTo: 'WES / IQAS evaluation',
        notes: <String>[
          'Apostille or legalise before submitting.',
          'Some destinations require credential evaluation (WES, IQAS).',
        ],
      );

  DocumentTemplate _transcript() => const DocumentTemplate(
        id: 'transcript',
        title: 'Official transcript',
        issuer: 'University',
        icon: Icons.description_outlined,
        status: DocumentStatus.required,
        notes: <String>['Sealed envelope strongly preferred.'],
      );

  DocumentTemplate _languageCertificate(String dest) {
    final bool english = !<String>['DE', 'FR', 'JP', 'KR', 'CN'].contains(dest);
    return DocumentTemplate(
      id: 'language',
      title: english ? 'IELTS / TOEFL' : 'Local language test',
      issuer: english ? 'British Council / ETS' : 'Local authority',
      icon: Icons.translate_rounded,
      status: DocumentStatus.required,
      validityYears: 2,
      notes: const <String>[
        'Valid two years from test date.',
      ],
    );
  }

  DocumentTemplate _motivationLetter() => const DocumentTemplate(
        id: 'motivation',
        title: 'Motivation letter',
        issuer: 'You',
        icon: Icons.edit_note_rounded,
        status: DocumentStatus.required,
      );

  DocumentTemplate _financialProof() => const DocumentTemplate(
        id: 'finance',
        title: 'Proof of funds',
        issuer: 'Bank',
        icon: Icons.account_balance_outlined,
        status: DocumentStatus.required,
        notes: <String>[
          'Statements from the last 3 months in most cases.',
          'Germany requires a blocked account; UK, US — sponsor letter or balance.',
        ],
      );

  DocumentTemplate _cv() => const DocumentTemplate(
        id: 'cv',
        title: 'CV / résumé',
        issuer: 'You',
        icon: Icons.assignment_ind_outlined,
        status: DocumentStatus.required,
      );

  DocumentTemplate _employmentContract() => const DocumentTemplate(
        id: 'contract',
        title: 'Employment contract',
        issuer: 'Employer',
        icon: Icons.handshake_outlined,
        status: DocumentStatus.required,
        notes: <String>[
          'Have Globaly scan it before signing.',
        ],
      );

  DocumentTemplate _criminalRecord() => const DocumentTemplate(
        id: 'criminal',
        title: 'Criminal record certificate',
        issuer: 'Police',
        icon: Icons.gavel_outlined,
        status: DocumentStatus.required,
        validityYears: 1,
      );

  DocumentTemplate _marriageOrBirth() => const DocumentTemplate(
        id: 'civil',
        title: 'Marriage / birth certificate',
        issuer: 'Civil registry',
        icon: Icons.family_restroom_rounded,
        status: DocumentStatus.required,
      );

  DocumentTemplate _businessPlan() => const DocumentTemplate(
        id: 'business_plan',
        title: 'Business plan',
        issuer: 'You',
        icon: Icons.lightbulb_outline_rounded,
        status: DocumentStatus.required,
      );

  DocumentTemplate _visa(String dest, Purpose p) => DocumentTemplate(
        id: 'visa',
        title: '${_visaPrefix(p)} visa to $dest',
        issuer: 'Embassy / VFS',
        icon: Icons.confirmation_number_outlined,
        status: DocumentStatus.required,
        notes: const <String>[
          'Apply only after collecting all supporting documents.',
        ],
      );
  String _visaPrefix(Purpose p) {
    switch (p) {
      case Purpose.study:
        return 'Study';
      case Purpose.work:
        return 'Work';
      case Purpose.family:
        return 'Family';
      case Purpose.tourism:
        return 'Tourist';
      case Purpose.business:
        return 'Business';
    }
  }
}
