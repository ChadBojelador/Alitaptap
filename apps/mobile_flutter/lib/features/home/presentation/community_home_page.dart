import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../civic_intelligence/presentation/issue_map_page.dart';
import '../../civic_intelligence/presentation/issue_submit_page.dart';

/// Community member home page — report problems and view the map.
class CommunityHomePage extends StatelessWidget {
  const CommunityHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';

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
            Icon(Icons.people_alt_rounded,
                size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Community Hub',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Report local problems and help researchers find real community needs.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // --- Report button ---
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => IssueSubmitPage(reporterId: uid),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Report a Problem'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),

            // --- Map button ---
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const IssueMapPage()),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('View Community Map'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
