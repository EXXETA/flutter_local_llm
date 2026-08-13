import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/model_constants.dart';
import 'generation_event.dart';
import 'generation_state.dart';

class GenerationBloc extends Bloc<GenerationEvent, GenerationState> {
  GenerationBloc() : super(const GenerationState()) {
    on<GenerationInputChanged>(_onInputChanged);
    on<GenerationQuickFillSelected>(_onQuickFill);
    on<GenerationMoodChanged>(_onMoodChanged);
    on<GenerationRewriteRequested>(_onRewrite);
    on<GenerationSummarizeRequested>(_onSummarize);
  }

  void _onInputChanged(
    GenerationInputChanged event,
    Emitter<GenerationState> emit,
  ) {
    emit(state.copyWith(inputText: event.text));
  }

  void _onQuickFill(
    GenerationQuickFillSelected event,
    Emitter<GenerationState> emit,
  ) {
    emit(state.copyWith(inputText: event.text));
  }

  void _onMoodChanged(
    GenerationMoodChanged event,
    Emitter<GenerationState> emit,
  ) {
    emit(state.copyWith(selectedMood: event.mood));
  }

  Future<void> _onRewrite(
    GenerationRewriteRequested event,
    Emitter<GenerationState> emit,
  ) async {
    if (!state.hasInput) return;
    emit(
      state.copyWith(
        status: GenerationStatus.loading,
        output: '',
        errorMessage: null,
      ),
    );
    final prompt =
        'You are a professional writing assistant. Rewrite the following text '
        'to sound highly ${event.mood.label.toLowerCase()}. Maintain all '
        'critical data facts, numbers, dates, names, and contact details '
        'exactly as written. Do not omit them.\n\n'
        'Text to rewrite:\n${state.inputText}';
    await _runModel(prompt, emit);
  }

  Future<void> _onSummarize(
    GenerationSummarizeRequested event,
    Emitter<GenerationState> emit,
  ) async {
    if (!state.hasInput) return;
    emit(
      state.copyWith(
        status: GenerationStatus.loading,
        output: '',
        errorMessage: null,
      ),
    );
    await _runModel('Summarize the following text:\n${state.inputText}', emit);
  }

  Future<void> _runModel(String prompt, Emitter<GenerationState> emit) async {
    try {
      final model = await FlutterGemma.getActiveModel(
        maxTokens: ModelConstants.maxTokens,
      );
      try {
        final chat = await model.createChat();
        await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
        final response = await chat.generateChatResponse();
        final text = response is TextResponse ? response.token : '';
        emit(state.copyWith(status: GenerationStatus.success, output: text));
      } finally {
        await model.close();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: GenerationStatus.error,
          errorMessage: 'Failed to run model: $e',
        ),
      );
    }
  }
}
