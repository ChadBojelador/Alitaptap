// TEMPORARILY DISABLED: Firebase chat features removed
// TODO: Implement chat with FastAPI backend

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';

import 'chat_thread_page.dart';

class ChatInboxPage extends StatelessWidget {
  const ChatInboxPage({super.key, required this.currentUid});
  final String currentUid;

  @override
  Widget build(BuildContext context) {
    final chats = [...MockData.mockChats]..sort((a, b) =>
        _parseDate((b['last_message_at'] as String?) ?? '')
            .compareTo(_parseDate((a['last_message_at'] as String?) ?? '')));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat Inbox',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: chats.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No sample chats yet',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              itemCount: chats.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final otherUid = chat['other_uid'] as String? ?? '';
                final user = MockData.mockUsers[otherUid] ?? const {};
                final name = user['name'] ?? 'Unknown User';
                final avatar = user['avatar'] ?? '';
                final lastMessage = chat['last_message'] as String? ?? '';
                final unread = (chat['unread_count'] as num?)?.toInt() ?? 0;
                final isOnline = chat['is_online'] == true;
                final timestamp = _formatTimestamp(
                  chat['last_message_at'] as String? ?? '',
                );

                return ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatThreadPage(
                          currentUid: currentUid,
                          otherUid: otherUid,
                          otherName: name,
                        ),
                      ),
                    );
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: _ChatAvatar(
                    name: name,
                    avatarPath: avatar,
                    isOnline: isOnline,
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight:
                          unread > 0 ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timestamp,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD60A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unread',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
    );
  }

  static DateTime _parseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  static String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({
    required this.name,
    required this.avatarPath,
    required this.isOnline,
  });

  final String name;
  final String avatarPath;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final hasAvatar = avatarPath.isNotEmpty;

    final ImageProvider? avatarImage = hasAvatar
        ? avatarPath.startsWith('assets/')
            ? AssetImage(avatarPath)
            : NetworkImage(avatarPath)
        : null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFFFD60A).withValues(alpha: 0.2),
          backgroundImage: avatarImage,
          child: avatarImage == null
              ? Text(
                  initials,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFFD60A),
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
