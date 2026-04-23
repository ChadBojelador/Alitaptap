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

    final msgRef = _chatRef.collection('messages').doc();
    batch.set(msgRef, {
      'sender_uid': widget.currentUid,
      'sender_email': widget.currentEmail,
      'text': text,
      'created_at': now,
    });

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
      },
      SetOptions(merge: true),
    );

    await batch.commit();

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
    final _otherName = MockData.mockUsers[widget.otherUid]?['name'] ?? widget.otherEmail.split('@').first;

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
            _Avatar(uid: widget.otherUid, email: widget.otherEmail, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_otherName,
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRef
                  .collection('messages')
                  .orderBy('created_at', descending: false)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: _yellow));
                }
                
                final realMsgs = snap.data?.docs ?? [];
                final displayedMsgs = <Map<String, dynamic>>[];

                for (var doc in realMsgs) {
                  displayedMsgs.add(doc.data() as Map<String, dynamic>);
                }

                if (realMsgs.isEmpty) {
                  final mockThread = MockData.mockMessages[_chatId] ?? [];
                  for (var m in mockThread) {
                    displayedMsgs.add({
                      'sender_uid': m['sender_uid'],
                      'text': m['text'],
                      'created_at': Timestamp.fromDate(m['created_at'] as DateTime),
                    });
                  }
                  displayedMsgs.sort((a, b) => (a['created_at'] as Timestamp).compareTo(b['created_at'] as Timestamp));
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: displayedMsgs.length,
                  itemBuilder: (context, i) {
                    final msg = displayedMsgs[i];
                    final isMe = msg['sender_uid'] == widget.currentUid;
                    final time = msg['created_at'] as Timestamp?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe) ...[
                                _Avatar(uid: widget.otherUid, email: widget.otherEmail, size: 28),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? _yellow : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    boxShadow: [
                                      if (!isMe) BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    msg['text'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: isMe ? const Color(0xFF1A1A1A) : textColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (time != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 36, right: 4),
                              child: Text(
                                '${time.toDate().hour}:${time.toDate().minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 9),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _yellow),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
