import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/onboarding_local_datasource.dart';
import '../../domain/entities/onboarding_slide.dart';

class OnboardingState extends Equatable {
  const OnboardingState({required this.slides, required this.index});
  final List<OnboardingSlide> slides;
  final int index;

  bool get isLast => index == slides.length - 1;

  OnboardingState copyWith({int? index}) =>
      OnboardingState(slides: slides, index: index ?? this.index);

  @override
  List<Object?> get props => <Object?>[slides, index];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._ds)
      : super(OnboardingState(slides: _ds.getSlides(), index: 0));

  final OnboardingLocalDataSource _ds;

  void setIndex(int i) => emit(state.copyWith(index: i));

  Future<void> complete() async => _ds.markCompleted();
}
