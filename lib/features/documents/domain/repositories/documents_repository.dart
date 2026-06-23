import '../../../profile_setup/domain/entities/purpose.dart';
import '../entities/document_template.dart';

abstract class DocumentsRepository {
  Future<List<DocumentTemplate>> requiredDocuments({
    required String origin,
    required String destination,
    required Purpose purpose,
  });

  List<DocumentTemplate> fallback({
    required String origin,
    required String destination,
    required Purpose purpose,
  });
}
