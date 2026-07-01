import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/chat_domain.dart';

enum ChatStatus { initial, sending, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;
  final String? errorMessage;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(_initialState());

  final ChatRepository _repository;

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.status == ChatStatus.sending) return;

    final now = DateTime.now();
    final userMessage = ChatMessage(
      content: message,
      sender: ChatSender.user,
      createdAt: now,
    );

    emit(
      state.copyWith(
        status: ChatStatus.sending,
        messages: [...state.messages, userMessage],
        clearError: true,
      ),
    );

    try {
      final reply = await _repository.sendMessage(message);
      emit(
        state.copyWith(
          status: ChatStatus.initial,
          messages: [
            ...state.messages,
            ChatMessage(
              content: reply,
              sender: ChatSender.bot,
              createdAt: DateTime.now(),
            ),
          ],
          clearError: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: ChatStatus.failure,
          errorMessage: error.message,
          messages: [
            ...state.messages,
            ChatMessage(
              content: 'تعذر إرسال الرسالة. ${error.message}',
              sender: ChatSender.bot,
              createdAt: DateTime.now(),
            ),
          ],
        ),
      );
    }
  }
}

ChatState _initialState() {
  return ChatState(
    messages: [
      ChatMessage(
        content: 'مرحباً، أنا مساعد النظام. كيف يمكنني مساعدتك اليوم؟',
        sender: ChatSender.bot,
        createdAt: DateTime.now(),
      ),
    ],
  );
}
