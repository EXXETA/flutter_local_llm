import 'package:equatable/equatable.dart';

import '../../../shared/models/ai_mood.dart';

abstract class GenerationEvent extends Equatable {
  const GenerationEvent();

  @override
  List<Object?> get props => [];
}

class GenerationInputChanged extends GenerationEvent {
  const GenerationInputChanged(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

class GenerationQuickFillSelected extends GenerationEvent {
  const GenerationQuickFillSelected(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

class GenerationRewriteRequested extends GenerationEvent {
  const GenerationRewriteRequested(this.mood);

  final AiMood mood;

  @override
  List<Object?> get props => [mood];
}

class GenerationSummarizeRequested extends GenerationEvent {
  const GenerationSummarizeRequested();
}

class GenerationMoodChanged extends GenerationEvent {
  const GenerationMoodChanged(this.mood);

  final AiMood mood;

  @override
  List<Object?> get props => [mood];
}
