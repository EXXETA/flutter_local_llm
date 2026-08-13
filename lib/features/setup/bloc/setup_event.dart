import 'package:equatable/equatable.dart';

abstract class SetupEvent extends Equatable {
  const SetupEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once on screen init — checks whether a model is already active.
class SetupCheckRequested extends SetupEvent {
  const SetupCheckRequested();
}

/// User pressed the install / retry button.
class SetupInstallRequested extends SetupEvent {
  const SetupInstallRequested();
}
