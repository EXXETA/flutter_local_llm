import 'package:equatable/equatable.dart';

abstract class RagEvent extends Equatable {
  const RagEvent();

  @override
  List<Object?> get props => [];
}

/// Check if the embedding model (shared with the Embedding tab) is installed.
class RagCheckRequested extends RagEvent {
  const RagCheckRequested();
}

/// Install the Gecko 256 embedding model.
class RagInstallModelRequested extends RagEvent {
  const RagInstallModelRequested();
}

/// Embed and index the fixed demo document corpus.
class RagIndexDocumentsRequested extends RagEvent {
  const RagIndexDocumentsRequested();
}

/// Wipe the vector store clean.
class RagClearIndexRequested extends RagEvent {
  const RagClearIndexRequested();
}

/// User edited the search query.
class RagSearchInputChanged extends RagEvent {
  const RagSearchInputChanged(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

/// User picked a topic filter chip (or `kAllTopics`).
class RagTopicFilterChanged extends RagEvent {
  const RagTopicFilterChanged(this.topic);

  final String topic;

  @override
  List<Object?> get props => [topic];
}

/// User toggled the "2020 or later" filter.
class RagRecentOnlyFilterChanged extends RagEvent {
  const RagRecentOnlyFilterChanged(this.recentOnly);

  final bool recentOnly;

  @override
  List<Object?> get props => [recentOnly];
}

/// Run the filtered semantic search.
class RagSearchRequested extends RagEvent {
  const RagSearchRequested();
}
