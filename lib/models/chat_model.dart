import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String familyId;
  final String familyName;
  final String orphanageId;
  final String orphanageName;
  final String? childId;
  final String? childName;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.familyId,
    required this.familyName,
    required this.orphanageId,
    required this.orphanageName,
    this.childId,
    this.childName,
    required this.unreadCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime), // Save as Timestamp
      'familyId': familyId,
      'familyName': familyName,
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'childId': childId,
      'childName': childName,
      'unreadCount': unreadCount,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chatId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: _parseDateTime(map['lastMessageTime']), // Safe parsing
      familyId: map['familyId'] ?? '',
      familyName: map['familyName'] ?? '',
      orphanageId: map['orphanageId'] ?? '',
      orphanageName: map['orphanageName'] ?? '',
      childId: map['childId'],
      childName: map['childName'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}

class MessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp), // Save as Timestamp
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: _parseDateTime(map['timestamp']), // Safe parsing
      isRead: map['isRead'] ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }
}