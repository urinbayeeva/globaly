import 'package:equatable/equatable.dart';

enum ChatSender { user, assistant }

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.imagePath,
  });

  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;

  final String? imagePath;

  bool get isUser => sender == ChatSender.user;
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  List<Object?> get props => <Object?>[id, sender, text, timestamp, imagePath];
}
