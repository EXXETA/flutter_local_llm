import 'package:equatable/equatable.dart';

enum AnalysisStatus { idle, loading, success, error }

class AnalysisState extends Equatable {
  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.output = '',
    this.errorMessage,
  });

  final AnalysisStatus status;
  final String output;
  final String? errorMessage;

  bool get isLoading => status == AnalysisStatus.loading;

  AnalysisState copyWith({
    AnalysisStatus? status,
    String? output,
    String? errorMessage,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      output: output ?? this.output,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, output, errorMessage];
}
