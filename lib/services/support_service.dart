import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/support_model.dart';
import 'image_service.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new support ticket
  Future<String?> createSupportTicket({
    required String userId,
    required String userName,
    required String userEmail,
    required String subject,
    required String initialMessage,
    File? imageFile,
  }) async {
    try {
      final ticketId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ImageService.uploadImage(imageFile);
      }

      final ticket = SupportTicket(
        ticketId: ticketId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        createdAt: DateTime.now(),
        lastMessageTime: DateTime.now(),
        lastMessage: imageUrl != null ? '🖼️ Photo' : initialMessage,
        isResolved: false,
      );

      // Create ticket document
      await _firestore.collection('support_tickets').doc(ticketId).set(ticket.toMap());

      // Create initial message
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final message = SupportMessage(
        messageId: messageId,
        ticketId: ticketId,
        senderId: userId,
        senderName: userName,
        senderRole: 'user',
        text: initialMessage,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      return null; // Success
    } catch (e) {
      print('Error creating support ticket: $e');
      return 'Failed to create ticket: $e';
    }
  }

  // Send support message with optional image
  Future<String?> sendSupportMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String text,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await ImageService.uploadImage(imageFile);
      }

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final message = SupportMessage(
        messageId: messageId,
        ticketId: ticketId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        text: text,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
      );

      // Add message to subcollection
      await _firestore
          .collection('support_tickets')
          .doc(ticketId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Update ticket's last message
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'lastMessage': imageUrl != null ? '🖼️ Photo' : text,
        'lastMessageTime': DateTime.now().toIso8601String(),
      });

      return null; // Success
    } catch (e) {
      print('Error sending support message: $e');
      return 'Failed to send message: $e';
    }
  }

  // Get user's support tickets
  Stream<List<SupportTicket>> getUserSupportTickets(String userId) {
    return _firestore
        .collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      List<SupportTicket> tickets = snapshot.docs.map((doc) {
        return SupportTicket.fromMap(doc.data());
      }).toList();
      // Sort in Dart instead of Firestore to avoid index requirement
      tickets.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return tickets;
    });
  }

  // Get all support tickets (for admin)
  Stream<List<SupportTicket>> getAllSupportTickets() {
    return _firestore
        .collection('support_tickets')
        .snapshots()
        .map((snapshot) {
      List<SupportTicket> tickets = snapshot.docs.map((doc) {
        return SupportTicket.fromMap(doc.data());
      }).toList();
      // Sort in Dart instead of Firestore to avoid index requirement
      tickets.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      return tickets;
    });
  }

  // Get messages for a ticket
  Stream<List<SupportMessage>> getTicketMessages(String ticketId) {
    return _firestore
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      List<SupportMessage> messages = snapshot.docs.map((doc) {
        return SupportMessage.fromMap(doc.data());
      }).toList();
      // Sort in Dart instead of Firestore to avoid index requirement
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Resolve ticket
  Future<String?> resolveTicket(String ticketId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'isResolved': true,
        'lastMessageTime': DateTime.now().toIso8601String(),
      });
      return null;
    } catch (e) {
      print('Error resolving ticket: $e');
      return 'Failed to resolve ticket: $e';
    }
  }

  // Reopen ticket
  Future<String?> reopenTicket(String ticketId) async {
    try {
      await _firestore.collection('support_tickets').doc(ticketId).update({
        'isResolved': false,
        'lastMessageTime': DateTime.now().toIso8601String(),
      });
      return null;
    } catch (e) {
      print('Error reopening ticket: $e');
      return 'Failed to reopen ticket: $e';
    }
  }
}