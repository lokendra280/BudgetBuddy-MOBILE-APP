import 'package:budgetBuddy/features/voice_expense/models/presenter/voice_presenter.dart';
import 'package:budgetBuddy/features/voice_expense/models/voice_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeLangProvider = StateProvider<String>((ref) => 'en');

final voiceResultProvider = StateProvider<VoiceResult?>((ref) => null);

final voicePresenterProvider =
    StateNotifierProvider.autoDispose<VoicePresenter, VoiceState>(
      (ref) => VoicePresenter(ref),
    );
