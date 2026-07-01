import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.content,
    required this.sender,
    required this.createdAt,
  });

  final String content;
  final ChatSender sender;
  final DateTime createdAt;

  bool get isUser => sender == ChatSender.user;

  @override
  List<Object?> get props => [content, sender, createdAt];
}

enum ChatSender { user, bot }

abstract class ChatRepository {
  Future<String> sendMessage(String message);
}
