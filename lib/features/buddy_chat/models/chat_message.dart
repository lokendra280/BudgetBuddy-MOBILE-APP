import 'dart:convert';

enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isSynced;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isSynced = false,
  });

  bool get isUser => role == MessageRole.user;

  ChatMessage copyWith({bool? isSynced}) => ChatMessage(
    id: id,
    role: role,
    content: content,
    timestamp: timestamp,
    isSynced: isSynced ?? this.isSynced,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    role: MessageRole.values.byName(json['role']),
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
    isSynced: json['isSynced'] ?? false,
  );

  /// Format for OpenAI API messages array
  Map<String, String> toApiMap() => {'role': role.name, 'content': content};
}
