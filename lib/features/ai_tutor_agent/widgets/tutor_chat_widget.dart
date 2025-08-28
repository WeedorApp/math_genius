import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

// Core imports
import '../../../core/barrel.dart';

// AI Tutor imports
import '../barrel.dart';

/// AI Tutor Chat Widget
class TutorChatWidget extends ConsumerStatefulWidget {
  final String sessionId;
  final String studentId;
  final int grade;

  const TutorChatWidget({
    super.key,
    required this.sessionId,
    required this.studentId,
    required this.grade,
  });

  @override
  ConsumerState<TutorChatWidget> createState() => _TutorChatWidgetState();
}

class _TutorChatWidgetState extends ConsumerState<TutorChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  TutorSession? _currentSession;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeSession() async {
    try {
      final aiTutorService = ref.read(aiTutorServiceProvider);

      // Initialize voice interface
      await aiTutorService.initializeVoiceInterface();

      // Create or get existing session
      _currentSession = await aiTutorService.createTutorSession(
        widget.studentId,
        widget.grade,
      );

      // Send welcome message
      await aiTutorService.sendMessage(
        _currentSession!.id,
        'Hello! I\'m your AI Math Tutor. How can I help you today?',
        true,
        mode: TutorMode.hint,
      );

      setState(() {});
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error initializing tutor session: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentSession == null) return;

    try {
      final aiTutorService = ref.read(aiTutorServiceProvider);

      // Send student message
      await aiTutorService.sendMessage(_currentSession!.id, message, false);

      _messageController.clear();

      // Generate AI response
      final aiResponse = await aiTutorService.generateAIResponse(
        _currentSession!.id,
        message,
      );

      // Speak the response
      await aiTutorService.speakText(aiResponse.content);

      setState(() {});
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error sending message: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _startListening() async {
    if (_currentSession == null) return;

    try {
      setState(() {
        _isListening = true;
      });

      final aiTutorService = ref.read(aiTutorServiceProvider);
      final speechText = await aiTutorService.listenForSpeech();

      if (speechText != null && speechText.isNotEmpty) {
        _messageController.text = speechText;
        await _sendMessage();
      }

      setState(() {
        _isListening = false;
      });
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error listening for speech: $e',
          isError: true,
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'AI Math Tutor',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _isListening ? null : _startListening,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _currentSession == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing AI Tutor...',
                          style: themeData.typography.bodyLarge.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )
                : Consumer(
                    builder: (context, ref, child) {
                      return FutureBuilder<TutorSession?>(
                        future: ref
                            .read(aiTutorServiceProvider)
                            .getTutorSession(_currentSession!.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final session = snapshot.data;
                          if (session == null) {
                            return const Center(
                              child: Text('Session not found'),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: session.messages.length,
                            itemBuilder: (context, index) {
                              final message = session.messages[index];
                              return _buildMessageBubble(
                                message,
                                colorScheme,
                                themeData,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: colorScheme.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    TutorMessage message,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    final isFromTutor = message.isFromTutor;

    final backgroundColor = isFromTutor
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final textColor = isFromTutor
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromTutor
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isFromTutor) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary,
              child: Icon(Icons.school, size: 16, color: colorScheme.onPrimary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isFromTutor ? const Radius.circular(4) : null,
                  bottomRight: !isFromTutor ? const Radius.circular(4) : null,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: themeData.typography.bodyMedium.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: themeData.typography.bodySmall.copyWith(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isFromTutor) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// AI Tutor Panel Screen
class TutorPanelScreen extends ConsumerWidget {
  final String studentId;
  final int grade;

  const TutorPanelScreen({
    super.key,
    required this.studentId,
    required this.grade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'AI Math Tutor',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome card
            Card(
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to AI Math Tutor!',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'I\'m here to help you with math problems. Ask me anything!',
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildQuickActionCard(
                    context,
                    'Ask for Help',
                    Icons.help_outline,
                    () => _startChat(context),
                    colorScheme,
                    themeData,
                  ),
                  _buildQuickActionCard(
                    context,
                    'Get a Hint',
                    Icons.lightbulb_outline,
                    () => _getHint(context),
                    colorScheme,
                    themeData,
                  ),
                  _buildQuickActionCard(
                    context,
                    'Practice',
                    Icons.fitness_center,
                    () => _startPractice(context),
                    colorScheme,
                    themeData,
                  ),
                  _buildQuickActionCard(
                    context,
                    'Voice Chat',
                    Icons.mic,
                    () => _startVoiceChat(context),
                    colorScheme,
                    themeData,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Card(
      color: colorScheme.surface,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: themeData.typography.labelLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TutorChatWidget(
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
          studentId: studentId,
          grade: grade,
        ),
      ),
    );
  }

  void _getHint(BuildContext context) {
    // Todo: Implement hint generation
    AdaptiveUISystem.showAdaptiveSnackBar(
      context: context,
      message: 'Hint feature coming soon!',
    );
  }

  void _startPractice(BuildContext context) {
    // Todo: Implement practice mode
    AdaptiveUISystem.showAdaptiveSnackBar(
      context: context,
      message: 'Practice mode coming soon!',
    );
  }

  void _startVoiceChat(BuildContext context) {
    _startChat(context);
  }
}
