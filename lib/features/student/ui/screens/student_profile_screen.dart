import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/barrel.dart';
import '../components/student_header.dart';

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const StudentHeader(),
          Expanded(
            child: Center(
              child: Text(
                'Profile - Coming Soon',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
