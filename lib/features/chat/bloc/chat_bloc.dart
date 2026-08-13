import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/model_constants.dart';
import 'chat_event.dart';
import 'chat_message.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatStarted>(_onStarted);
    on<ChatInputChanged>(_onInputChanged);
    on<ChatMessageSubmitted>(_onSubmitted);
    on<ChatHistoryCleared>(_onHistoryCleared);
  }

  InferenceModel? _model;
  InferenceChat? _chat;

  /// Loads the active model once and keeps a single [InferenceChat] open for
  /// the lifetime of the bloc. Every turn below reuses this same chat — that
  /// is what lets flutter_gemma track multi-turn history for us instead of
  /// us re-sending the whole transcript by hand.
  Future<void> _onStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading, errorMessage: null));
    try {
      final model = await FlutterGemma.getActiveModel(
        maxTokens: ModelConstants.maxTokens,
      );
      final chat = await model.createChat(
        // Qwen3-specific handling (thinking suppression, stop tokens) only
        // kicks in when the chat knows it's talking to Qwen3.
        modelType: ModelType.qwen3,
      );
      _model = model;
      _chat = chat;
      emit(state.copyWith(status: ChatStatus.ready));
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Failed to load model: $e',
        ),
      );
    }
  }

  void _onInputChanged(ChatInputChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(inputText: event.text));
  }

  Future<void> _onSubmitted(
    ChatMessageSubmitted event,
    Emitter<ChatState> emit,
  ) async {
    final chat = _chat;
    if (chat == null || !state.canSend) return;

    final text = state.inputText.trim();
    emit(
      state.copyWith(
        status: ChatStatus.sending,
        inputText: '',
        errorMessage: null,
        messages: [
          ...state.messages,
          ChatMessage(text: text, isUser: true),
          const ChatMessage(text: '', isUser: false, isStreaming: true),
        ],
      ),
    );

    try {
      // addQueryChunk appends to the chat's own history — it's what makes
      // the next generateChatResponseAsync() call see this whole
      // conversation, not just the latest message.
      await chat.addQueryChunk(Message.text(text: text, isUser: true));

      final buffer = StringBuffer();
      await emit.forEach<ModelResponse>(
        chat.generateChatResponseAsync(),
        onData: (response) {
          if (response is TextResponse) buffer.write(response.token);
          return state.copyWith(
            messages: _withStreamedReply(buffer.toString()),
          );
        },
      );

      emit(
        state.copyWith(
          status: ChatStatus.ready,
          messages: _withStreamedReply(buffer.toString(), isStreaming: false),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ChatStatus.error,
          errorMessage: 'Failed to generate a response: $e',
        ),
      );
    }
  }

  List<ChatMessage> _withStreamedReply(String text, {bool isStreaming = true}) {
    final messages = [...state.messages];
    if (messages.isEmpty) return messages;
    messages[messages.length - 1] = ChatMessage(
      text: text.trimLeft(),
      isUser: false,
      isStreaming: isStreaming,
    );
    return messages;
  }

  Future<void> _onHistoryCleared(
    ChatHistoryCleared event,
    Emitter<ChatState> emit,
  ) async {
    final chat = _chat;
    if (chat == null) return;
    // Drops the native session's history too — otherwise the model would
    // keep answering from a transcript the UI no longer shows.
    await chat.clearHistory();
    emit(state.copyWith(messages: const []));
  }

  @override
  Future<void> close() async {
    await _model?.close();
    return super.close();
  }
}
