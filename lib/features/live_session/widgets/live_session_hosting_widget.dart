import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Core imports
import '../../../core/barrel.dart';

// Live Session imports
import '../barrel.dart';

/// Live Session Hosting Widget - For teachers/parents to host live quizzes
class LiveSessionHostingWidget extends ConsumerStatefulWidget {
  final String hostId;
  final String hostName;

  const LiveSessionHostingWidget({
    super.key,
    required this.hostId,
    required this.hostName,
  });

  @override
  ConsumerState<LiveSessionHostingWidget> createState() =>
      _LiveSessionHostingWidgetState();
}

class _LiveSessionHostingWidgetState
    extends ConsumerState<LiveSessionHostingWidget> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _passwordController = TextEditingController();

  SessionAccessType _selectedAccessType = SessionAccessType.public;
  int _maxParticipants = 50;
  bool _showQRCode = false;
  LiveSession? _currentSession;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_titleController.text.isEmpty) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Please enter a session title',
          isError: true,
        );
      }
      return;
    }

    try {
      final session = await ref
          .read(liveSessionServiceProvider)
          .createLiveSession(
            hostId: widget.hostId,
            hostName: widget.hostName,
            title: _titleController.text,
            description: _descriptionController.text,
            accessType: _selectedAccessType,
            password: _selectedAccessType == SessionAccessType.passwordProtected
                ? _passwordController.text
                : null,
            maxParticipants: _maxParticipants,
          );

      if (mounted) {
        setState(() {
          _currentSession = session;
          _showQRCode = true;
        });

        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Session "${session.title}" created successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error creating session: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _startSession() async {
    if (_currentSession == null) return;

    try {
      final updatedSession = await ref
          .read(liveSessionServiceProvider)
          .startLiveSession(_currentSession!.id);

      if (updatedSession != null && mounted) {
        setState(() {
          _currentSession = updatedSession;
        });

        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Session started!',
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error starting session: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _endSession() async {
    if (_currentSession == null) return;

    try {
      final updatedSession = await ref
          .read(liveSessionServiceProvider)
          .endLiveSession(_currentSession!.id);

      if (updatedSession != null && mounted) {
        setState(() {
          _currentSession = updatedSession;
        });

        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Session ended!',
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error ending session: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Session Hosting'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Creation Form
            if (_currentSession == null) ...[
              Text(
                'Create Live Session',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Title Input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Session Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 16),

              // Description Input
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Access Type Selection
              Text(
                'Access Type',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Column(
                children: SessionAccessType.values.map((type) {
                  return RadioListTile<SessionAccessType>(
                    title: Text(_getAccessTypeLabel(type)),
                    subtitle: Text(_getAccessTypeDescription(type)),
                    value: type,
                    groupValue: _selectedAccessType,
                    onChanged: (value) {
                      setState(() {
                        _selectedAccessType = value!;
                      });
                    },
                  );
                }).toList(),
              ),

              // Password Input (if password protected)
              if (_selectedAccessType ==
                  SessionAccessType.passwordProtected) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  obscureText: true,
                ),
              ],

              const SizedBox(height: 16),

              // Max Participants
              Text(
                'Maximum Participants: $_maxParticipants',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Slider(
                value: _maxParticipants.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _maxParticipants = value.round();
                  });
                },
              ),

              const SizedBox(height: 24),

              // Create Session Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Create Session',
                    style: themeData.typography.labelLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // Session Management
            if (_currentSession != null) ...[
              _buildSessionInfo(_currentSession!, colorScheme, themeData),
              const SizedBox(height: 24),

              // Session Controls
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _currentSession!.status == LiveSessionStatus.waiting
                          ? _startSession
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.secondary,
                        foregroundColor: colorScheme.onSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Start Session',
                        style: themeData.typography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _currentSession!.status == LiveSessionStatus.active
                          ? _endSession
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'End Session',
                        style: themeData.typography.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Participants List
              _buildParticipantsList(
                _currentSession!.id,
                colorScheme,
                themeData,
              ),

              const SizedBox(height: 24),

              // Leaderboard
              _buildLeaderboard(_currentSession!.id, colorScheme, themeData),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo(
    LiveSession session,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Card(
      color: colorScheme.surface,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: themeData.typography.headlineSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (session.description.isNotEmpty)
                        Text(
                          session.description,
                          style: themeData.typography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(session.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.status.name.toUpperCase(),
                    style: themeData.typography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Session Details
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    'Participants',
                    '${session.currentParticipants}/${session.maxParticipants}',
                    Icons.people,
                    colorScheme.primary,
                    themeData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Questions',
                    session.questions.length.toString(),
                    Icons.quiz,
                    colorScheme.secondary,
                    themeData,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    'Access',
                    session.accessType.name,
                    Icons.security,
                    colorScheme.tertiary,
                    themeData,
                  ),
                ),
              ],
            ),

            // QR Code
            if (_showQRCode && session.qrCode != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'QR Code',
                        style: themeData.typography.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Center(
                          child: Text(
                            session.qrCode!,
                            style: themeData.typography.bodySmall.copyWith(
                              color: colorScheme.onSurface,
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Share this code with participants',
                        style: themeData.typography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: themeData.typography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: themeData.typography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsList(
    String sessionId,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder<List<LiveParticipant>>(
          future: ref
              .read(liveSessionServiceProvider)
              .getSessionParticipants(sessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final participants = snapshot.data ?? [];

            return Card(
              color: colorScheme.surface,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participants (${participants.length})',
                      style: themeData.typography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (participants.isEmpty)
                      Center(
                        child: Text(
                          'No participants yet',
                          style: themeData.typography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: participants.map((participant) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              child: Text(
                                participant.name[0].toUpperCase(),
                                style: themeData.typography.labelLarge.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              participant.name,
                              style: themeData.typography.labelLarge.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Score: ${participant.score} | Correct: ${participant.correctAnswers}/${participant.totalQuestions}',
                              style: themeData.typography.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: participant.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                participant.isActive ? 'Active' : 'Left',
                                style: themeData.typography.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboard(
    String sessionId,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder<List<LiveParticipant>>(
          future: ref
              .read(liveSessionServiceProvider)
              .getSessionLeaderboard(sessionId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final leaderboard = snapshot.data ?? [];

            return Card(
              color: colorScheme.surface,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leaderboard',
                      style: themeData.typography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (leaderboard.isEmpty)
                      Center(
                        child: Text(
                          'No participants yet',
                          style: themeData.typography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: leaderboard.asMap().entries.map((entry) {
                          final index = entry.key;
                          final participant = entry.value;
                          final isTopThree = index < 3;

                          return ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isTopThree
                                    ? _getTopThreeColor(index)
                                    : colorScheme.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: themeData.typography.labelLarge
                                      .copyWith(
                                        color: isTopThree
                                            ? Colors.white
                                            : colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                            title: Text(
                              participant.name,
                              style: themeData.typography.labelLarge.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Score: ${participant.score} | Accuracy: ${participant.totalQuestions > 0 ? (participant.correctAnswers / participant.totalQuestions * 100).toStringAsFixed(1) : 0}%',
                              style: themeData.typography.bodySmall.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(
                              '${participant.score} pts',
                              style: themeData.typography.titleMedium.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getAccessTypeLabel(SessionAccessType type) {
    switch (type) {
      case SessionAccessType.public:
        return 'Public';
      case SessionAccessType.private:
        return 'Private';
      case SessionAccessType.inviteOnly:
        return 'Invite Only';
      case SessionAccessType.passwordProtected:
        return 'Password Protected';
    }
  }

  String _getAccessTypeDescription(SessionAccessType type) {
    switch (type) {
      case SessionAccessType.public:
        return 'Anyone can join with the QR code';
      case SessionAccessType.private:
        return 'Only invited participants can join';
      case SessionAccessType.inviteOnly:
        return 'Requires invitation from host';
      case SessionAccessType.passwordProtected:
        return 'Requires password to join';
    }
  }

  Color _getStatusColor(LiveSessionStatus status) {
    switch (status) {
      case LiveSessionStatus.waiting:
        return Colors.orange;
      case LiveSessionStatus.active:
        return Colors.green;
      case LiveSessionStatus.paused:
        return Colors.yellow;
      case LiveSessionStatus.completed:
        return Colors.blue;
      case LiveSessionStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getTopThreeColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}
