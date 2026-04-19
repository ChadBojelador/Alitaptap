import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../civic_intelligence/presentation/issue_map_page.dart';
import '../../neural_mapper/presentation/idea_match_page.dart';

/// Student home page — explore community problems and match research ideas.
class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALITAPTAP'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.school_rounded,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Student Research Hub',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Explore real community problems and find research opportunities.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // --- Explore problems ---
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IssueMapPage()),
              ),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explore Problems'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),

            // --- Neural Mapper: idea input ---
            FilledButton.icon(
              onPressed: () {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => IdeaMatchPage(studentId: uid),
                  ),
                );
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Match Your Idea'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: theme.textTheme.titleMedium,
                backgroundColor: theme.colorScheme.tertiary,
                foregroundColor: theme.colorScheme.onTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
