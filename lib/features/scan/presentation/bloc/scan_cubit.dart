import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/i18n/app_strings.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/gemini_contract_analyzer.dart';
import '../../domain/entities/scan_analysis.dart';

enum ScanStatus { idle, scanning, analyzing, success, error }

enum AnalysisPhase { reading, detecting, drafting }

class ScanState extends Equatable {
  const ScanState({
    this.status = ScanStatus.idle,
    this.pages = const <String>[],
    this.analysis,
    this.message,
    this.phase = AnalysisPhase.reading,
  });

  final ScanStatus status;
  final List<String> pages;
  final ScanAnalysis? analysis;
  final String? message;
  final AnalysisPhase phase;

  ScanState copyWith({
    ScanStatus? status,
    List<String>? pages,
    ScanAnalysis? analysis,
    Object? message = _sentinel,
    AnalysisPhase? phase,
  }) =>
      ScanState(
        status: status ?? this.status,
        pages: pages ?? this.pages,
        analysis: analysis ?? this.analysis,
        message:
            identical(message, _sentinel) ? this.message : message as String?,
        phase: phase ?? this.phase,
      );

  @override
  List<Object?> get props => <Object?>[status, pages, analysis, message, phase];
}

const Object _sentinel = Object();

class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._analyzer) : super(const ScanState());

  final GeminiContractAnalyzer _analyzer;
  final ImagePicker _picker = ImagePicker();

  Future<void> capturePage() => _pickAndAnalyse(ImageSource.camera);
  Future<void> addFromGallery() => _pickAndAnalyse(ImageSource.gallery);

  Future<void> _pickAndAnalyse(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (file == null) return;
      emit(
        state.copyWith(
          status: ScanStatus.scanning,
          pages: <String>[file.path],
          message: null,
        ),
      );
      await _runAnalysis(File(file.path));
    } catch (e, st) {
      appLogger.e('scan capture failed', error: e, stackTrace: st);
      emit(
        state.copyWith(
          status: ScanStatus.error,
          message: T.t('scan.permissionError'),
        ),
      );
    }
  }

  Future<void> _runAnalysis(File image) async {
    emit(
      state.copyWith(
        status: ScanStatus.analyzing,
        phase: AnalysisPhase.reading,
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (isClosed || state.status != ScanStatus.analyzing) return;
      emit(state.copyWith(phase: AnalysisPhase.detecting));
    });
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (isClosed || state.status != ScanStatus.analyzing) return;
      emit(state.copyWith(phase: AnalysisPhase.drafting));
    });

    try {
      final ScanAnalysis analysis = await _analyzer.analyze(image);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ScanStatus.success,
          analysis: analysis,
        ),
      );
    } catch (e, st) {
      appLogger.e('scan analyse failed', error: e, stackTrace: st);
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ScanStatus.error,
          message: T.t('scan.error'),
        ),
      );
    }
  }

  void reset() => emit(const ScanState());
}
