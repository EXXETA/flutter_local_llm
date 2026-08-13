import 'package:equatable/equatable.dart';

abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();

  @override
  List<Object?> get props => [];
}

class AnalysisClassifyRequested extends AnalysisEvent {
  const AnalysisClassifyRequested();
}

class AnalysisExtractEntitiesRequested extends AnalysisEvent {
  const AnalysisExtractEntitiesRequested();
}
