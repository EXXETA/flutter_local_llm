import 'package:equatable/equatable.dart';

import 'chat_message.dart';

enum ChatStatus { loading, ready, sending, error }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.inputText = '',
    this.errorMessage,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;
  final String inputText;
  final String? errorMessage;

  bool get isModelReady => status != ChatStatus.loading;
  bool get canSend => status == ChatStatus.ready && inputText.trim().isNotEmpty;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? inputText,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      inputText: inputText ?? this.inputText,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, inputText, errorMessage];
}
