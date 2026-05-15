import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/chat_model.dart';
import 'image_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or get existing chat
  Future<String> createOrGetChat({
    required String familyId,
    required String familyName,
    required String orphanageId,
    required String orphanageName,
    String? childId,
    String? childName,
  }) async {
    try {
      // Check if chat already exists
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: familyId)
          .get();

      for (var doc in querySnapshot.docs) {
        final chat = ChatModel.fromMap(doc.data());
        if (chat.participants.contains(orphanageId) && chat.childId == childId) {
          return chat.chatId;
        }
      }

      // Create new chat
      final chatId = DateTime.now().millisecondsSinceEpoch.toString();
      final chat = ChatModel(
        chatId: chatId,
        participants: [familyId, orphanageId],
        lastMessage: '',
        lastMessageTime: DateTime.now(),
        familyId: familyId,
        familyName: familyName,
        orphanageId: orphanageId,
        orphanageName: orphanageName,
        childId: childId,
        childName: childName,
        unreadCount: {familyId: 0, orphanageId: 0},
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toMap());
      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await ImageService.uploadImage(imageFile);
      }

      // Create message
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();

      final message = MessageModel(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        imageUrl: imageUrl,
        timestamp: now,
        isRead: false,
      );

      // Add message to subcollection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update chat last message and unread count
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final chat = ChatModel.fromMap(chatDoc.data()!);
      final receiverId = chat.participants.firstWhere((id) => id != senderId);

      final updatedUnreadCount = Map<String, int>.from(chat.unreadCount);
      updatedUnreadCount[receiverId] = (updatedUnreadCount[receiverId] ?? 0) + 1;

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': imageUrl != null ? '📷 Photo' : text,
        'lastMessageTime': Timestamp.fromDate(now), // Using Timestamp for better sorting
        'unreadCount': updatedUnreadCount,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get user chats
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromMap(doc.data())).toList();
    });
  }

  // Get messages - CRITICAL FOR WHATSAPP ORDERING
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // false = Oldest at top, Newest at bottom
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
    });
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Use a batch for efficiency
      WriteBatch batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('chats').doc(chatId));
      await batch.commit();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}