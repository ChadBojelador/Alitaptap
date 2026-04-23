import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    super.key,
    required this.currentUid,
    required this.currentEmail,
    required this.otherUid,
    required this.otherEmail,
  });

  final String currentUid;
  final String currentEmail;
  final String otherUid;
  final String otherEmail;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final String _chatId;
  late final DocumentReference _chatRef;

  static const _yellow = Color(0xFFFFD60A);

  @override
  void initState() {
    super.initState();
    // Deterministic chat ID: sorted UIDs joined by '_'
    final ids = [widget.currentUid, widget.otherUid]..sort();
    _chatId = ids.join('_');
    _chatRef = FirebaseFirestore.instance.collection('chats').doc(_chatId);
    _markRead();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    await _chatRef.set(
      {'unread_${widget.currentUid}': 0},
      SetOptions(merge: true),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon! 🚀',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
        backgroundColor: _yellow,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    final now = FieldValue.serverTimestamp();
    final batch = FirebaseFirestore.instance.batch();

    // Add message to subcollection
    final msgRef = _chatRef.collection('messages').doc();
    batch.set(msgRef, {
      'sender_uid': widget.currentUid,
      'sender_email': widget.currentEmail,
      'text': text,
      'created_at': now,
    });

    // Update chat metadata
    batch.set(
      _chatRef,
      {
        'participants': [widget.currentUid, widget.otherUid],
        'emails': {
          widget.currentUid: widget.currentEmail,
          widget.otherUid: widget.otherEmail,
        },
        'last_message': text,
        'last_message_at': now,
        'unread_${widget.otherUid}': FieldValue.increment(1),
        'unread_${widget.currentUid}': 0,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
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
        title: Row(
          children: [
            _Avatar(email: widget.otherEmail, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherEmail.split('@').first,
                    style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                Text('Active now',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF66BB6A), fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _yellow),
            onPressed: () => _showComingSoon(context, 'Video Calling'),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: _yellow),
            onPressed: () => _showComingSoon(context, 'Voice Calling'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ───────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRef
                  .collection('messages')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  debugPrint('Messages Error: ${snap.error}');
                }
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _yellow, strokeWidth: 2));
                }
                final docs = snap.data?.docs ?? [];
                final displayedMsgs = <Map<String, dynamic>>[];

                // Add mock messages for this specific conversation
                if (MockData.mockMessages.containsKey(widget.otherUid)) {
                  for (var mock in MockData.mockMessages[widget.otherUid]!) {
                    displayedMsgs.add({
                      'sender_uid': mock['sender_uid'] == 'me' ? widget.currentUid : mock['sender_uid'],
                      'text': mock['text'],
                      'created_at': Timestamp.fromDate(mock['created_at'] as DateTime),
                    });
                  }
                }

                // Add real messages from Firestore
                for (var doc in docs) {
                  displayedMsgs.add(doc.data() as Map<String, dynamic>);
                }

                // Sort by time
                displayedMsgs.sort((a, b) {
                  final tA = a['created_at'] as Timestamp?;
                  final tB = b['created_at'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tA.compareTo(tB);
                });

                if (displayedMsgs.isEmpty) {
                  return Center(
                    child: Text('Say hello! 👋',
                        style: GoogleFonts.poppins(
                            color: subtle, fontSize: 14)),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(
                        _scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: displayedMsgs.length,
                  itemBuilder: (context, i) {
                    final data = displayedMsgs[i];
                    final isMe =
                        data['sender_uid'] == widget.currentUid;
                    final text = data['text'] as String? ?? '';
                    final ts = data['created_at'] as Timestamp?;
                    final time = ts != null
                        ? _formatTime(ts.toDate())
                        : '';
                    return _MessageBubble(
                      text: text,
                      time: time,
                      isMe: isMe,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border(
                top: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_library_rounded,
                      color: _yellow, size: 22),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Aa',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 14, color: subtle),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0F0F0),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _yellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Color(0xFF1A1A1A), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.isDark,
  });
  final String text;
  final String time;
  final bool isMe;
  final bool isDark;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(
                email: text.isNotEmpty ? text[0] : '?', size: 28),
            const SizedBox(width: 6),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? _yellow
                      : (isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                ),
                child: Text(text,
                    style: GoogleFonts.poppins(
                      color: isMe
                          ? const Color(0xFF1A1A1A)
                          : (isDark
                              ? const Color(0xFFF0F0F0)
                              : const Color(0xFF1A1A1A)),
                      fontSize: 14,
                    )),
              ),
              const SizedBox(height: 3),
              Text(time,
                  style: GoogleFonts.poppins(
                    color: isDark
                        ? const Color(0xFF616161)
                        : const Color(0xFF9E9E9E),
                    fontSize: 10,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.email, required this.size});
  final String email;
  final double size;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _yellow.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: GoogleFonts.poppins(
              color: _yellow,
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }
}
