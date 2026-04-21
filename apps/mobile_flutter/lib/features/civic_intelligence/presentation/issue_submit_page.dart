import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IssueSubmitPage extends StatefulWidget {
  const IssueSubmitPage({super.key, required this.reporterId, this.reporterName});
  final String reporterId;
  final String? reporterName;

  @override
  State<IssueSubmitPage> createState() => _IssueSubmitPageState();
}

class _IssueSubmitPageState extends State<IssueSubmitPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Report a Problem',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: const Center(
        child: Text('Report a Problem Page'),
      ),
    );
  }
}
