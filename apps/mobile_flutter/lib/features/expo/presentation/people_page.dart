import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:alitaptap_mobile/core/mock_data.dart';

import 'chat_thread_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({
    super.key,
    required this.currentUid,
    required this.currentEmail,
  });

  final String currentUid;
  final String currentEmail;

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const _yellow = Color(0xFFFFD60A);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest(String targetUid) async {
    if (widget.currentUid.isEmpty || targetUid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(targetUid),
      {
        'friend_requests': FieldValue.arrayUnion([widget.currentUid])
      },
    );
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(widget.currentUid),
      {
        'sent_requests': FieldValue.arrayUnion([targetUid])
      },
    );
    await batch.commit();
  }

  Future<void> _acceptRequest(String fromUid) async {
    if (widget.currentUid.isEmpty || fromUid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final myRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUid);
    final theirRef =
        FirebaseFirestore.instance.collection('users').doc(fromUid);
    batch.update(myRef, {
      'friends': FieldValue.arrayUnion([fromUid]),
      'friend_requests': FieldValue.arrayRemove([fromUid]),
    });
    batch.update(theirRef, {
      'friends': FieldValue.arrayUnion([widget.currentUid]),
      'sent_requests': FieldValue.arrayRemove([widget.currentUid]),
    });
    await batch.commit();
  }

  Future<void> _declineRequest(String fromUid) async {
    if (widget.currentUid.isEmpty || fromUid.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUid)
        .update({
      'friend_requests': FieldValue.arrayRemove([fromUid]),
    });
  }

  Future<void> _unfriend(String otherUid) async {
    if (widget.currentUid.isEmpty || otherUid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(widget.currentUid),
      {'friends': FieldValue.arrayRemove([otherUid])},
    );
    batch.update(
      FirebaseFirestore.instance.collection('users').doc(otherUid),
      {'friends': FieldValue.arrayRemove([widget.currentUid])},
    );
    await batch.commit();
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
        title: Text('People',
            style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  style: GoogleFonts.poppins(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search people...',
                    hintStyle:
                        GoogleFonts.poppins(fontSize: 13, color: subtle),
                    prefixIcon:
                        const Icon(Icons.search_rounded, color: _yellow),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF0F0F0),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF1A1A1A),
                  unselectedLabelColor: subtle,
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Discover'),
                    Tab(text: 'Friends'),
                    Tab(text: 'Requests'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: widget.currentUid.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: _yellow, strokeWidth: 2))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUid)
                  .snapshots(),
              builder: (context, mySnap) {
                final myData =
                    mySnap.data?.data() as Map<String, dynamic>? ?? {};
          final friends =
              List<String>.from(myData['friends'] as List? ?? []);
          final requests =
              List<String>.from(myData['friend_requests'] as List? ?? []);
          final sent =
              List<String>.from(myData['sent_requests'] as List? ?? []);

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _UserList(
                currentUid: widget.currentUid,
                currentEmail: widget.currentEmail,
                query: _query,
                isDark: isDark,
                exclude: [widget.currentUid, ...friends],
                friends: friends,
                sent: sent,
                requests: requests,
                mode: _ListMode.discover,
                onAdd: _sendRequest,
                onAccept: _acceptRequest,
                onDecline: _declineRequest,
                onUnfriend: _unfriend,
              ),
              _UserList(
                currentUid: widget.currentUid,
                currentEmail: widget.currentEmail,
                query: _query,
                isDark: isDark,
                include: friends,
                friends: friends,
                sent: sent,
                requests: requests,
                mode: _ListMode.friends,
                onAdd: _sendRequest,
                onAccept: _acceptRequest,
                onDecline: _declineRequest,
                onUnfriend: _unfriend,
              ),
              _UserList(
                currentUid: widget.currentUid,
                currentEmail: widget.currentEmail,
                query: _query,
                isDark: isDark,
                include: requests,
                friends: friends,
                sent: sent,
                requests: requests,
                mode: _ListMode.requests,
                onAdd: _sendRequest,
                onAccept: _acceptRequest,
                onDecline: _declineRequest,
                onUnfriend: _unfriend,
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _ListMode { discover, friends, requests }

class _UserList extends StatelessWidget {
  const _UserList({
    required this.currentUid,
    required this.currentEmail,
    required this.query,
    required this.isDark,
    required this.friends,
    required this.sent,
    required this.requests,
    required this.mode,
    required this.onAdd,
    required this.onAccept,
    required this.onDecline,
    required this.onUnfriend,
    this.exclude = const [],
    this.include,
  });

  final String currentUid;
  final String currentEmail;
  final String query;
  final bool isDark;
  final List<String> exclude;
  final List<String>? include;
  final List<String> friends;
  final List<String> sent;
  final List<String> requests;
  final _ListMode mode;
  final Future<void> Function(String uid) onAdd;
  final Future<void> Function(String uid) onAccept;
  final Future<void> Function(String uid) onDecline;
  final Future<void> Function(String uid) onUnfriend;

  static const _yellow = Color(0xFFFFD60A);

  @override
  Widget build(BuildContext context) {
    final subtle =
        isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection('users');

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: _yellow, strokeWidth: 2));
        }

        var docs = snap.data?.docs ?? [];

        if (include != null) {
          docs = docs.where((d) => include!.contains(d.id)).toList();
        } else {
          docs = docs.where((d) => !exclude.contains(d.id)).toList();
        }

        if (query.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final email = (data['email'] as String? ?? '').toLowerCase();
            return email.contains(query);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 56, color: _yellow.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  mode == _ListMode.requests
                      ? 'No pending requests.'
                      : mode == _ListMode.friends
                          ? 'No friends yet. Discover people!'
                          : 'No users found.',
                  style: GoogleFonts.poppins(
                      color: subtle, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final uid = docs[i].id;
            final email = data['email'] as String? ?? uid;
            final role = data['role'] as String? ?? 'student';
            final isFriend = friends.contains(uid);
            final hasSent = sent.contains(uid);
            final hasRequest = requests.contains(uid);

            return _UserCard(
              uid: uid,
              email: email,
              role: role,
              isDark: isDark,
              isFriend: isFriend,
              hasSent: hasSent,
              hasRequest: hasRequest,
              mode: mode,
              onAdd: () => onAdd(uid),
              onAccept: () => onAccept(uid),
              onDecline: () => onDecline(uid),
              onUnfriend: () => onUnfriend(uid),
              onMessage: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatThreadPage(
                  currentUid: currentUid,
                  currentEmail: currentEmail,
                  otherUid: uid,
                  otherEmail: email,
                ),
              )),
            );
          },
        );
      },
    );
  }
}

class _UserCard extends StatefulWidget {
  const _UserCard({
    required this.uid,
    required this.email,
    required this.role,
    required this.isDark,
    required this.isFriend,
    required this.hasSent,
    required this.hasRequest,
    required this.mode,
    required this.onAdd,
    required this.onAccept,
    required this.onDecline,
    required this.onUnfriend,
    required this.onMessage,
  });

  final String uid;
  final String email;
  final String role;
  final bool isDark;
  final bool isFriend;
  final bool hasSent;
  final bool hasRequest;
  final _ListMode mode;
  final VoidCallback onAdd;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onUnfriend;
  final VoidCallback onMessage;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _loading = false;

  static const _yellow = Color(0xFFFFD60A);

  Color get _roleColor {
    switch (widget.role) {
      case 'admin':
        return const Color(0xFFEF5350);
      case 'community':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF42A5F5);
    }
  }

  Future<void> _run(VoidCallback fn) async {
    setState(() => _loading = true);
    await Future.microtask(fn);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDark
        ? const Color(0xFFF0F0F0)
        : const Color(0xFF1A1A1A);
    final subtle = widget.isDark
        ? const Color(0xFF9E9E9E)
        : const Color(0xFF757575);
    final name = MockData.mockUsers[widget.uid]?['name'] ?? widget.email.split('@').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _yellow.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          _Avatar(uid: widget.uid, email: widget.email, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.poppins(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.role,
                          style: GoogleFonts.poppins(
                            color: _roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    if (widget.isFriend) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.people_rounded,
                          color: _yellow, size: 13),
                      const SizedBox(width: 3),
                      Text('Friends',
                          style: GoogleFonts.poppins(
                              color: _yellow,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: _yellow, strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: widget.onMessage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _yellow.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded,
                        color: _yellow, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.mode == _ListMode.requests) ...[
                  GestureDetector(
                    onTap: () => _run(widget.onDecline),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFFEF5350), size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _run(widget.onAccept),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Accept',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ),
                ] else if (widget.isFriend)
                  GestureDetector(
                    onTap: () => _run(widget.onUnfriend),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: subtle.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: subtle.withValues(alpha: 0.3)),
                      ),
                      child: Text('Unfriend',
                          style: GoogleFonts.poppins(
                            color: subtle,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  )
                else if (widget.hasSent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: subtle.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Requested',
                        style: GoogleFonts.poppins(
                          color: subtle,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  )
                else
                  GestureDetector(
                    onTap: () => _run(widget.onAdd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_add_rounded,
                              color: Color(0xFF1A1A1A), size: 14),
                          const SizedBox(width: 5),
                          Text('Add',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1A1A1A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
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
