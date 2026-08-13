import 'package:equatable/equatable.dart';

abstract class EmbeddingEvent extends Equatable {
  const EmbeddingEvent();

  @override
  List<Object?> get props => [];
}

/// Check if embedding model is already installed.
class EmbeddingCheckRequested extends EmbeddingEvent {
  const EmbeddingCheckRequested();
}

/// Install EmbeddingGemma model (requires HF token in .env).
class EmbeddingInstallModelRequested extends EmbeddingEvent {
  const EmbeddingInstallModelRequested();
}

/// Embed the static reference text.
class EmbeddingEmbedReferenceRequested extends EmbeddingEvent {
  const EmbeddingEmbedReferenceRequested();
}

/// User changed the similarity comparison input.
class EmbeddingSimilarityInputChanged extends EmbeddingEvent {
  const EmbeddingSimilarityInputChanged(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Quick-fill similarity input.
class EmbeddingSimilarityQuickFill extends EmbeddingEvent {
  const EmbeddingSimilarityQuickFill(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// Run cosine similarity between reference and current input.
class EmbeddingCompareRequested extends EmbeddingEvent {
  const EmbeddingCompareRequested();
}
