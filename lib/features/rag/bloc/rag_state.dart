import 'package:equatable/equatable.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

const kAllTopics = 'all';
const kRagTopics = ['science', 'cooking', 'history'];

enum RagStatus {
  modelNotInstalled,
  installingModel,
  idle,
  indexing,
  searching,
  error,
}

class RagState extends Equatable {
  const RagState({
    this.status = RagStatus.modelNotInstalled,
    this.installProgress = 0,
    this.indexedCount = 0,
    this.searchQuery = '',
    this.topicFilter = kAllTopics,
    this.recentOnly = false,
    this.results = const [],
    this.hasSearched = false,
    this.errorMessage,
  });

  final RagStatus status;
  final int installProgress;
  final int indexedCount;
  final String searchQuery;
  final String topicFilter;
  final bool recentOnly;
  final List<RetrievalResult> results;
  final bool hasSearched;
  final String? errorMessage;

  bool get isModelReady =>
      status != RagStatus.modelNotInstalled &&
      status != RagStatus.installingModel;

  bool get isIndexed => indexedCount > 0;

  bool get canIndex => isModelReady && !_isBusy;

  bool get canSearch => isIndexed && searchQuery.trim().isNotEmpty && !_isBusy;

  bool get _isBusy =>
      status == RagStatus.indexing ||
      status == RagStatus.searching ||
      status == RagStatus.installingModel;

  RagState copyWith({
    RagStatus? status,
    int? installProgress,
    int? indexedCount,
    String? searchQuery,
    String? topicFilter,
    bool? recentOnly,
    List<RetrievalResult>? results,
    bool? hasSearched,
    String? errorMessage,
  }) {
    return RagState(
      status: status ?? this.status,
      installProgress: installProgress ?? this.installProgress,
      indexedCount: indexedCount ?? this.indexedCount,
      searchQuery: searchQuery ?? this.searchQuery,
      topicFilter: topicFilter ?? this.topicFilter,
      recentOnly: recentOnly ?? this.recentOnly,
      results: results ?? this.results,
      hasSearched: hasSearched ?? this.hasSearched,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    installProgress,
    indexedCount,
    searchQuery,
    topicFilter,
    recentOnly,
    results,
    hasSearched,
    errorMessage,
  ];
}
