import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../core/barrel.dart';

/// Debug Preference Test Widget
/// Simple widget to test if preferences are actually changing
class DebugPreferenceTest extends ConsumerWidget {
  const DebugPreferenceTest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current preferences
    final prefs = ref.watch(currentUserGamePreferencesProvider);
    
    // Also listen for changes
    ref.listen<UserGamePreferences?>(
      currentUserGamePreferencesProvider,
      (previous, next) {
        if (next != null) {
          debugPrint('🔍 DEBUG: Preference change detected!');
          debugPrint('   Category: ${next.preferredCategory.name}');
          debugPrint('   Difficulty: ${next.preferredDifficulty.name}');
          debugPrint('   Question Count: ${next.preferredQuestionCount}');
          debugPrint('   Time Limit: ${next.preferredTimeLimit}');
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Preferences'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Preferences:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (prefs != null) ...[
              _buildPreferenceRow('Category', prefs.preferredCategory.name),
              _buildPreferenceRow('Difficulty', prefs.preferredDifficulty.name),
              _buildPreferenceRow('Question Count', prefs.preferredQuestionCount.toString()),
              _buildPreferenceRow('Time Limit', '${prefs.preferredTimeLimit}s'),
              _buildPreferenceRow('Sound', prefs.soundEnabled.toString()),
              _buildPreferenceRow('Haptic', prefs.hapticFeedbackEnabled.toString()),
              _buildPreferenceRow('Last Updated', prefs.lastPlayed.toString()),
            ] else ...[
              const Text(
                'No preferences loaded',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Keep this screen open\n'
              '2. Go to Settings → Game Preferences\n'
              '3. Change the category to fractions or percentages\n'
              '4. Save the preferences\n'
              '5. Come back here to see if it updated\n'
              '6. Check the debug console for logs',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Force refresh the provider
                ref.invalidate(currentUserGamePreferencesProvider);
              },
              child: const Text('Force Refresh Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
