import 'package:equatable/equatable.dart';

enum SetupStatus { checking, notInstalled, downloading, ready, error }

class SetupState extends Equatable {
  const SetupState({
    this.status = SetupStatus.checking,
    this.downloadProgress = 0,
    this.errorMessage,
  });

  final SetupStatus status;

  /// 0–100 during download.
  final int downloadProgress;

  final String? errorMessage;

  bool get isLoading =>
      status == SetupStatus.checking || status == SetupStatus.downloading;

  SetupState copyWith({
    SetupStatus? status,
    int? downloadProgress,
    String? errorMessage,
  }) {
    return SetupState(
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, downloadProgress, errorMessage];
}
