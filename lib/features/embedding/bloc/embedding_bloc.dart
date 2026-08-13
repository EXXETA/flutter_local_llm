import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/model_constants.dart';
import 'embedding_event.dart';
import 'embedding_state.dart';

const _kReferenceText =
    'Planets orbit stars in vast solar systems, held in place by gravity across '
    'immense stretches of space. From rocky terrestrial worlds to massive gas '
    'giants, each planet tells a unique story about the forces that shaped our '
    'universe.';

class EmbeddingBloc extends Bloc<EmbeddingEvent, EmbeddingState> {
  EmbeddingBloc() : super(const EmbeddingState()) {
    on<EmbeddingCheckRequested>(_onCheck);
    on<EmbeddingInstallModelRequested>(_onInstall);
    on<EmbeddingEmbedReferenceRequested>(_onEmbedReference);
    on<EmbeddingSimilarityInputChanged>(_onInputChanged);
    on<EmbeddingSimilarityQuickFill>(_onQuickFill);
    on<EmbeddingCompareRequested>(_onCompare);
    on<_ProgressUpdated>(
      (event, emit) => emit(state.copyWith(installProgress: event.progress)),
    );
  }

  Future<void> _onCheck(
    EmbeddingCheckRequested event,
    Emitter<EmbeddingState> emit,
  ) async {
    // hasActiveEmbedder() is a synchronous, cheap check — it returns true when
    // a previously installed embedder spec has been restored from SharedPreferences.
    if (FlutterGemma.hasActiveEmbedder()) {
      emit(state.copyWith(status: EmbeddingStatus.idle));
    } else {
      emit(state.copyWith(status: EmbeddingStatus.modelNotInstalled));
    }
  }

  Future<void> _onInstall(
    EmbeddingInstallModelRequested event,
    Emitter<EmbeddingState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EmbeddingStatus.installingModel,
        installProgress: 0,
      ),
    );
    try {
      // Gecko 256 is public — no token required.
      // If you switch to EmbeddingGemma (gated), uncomment the token line.
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
      emit(state.copyWith(status: EmbeddingStatus.idle));
    } on DownloadException catch (e) {
      emit(
        state.copyWith(
          status: EmbeddingStatus.error,
          errorMessage: e.error.toUserMessage(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EmbeddingStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onEmbedReference(
    EmbeddingEmbedReferenceRequested event,
    Emitter<EmbeddingState> emit,
  ) async {
    emit(state.copyWith(status: EmbeddingStatus.embeddingReference));
    try {
      final embedder = await FlutterGemma.getActiveEmbedder();
      try {
        final vector = await embedder.generateEmbedding(_kReferenceText);
        emit(
          state.copyWith(
            status: EmbeddingStatus.referenceReady,
            referenceVector: vector,
            referenceDimensions: vector.length,
          ),
        );
      } finally {
        await embedder.close();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: EmbeddingStatus.error,
          errorMessage: 'Embedding failed: $e',
        ),
      );
    }
  }

  void _onInputChanged(
    EmbeddingSimilarityInputChanged event,
    Emitter<EmbeddingState> emit,
  ) {
    emit(state.copyWith(similarityInput: event.text));
  }

  void _onQuickFill(
    EmbeddingSimilarityQuickFill event,
    Emitter<EmbeddingState> emit,
  ) {
    emit(state.copyWith(similarityInput: event.text));
  }

  Future<void> _onCompare(
    EmbeddingCompareRequested event,
    Emitter<EmbeddingState> emit,
  ) async {
    if (!state.canCompare) return;
    emit(state.copyWith(status: EmbeddingStatus.comparing));
    try {
      final embedder = await FlutterGemma.getActiveEmbedder();
      try {
        final inputVec = await embedder.generateEmbedding(
          state.similarityInput,
        );
        final score = _cosineSimilarity(state.referenceVector!, inputVec);
        emit(
          state.copyWith(
            status: EmbeddingStatus.referenceReady,
            similarityScore: score,
          ),
        );
      } finally {
        await embedder.close();
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: EmbeddingStatus.error,
          errorMessage: 'Comparison failed: $e',
        ),
      );
    }
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final denom = math.sqrt(magA) * math.sqrt(magB);
    return denom == 0 ? 0 : dot / denom;
  }
}

class _ProgressUpdated extends EmbeddingEvent {
  const _ProgressUpdated(this.progress);

  final int progress;

  @override
  List<Object?> get props => [progress];
}
