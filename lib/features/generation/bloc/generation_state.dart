import 'package:equatable/equatable.dart';

import '../../../shared/models/ai_mood.dart';

enum GenerationStatus { idle, loading, success, error }

class GenerationState extends Equatable {
  const GenerationState({
    this.inputText = '',
    this.selectedMood = AiMood.professional,
    this.status = GenerationStatus.idle,
    this.output = '',
    this.errorMessage,
  });

  final String inputText;
  final AiMood selectedMood;
  final GenerationStatus status;
  final String output;
  final String? errorMessage;

  bool get isLoading => status == GenerationStatus.loading;
  bool get hasInput => inputText.trim().isNotEmpty;

  GenerationState copyWith({
    String? inputText,
    AiMood? selectedMood,
    GenerationStatus? status,
    String? output,
    String? errorMessage,
  }) {
    return GenerationState(
      inputText: inputText ?? this.inputText,
      selectedMood: selectedMood ?? this.selectedMood,
      status: status ?? this.status,
      output: output ?? this.output,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    inputText,
    selectedMood,
    status,
    output,
    errorMessage,
  ];
}
