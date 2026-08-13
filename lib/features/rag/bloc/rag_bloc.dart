import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/model_constants.dart';
import 'rag_event.dart';
import 'rag_state.dart';

class _RagDoc {
  const _RagDoc({
    required this.id,
    required this.content,
    required this.topic,
    required this.year,
  });

  final String id;
  final String content;
  final String topic;
  final int year;

  String get metadataJson => jsonEncode({'topic': topic, 'year': year});
}

const _kCorpus = [
  _RagDoc(
    id: 'sci-1',
    topic: 'science',
    year: 2021,
    content:
        'Vaccines work by presenting the immune system with a harmless '
        'fragment of a pathogen, such as a weakened virus or a piece of its '
        'protein coat. This trains the body to recognize the real pathogen '
        'and mount a fast antibody response if it is ever encountered again.',
  ),
  _RagDoc(
    id: 'sci-2',
    topic: 'science',
    year: 2023,
    content:
        'CRISPR-Cas9 lets researchers edit DNA with precision by guiding an '
        'enzyme to cut a specific sequence, which the cell then repairs — '
        'often with a new segment spliced in. It has accelerated gene '
        'therapy research for inherited diseases.',
  ),
  _RagDoc(
    id: 'cook-1',
    topic: 'cooking',
    year: 2020,
    content:
        "Sourdough bread rises using a natural culture of wild yeast and "
        "lactic acid bacteria instead of commercial yeast. The starter is "
        "fed flour and water over days until it's active enough to leaven a "
        "loaf, giving sourdough its tangy flavor.",
  ),
  _RagDoc(
    id: 'cook-2',
    topic: 'cooking',
    year: 2022,
    content:
        'Good knife skills start with a stable grip and a rocking motion '
        'that keeps the blade tip on the board. Uniform dice sizes cook '
        'more evenly, which is why professional kitchens spend so much time '
        'on mise en place before service.',
  ),
  _RagDoc(
    id: 'hist-1',
    topic: 'history',
    year: 1969,
    content:
        'On July 20, 1969, Apollo 11 landed the first humans on the Moon. '
        'Neil Armstrong and Buzz Aldrin spent about two and a half hours '
        'outside the lunar module while Michael Collins orbited above in '
        'the command module.',
  ),
  _RagDoc(
    id: 'hist-2',
    topic: 'history',
    year: 1989,
    content:
        'The Berlin Wall fell in November 1989 after East Germany opened '
        "its borders, symbolically ending the division of Europe. It's "
        'widely treated as the moment the Cold War began to close, with '
        'the Soviet Union dissolving two years later.',
  ),
  _RagDoc(
    id: 'hist-3',
    topic: 'history',
    year: 2001,
    content:
        'The September 11 attacks in 2001 reshaped global security policy, '
        'leading to sweeping changes in air travel screening and the '
        'creation of new government agencies focused on counterterrorism.',
  ),
];

const _kRagDbFileName = 'rag_demo.db';

class RagBloc extends Bloc<RagEvent, RagState> {
  RagBloc() : super(const RagState()) {
    on<RagCheckRequested>(_onCheck);
    on<RagInstallModelRequested>(_onInstall);
    on<RagIndexDocumentsRequested>(_onIndex);
    on<RagClearIndexRequested>(_onClear);
    on<RagSearchInputChanged>(
      (event, emit) => emit(state.copyWith(searchQuery: event.text)),
    );
    on<RagTopicFilterChanged>(
      (event, emit) => emit(state.copyWith(topicFilter: event.topic)),
    );
    on<RagRecentOnlyFilterChanged>(
      (event, emit) => emit(state.copyWith(recentOnly: event.recentOnly)),
    );
    on<RagSearchRequested>(_onSearch);
    on<_ProgressUpdated>(
      (event, emit) => emit(state.copyWith(installProgress: event.progress)),
    );
  }

  bool _storeInitialized = false;

  Future<void> _onCheck(
    RagCheckRequested event,
    Emitter<RagState> emit,
  ) async {
    // Shares the Gecko 256 embedder installed by the Embedding tab — only
    // one embedding model can be active at a time, so RAG piggybacks on it
    // rather than installing a second one.
    if (FlutterGemma.hasActiveEmbedder()) {
      emit(state.copyWith(status: RagStatus.idle));
    } else {
      emit(state.copyWith(status: RagStatus.modelNotInstalled));
    }
  }

  Future<void> _onInstall(
    RagInstallModelRequested event,
    Emitter<RagState> emit,
  ) async {
    emit(
      state.copyWith(status: RagStatus.installingModel, installProgress: 0),
    );
    try {
      final token = dotenv.env['HUGGING_FACE_API_KEY'];
      final hfToken = (token?.isNotEmpty == true) ? token : null;
      await FlutterGemma.installEmbedder()
          .modelFromNetwork(ModelConstants.embeddingModelUrl, token: hfToken)
          .tokenizerFromNetwork(
            ModelConstants.embeddingTokenizerUrl,
            token: hfToken,
          )
          .withModelProgress((p) => add(_ProgressUpdated(p)))
          .install();
      emit(state.copyWith(status: RagStatus.idle));
    } on DownloadException catch (e) {
      emit(
        state.copyWith(
          status: RagStatus.error,
          errorMessage: e.error.toUserMessage(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: RagStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// `addDocument`/`searchSimilar` auto-embed text through whichever
  /// embedding model instance the plugin currently has open. Unlike the
  /// Embedding tab — which opens a model, uses it once, and closes it — RAG
  /// needs one kept alive across the whole indexing/search flow, since the
  /// open instance is what the plugin's auto-embed path reads internally.
  /// `getActiveEmbedder()` returns a cached singleton (cheap to call
  /// repeatedly), so calling it right before every RAG operation both warms
  /// it up and self-heals if something else — e.g. the Embedding tab
  /// closing its own reference — dropped it in the meantime.
  Future<void> _ensureEmbedderActive() async {
    await FlutterGemma.getActiveEmbedder();
  }

  Future<void> _ensureStoreReady() async {
    if (_storeInitialized) return;
    final dir = await getApplicationDocumentsDirectory();
    await FlutterGemma.rag.initialize('${dir.path}/$_kRagDbFileName');
    _storeInitialized = true;
  }

  Future<void> _onIndex(
    RagIndexDocumentsRequested event,
    Emitter<RagState> emit,
  ) async {
    emit(state.copyWith(status: RagStatus.indexing));
    try {
      await _ensureStoreReady();
      await _ensureEmbedderActive();
      for (final doc in _kCorpus) {
        await FlutterGemma.rag.addDocument(
          id: doc.id,
          content: doc.content,
          metadata: doc.metadataJson,
        );
      }
      final stats = await FlutterGemma.rag.stats();
      emit(
        state.copyWith(
          status: RagStatus.idle,
          indexedCount: stats.documentCount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RagStatus.error,
          errorMessage: 'Indexing failed: $e',
        ),
      );
    }
  }

  Future<void> _onClear(
    RagClearIndexRequested event,
    Emitter<RagState> emit,
  ) async {
    try {
      await _ensureStoreReady();
      await FlutterGemma.rag.clear();
      emit(
        state.copyWith(
          status: RagStatus.idle,
          indexedCount: 0,
          results: const [],
          hasSearched: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RagStatus.error,
          errorMessage: 'Clear failed: $e',
        ),
      );
    }
  }

  /// Translates the topic chip + recency toggle into a [Filter] pushed down
  /// to sqlite-vec's typed `vec0` columns via the `topic`/`year`
  /// [FilterField]s declared in `FlutterGemma.initialize(filterSchema:)`.
  Filter? _buildFilter() {
    final must = <Condition>[];
    if (state.topicFilter != kAllTopics) {
      must.add(FieldEquals(key: 'topic', value: state.topicFilter));
    }
    if (state.recentOnly) {
      must.add(FieldRange(key: 'year', gte: 2020));
    }
    return must.isEmpty ? null : Filter(must: must);
  }

  Future<void> _onSearch(
    RagSearchRequested event,
    Emitter<RagState> emit,
  ) async {
    if (!state.canSearch) return;
    emit(state.copyWith(status: RagStatus.searching));
    try {
      await _ensureStoreReady();
      await _ensureEmbedderActive();
      final results = await FlutterGemma.rag.searchSimilar(
        query: state.searchQuery,
        topK: 5,
        filter: _buildFilter(),
      );
      emit(
        state.copyWith(
          status: RagStatus.idle,
          results: results,
          hasSearched: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RagStatus.error,
          errorMessage: 'Search failed: $e',
        ),
      );
    }
  }
}

class _ProgressUpdated extends RagEvent {
  const _ProgressUpdated(this.progress);

  final int progress;

  @override
  List<Object?> get props => [progress];
}
