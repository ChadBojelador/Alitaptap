// TEMPORARILY DISABLED: Firebase chat features removed
// TODO: Implement chat with FastAPI backend

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatThreadPage extends StatelessWidget {
  const ChatThreadPage({
    super.key,
    required this.currentUid,
    required this.otherUid,
    required this.otherName,
  });

  final String currentUid;
  final String otherUid;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with $otherName')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Chat feature coming soon',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This feature requires backend implementation',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
