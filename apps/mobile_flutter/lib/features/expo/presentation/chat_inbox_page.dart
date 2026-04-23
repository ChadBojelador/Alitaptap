import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';

import 'chat_thread_page.dart';
import 'people_page.dart';

class ChatInboxPage extends StatelessWidget {
  const ChatInboxPage({
    super.key,
    required this.currentUid,
    required this.currentEmail,
    this.openWithUid,
    this.openWithEmail,
  });

  final String currentUid;
  final String currentEmail;
  final String? openWithUid;
  final String? openWithEmail;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    if (openWithUid != null && openWithUid != currentUid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ChatThreadPage(
            currentUid: currentUid,
            currentEmail: currentEmail,
            otherUid: openWithUid!,
            otherEmail: openWithEmail ?? openWithUid!,
          ),
        ));
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final subtle =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: _yellow, size: 16),
          ),
        ),
        title: Text('Messages',
            style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PeoplePage(
                  currentUid: currentUid, currentEmail: currentEmail),
            )),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _yellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_rounded,
                  color: _yellow, size: 20),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            debugPrint('Firestore Error: ${snap.error}');
          }
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _yellow, strokeWidth: 2));
          }
          final docs = snap.data?.docs ?? [];
          final displayedChats = <Map<String, dynamic>>[];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            displayedChats.add(data);
          }

          for (var mock in MockData.mockChats) {
            final otherUid = mock['other_uid'] as String;
            final isExisting = displayedChats.any((c) {
              final parts = List<String>.from(c['participants'] ?? []);
              return parts.contains(otherUid);
            });

            if (!isExisting) {
              displayedChats.add({
                'participants': [currentUid, otherUid],
                'emails': {
                  currentUid: currentEmail,
                  otherUid: mock['other_email'],
                },
                'last_message': mock['last_message'],
                'last_message_at': Timestamp.fromDate(mock['last_message_at'] as DateTime),
                'unread_$currentUid': mock['unreadCount'],
              });
            }
          }

          if (displayedChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: _yellow.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No messages yet.',
                      style: GoogleFonts.poppins(
                          color: subtle, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Message a researcher from their post.',
                      style: GoogleFonts.poppins(
                          color: subtle, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: displayedChats.length,
            itemBuilder: (context, i) {
              final data = displayedChats[i];
              final participants =
                  List<String>.from(data['participants'] as List);
              final otherUid =
                  participants.firstWhere((p) => p != currentUid,
                      orElse: () => currentUid);
              final emails =
                  Map<String, String>.from(data['emails'] as Map? ?? {});
              final otherEmail = emails[otherUid] ?? otherUid;
              final otherName = MockData.mockUsers[otherUid]?['name'] ?? otherEmail.split('@').first;
              final lastMsg = data['last_message'] as String? ?? '';
              final lastAt = data['last_message_at'] as Timestamp?;
              final unread = (data['unread_$currentUid'] as int?) ?? 0;

              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatThreadPage(
                    currentUid: currentUid,
                    currentEmail: currentEmail,
                    otherUid: otherUid,
                    otherEmail: otherEmail,
                  ),
                )),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _Avatar(uid: otherUid, email: otherEmail, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(otherName,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                )),
                            const SizedBox(height: 2),
                            Text(lastMsg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: unread > 0
                                      ? textColor
                                      : subtle,
                                  fontSize: 12,
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                )),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastAt != null)
                            Text(
                              _timeAgo(lastAt.toDate()),
                              style: GoogleFonts.poppins(
                                  color: subtle, fontSize: 10),
                            ),
                          if (unread > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: _yellow,
                                shape: BoxShape.circle,
                              ),
                              child: Text('$unread',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1A1A1A),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.uid, this.email = '', required this.size});
  final String? uid;
  final String email;
  final double size;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    Map<String, String>? userData;
    if (uid != null && MockData.mockUsers.containsKey(uid)) {
      userData = MockData.mockUsers[uid];
    } else {
      try {
        final entry = MockData.mockUsers.entries.firstWhere(
            (e) => e.value['email'] == email,
            orElse: () => MapEntry('', {}));
        if (entry.key.isNotEmpty) userData = entry.value;
      } catch (_) {}
    }

    final imageUrl = userData?['avatar'];

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: _yellow.withValues(alpha: 0.4), width: 1.5),
        ),
      );
    }

    final initials = email.isNotEmpty
        ? email[0].toUpperCase()
        : (userData?['name'] != null ? userData!['name']![0].toUpperCase() : '?');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: _yellow.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
              color: _yellow,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}
