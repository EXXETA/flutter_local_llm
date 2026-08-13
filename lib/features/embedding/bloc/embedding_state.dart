import 'package:equatable/equatable.dart';

enum EmbeddingStatus {
  modelNotInstalled,
  installingModel,
  idle,
  embeddingReference,
  referenceReady,
  comparing,
  error,
}

class EmbeddingState extends Equatable {
  const EmbeddingState({
    this.status = EmbeddingStatus.modelNotInstalled,
    this.installProgress = 0,
    this.referenceVector,
    this.referenceDimensions,
    this.similarityInput = '',
    this.similarityScore,
    this.errorMessage,
  });

  final EmbeddingStatus status;
  final int installProgress;
  final List<double>? referenceVector;
  final int? referenceDimensions;
  final String similarityInput;
  final double? similarityScore;
  final String? errorMessage;

  bool get isModelReady =>
      status != EmbeddingStatus.modelNotInstalled &&
      status != EmbeddingStatus.installingModel;

  bool get hasReference => referenceVector != null;

  bool get canCompare =>
      hasReference && similarityInput.trim().isNotEmpty && !_isBusy;

  bool get _isBusy =>
      status == EmbeddingStatus.embeddingReference ||
      status == EmbeddingStatus.comparing ||
      status == EmbeddingStatus.installingModel;

  EmbeddingState copyWith({
    EmbeddingStatus? status,
    int? installProgress,
    List<double>? referenceVector,
    int? referenceDimensions,
    String? similarityInput,
    double? similarityScore,
    String? errorMessage,
  }) {
    return EmbeddingState(
      status: status ?? this.status,
      installProgress: installProgress ?? this.installProgress,
      referenceVector: referenceVector ?? this.referenceVector,
      referenceDimensions: referenceDimensions ?? this.referenceDimensions,
      similarityInput: similarityInput ?? this.similarityInput,
      similarityScore: similarityScore ?? this.similarityScore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    installProgress,
    referenceVector,
    referenceDimensions,
    similarityInput,
    similarityScore,
    errorMessage,
  ];
}
