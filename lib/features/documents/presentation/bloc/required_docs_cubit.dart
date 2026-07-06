import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/storage/prefs.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../profile_setup/domain/entities/purpose.dart';
import '../../domain/entities/document_template.dart';
import '../../domain/repositories/documents_repository.dart';

enum DocsStatus { idle, loading, success, error }

class RequiredDocsState extends Equatable {
  const RequiredDocsState({
    this.status = DocsStatus.idle,
    this.origin,
    this.destination,
    this.purpose,
    this.docs = const <DocumentTemplate>[],
    this.error,
  });

  final DocsStatus status;
  final String? origin;
  final String? destination;
  final Purpose? purpose;
  final List<DocumentTemplate> docs;
  final String? error;

  RequiredDocsState copyWith({
    DocsStatus? status,
    String? origin,
    String? destination,
    Purpose? purpose,
    List<DocumentTemplate>? docs,
    String? error,
  }) =>
      RequiredDocsState(
        status: status ?? this.status,
        origin: origin ?? this.origin,
        destination: destination ?? this.destination,
        purpose: purpose ?? this.purpose,
        docs: docs ?? this.docs,
        error: error,
      );

  @override
  List<Object?> get props =>
      <Object?>[status, origin, destination, purpose, docs, error];
}

class RequiredDocsCubit extends Cubit<RequiredDocsState> {
  RequiredDocsCubit(this._repo, this._location, this._prefs)
      : super(const RequiredDocsState());

  final DocumentsRepository _repo;
  final LocationService _location;
  final Prefs _prefs;

  bool _loadedOnce = false;

  Future<void> load({bool force = false}) async {
    if (_loadedOnce && !force) return;
    _loadedOnce = true;
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final String origin = await _location.getOriginCountry();
      final String destination =
          _prefs.getString(Prefs.kDestinationCountry) ?? 'DE';
      final Purpose purpose = Purpose.fromCode(
        _prefs.getString(Prefs.kPurpose) ?? Purpose.study.code,
      );

      emit(
        state.copyWith(
          status: DocsStatus.loading,
          origin: origin,
          destination: destination,
          purpose: purpose,
          docs: const <DocumentTemplate>[],
        ),
      );

      final List<DocumentTemplate> docs = await _repo.requiredDocuments(
        origin: origin,
        destination: destination,
        purpose: purpose,
      );

      appLogger.i('📑 Docs $origin → $destination (${purpose.label}): '
          '${docs.length} items');

      if (isClosed) return;
      if (docs.isEmpty) {
        emit(
          state.copyWith(
            status: DocsStatus.error,
            error: T.t('docs.error'),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: DocsStatus.success,
          origin: origin,
          destination: destination,
          purpose: purpose,
          docs: docs,
        ),
      );
    } catch (e, st) {
      appLogger.e('Docs load failed', error: e, stackTrace: st);
      if (isClosed) return;
      emit(state.copyWith(status: DocsStatus.error, error: e.toString()));
    }
  }
}
