import 'package:flutter/material.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALITAPTAP')),
      body: Center(
        child: ElevatedButton(
          onPressed: onContinue,
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
