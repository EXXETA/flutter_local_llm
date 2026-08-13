import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the active inference model and opens the multi-turn chat session.
class ChatStarted extends ChatEvent {
  const ChatStarted();
}

class ChatInputChanged extends ChatEvent {
  const ChatInputChanged(this.text);

  final String text;

  @override
  List<Object?> get props => [text];
}

class ChatMessageSubmitted extends ChatEvent {
  const ChatMessageSubmitted();
}

/// Resets the conversation — clears both the UI transcript and the model's
/// native session history.
class ChatHistoryCleared extends ChatEvent {
  const ChatHistoryCleared();
}
