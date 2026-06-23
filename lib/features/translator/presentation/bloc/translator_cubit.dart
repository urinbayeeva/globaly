import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/document_translator.dart';
import '../../domain/entities/translation_result.dart';

enum TranslateStatus { idle, translating, success, error }

class TranslatorState extends Equatable {
  const TranslatorState({
    this.status = TranslateStatus.idle,
    this.imagePath,
    this.result,
    this.message,
  });

  final TranslateStatus status;
  final String? imagePath;
  final TranslationResult? result;
  final String? message;

  TranslatorState copyWith({
    TranslateStatus? status,
    String? imagePath,
    TranslationResult? result,
    Object? message = _sentinel,
  }) =>
      TranslatorState(
        status: status ?? this.status,
        imagePath: imagePath ?? this.imagePath,
        result: result ?? this.result,
        message:
            identical(message, _sentinel) ? this.message : message as String?,
      );

  @override
  List<Object?> get props => <Object?>[status, imagePath, result, message];
}

const Object _sentinel = Object();

class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit(this._translator) : super(const TranslatorState());

  final DocumentTranslator _translator;
  final ImagePicker _picker = ImagePicker();

  Future<void> capture() => _pickAndTranslate(ImageSource.camera);
  Future<void> pickFromGallery() => _pickAndTranslate(ImageSource.gallery);

  Future<void> _pickAndTranslate(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (file == null) return;
      emit(
        TranslatorState(
          status: TranslateStatus.translating,
          imagePath: file.path,
        ),
      );
      final TranslationResult result = _translator.isConfigured
          ? await _translator.translate(File(file.path))
          : translatorOfflineFallback();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TranslateStatus.success,
          result: result,
        ),
      );
    } catch (e, st) {
      appLogger.e('translate failed', error: e, stackTrace: st);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TranslateStatus.error,
          message: T.t('translator.error'),
        ),
      );
    }
  }

  void reset() => emit(const TranslatorState());
}
