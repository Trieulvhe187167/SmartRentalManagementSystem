class AppNotification {
  final int? id;
  final String? title;
  final String? content;
  final String? type;
  final bool? isRead;
  final String? createdAt;

  const AppNotification({
    this.id,
    this.title,
    this.content,
    this.type,
    this.isRead,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String?,
      isRead: json['read'] as bool? ?? json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type,
        'read': isRead,
        'createdAt': createdAt,
      };
}

class NotificationBroadcastRequest {
  final String? title;
  final String? content;
  final String? type;

  const NotificationBroadcastRequest({
    required this.title,
    required this.content,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'type': type,
      };
}
