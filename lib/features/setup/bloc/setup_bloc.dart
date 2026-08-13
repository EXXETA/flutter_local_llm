import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/model_constants.dart';
import 'setup_event.dart';
import 'setup_state.dart';

class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc() : super(const SetupState()) {
    on<SetupCheckRequested>(_onCheck);
    on<SetupInstallRequested>(_onInstall);
    on<_ProgressUpdated>(
      (event, emit) => emit(state.copyWith(downloadProgress: event.progress)),
    );
  }

  Future<void> _onCheck(
    SetupCheckRequested event,
    Emitter<SetupState> emit,
  ) async {
    emit(state.copyWith(status: SetupStatus.checking));
    // hasActiveModel() is a synchronous, cheap check — it returns true when
    // a previously installed model spec has been restored from SharedPreferences.
    // Avoids loading the model just to verify it exists.
    if (FlutterGemma.hasActiveModel()) {
      emit(state.copyWith(status: SetupStatus.ready));
    } else {
      emit(state.copyWith(status: SetupStatus.notInstalled));
    }
  }

  Future<void> _onInstall(
    SetupInstallRequested event,
    Emitter<SetupState> emit,
  ) async {
    emit(state.copyWith(status: SetupStatus.downloading, downloadProgress: 0));
    try {
      await FlutterGemma.installModel(
            modelType: ModelType.qwen3,
            fileType: ModelFileType
                .litertlm, // .litertlm → routed to LiteRtLmFfiClient
          )
          .fromNetwork(
            ModelConstants.inferenceModelUrl,
            // Qwen3 0.6B is public — no token required.
            // For gated models (Gemma3, EmbeddingGemma), pass:
            // token: dotenv.env['HUGGING_FACE_API_KEY'],
          )
          .withProgress((progress) => add(_ProgressUpdated(progress)))
          .install();
      emit(state.copyWith(status: SetupStatus.ready));
    } on DownloadException catch (e) {
      emit(
        state.copyWith(
          status: SetupStatus.error,
          errorMessage: e.error.toUserMessage(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: SetupStatus.error, errorMessage: e.toString()),
      );
    }
  }
}

// File-private event — only SetupBloc calls add(_ProgressUpdated).
class _ProgressUpdated extends SetupEvent {
  const _ProgressUpdated(this.progress);

  final int progress;

  @override
  List<Object?> get props => [progress];
}
