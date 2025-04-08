import 'package:equatable/equatable.dart';

enum ChatMessageSender { user, bot }

class ChatMessageEntity extends Equatable {
  final ChatMessageSender sender;
  final String text;
  final DateTime timestamp;
  // Optional: Add fields like message type, suggestions associated with this message, etc.

  const ChatMessageEntity({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [sender, text, timestamp];
}
