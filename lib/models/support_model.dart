class SupportTicket {
  final String ticketId;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final DateTime createdAt;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool isResolved;

  SupportTicket({
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.createdAt,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.isResolved,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessage': lastMessage,
      'isResolved': isResolved,
    };
  }

  factory SupportTicket.fromMap(Map<String, dynamic> map) {
    return SupportTicket(
      ticketId: map['ticketId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      subject: map['subject'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      lastMessageTime: DateTime.parse(map['lastMessageTime']),
      lastMessage: map['lastMessage'] ?? '',
      isResolved: map['isResolved'] ?? false,
    );
  }
}

class SupportMessage {
  final String messageId;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user' or 'admin'
  final String text;
  final String? imageUrl; // NEW: For image support
  final DateTime timestamp;

  SupportMessage({
    required this.messageId,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.imageUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'ticketId': ticketId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      messageId: map['messageId'] ?? '',
      ticketId: map['ticketId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'user',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
