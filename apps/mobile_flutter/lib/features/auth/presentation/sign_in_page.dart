import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.onContinue();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to continue: $e')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ALITAPTAP')),
      body: Center(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleContinue,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continue'),
        ),
      ),
    );
  }
}
