import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import 'chat_messaging_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConversationsListScreen extends StatefulWidget {
  final UserModel user;

  const ConversationsListScreen({super.key, required this.user});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final ChatService _chatService = ChatService();
  Stream<List<ChatModel>>? _chatsStream;

  @override
  void initState() {
    super.initState();
    _chatsStream = _chatService.getUserChats(widget.user.uid);
  }

  void _showDeleteDialog(String chatId, String otherUserName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Delete Chat?",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete your conversation with $otherUserName? All messages will be permanently removed.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _chatService.deleteChat(chatId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Conversation deleted")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error deleting conversation")),
                    );
                  }
                }
              },
              child: Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToChat(ChatModel chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessagingScreen(
          chat: chat,
          currentUser: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return _buildErrorState(isDark);
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) return _buildEmptyState(isDark);

          return RefreshIndicator(
            color: const Color(0xFF6C63FF),
            onRefresh: () async {
              setState(() {
                _chatsStream = _chatService.getUserChats(widget.user.uid);
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUserName = widget.user.role == 'family'
                    ? chat.orphanageName
                    : chat.familyName;
                final unreadCount = chat.unreadCount[widget.user.uid] ?? 0;

                return GestureDetector(
                  onLongPress: () => _showDeleteDialog(chat.chatId, otherUserName),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    child: InkWell(
                      onTap: () => _navigateToChat(chat),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            _buildAvatar(otherUserName, unreadCount),
                            const SizedBox(width: 14),
                            _buildChatInfo(chat, otherUserName, unreadCount, isDark),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String name, int unread) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
          child: Text(
            name[0].toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF6C63FF)),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatInfo(ChatModel chat, String name, int unread, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeago.format(chat.lastMessageTime, locale: 'en_short'),
                style: GoogleFonts.poppins(fontSize: 11, color: isDark ? Colors.grey[500] : Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (chat.childName != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('About: ${chat.childName}', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: unread > 0 ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.grey[500] : Colors.grey[600]),
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 60, color: Color(0xFF6C63FF)),
          const SizedBox(height: 20),
          Text('No messages yet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            widget.user.role == 'family' ? 'Contact an orphanage' : 'Families will message you here',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
          const SizedBox(height: 14),
          Text('Error loading chats', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ElevatedButton(
            onPressed: () => setState(() => _chatsStream = _chatService.getUserChats(widget.user.uid)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}