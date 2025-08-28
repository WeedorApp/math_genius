import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

// Core imports
import '../../../core/barrel.dart';

// ChatGPT Configuration
import '../../../core/ai/chatgpt_config.dart';

/// ChatGPT Settings Screen
/// Manages API keys, model selection, and ChatGPT configuration
class ChatGPTSettingsScreen extends ConsumerStatefulWidget {
  const ChatGPTSettingsScreen({super.key});

  @override
  ConsumerState<ChatGPTSettingsScreen> createState() =>
      _ChatGPTSettingsScreenState();
}

class _ChatGPTSettingsScreenState extends ConsumerState<ChatGPTSettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _maxTokensController = TextEditingController();
  final _temperatureController = TextEditingController();
  bool _isLoading = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _maxTokensController.dispose();
    _temperatureController.dispose();
    super.dispose();
  }

  void _loadCurrentSettings() {
    final config = ref.read(chatGPTConfigProvider);
    _apiKeyController.text = config.hasApiKey
        ? '••••••••••••••••••••••••••••••••••••••••••••••••••'
        : '';
    _maxTokensController.text = config.maxTokens.toString();
    _temperatureController.text = config.temperature.toString();
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showSnackBar('Please enter an API key', isError: true);
      return;
    }

    final config = ref.read(chatGPTConfigProvider);
    if (!config.isValidApiKey(apiKey)) {
      _showSnackBar(
        'Invalid API key format. OpenAI keys start with "sk-"',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await config.setApiKey(apiKey);
      _showSnackBar('API key saved successfully');
      ref.invalidate(chatGPTApiKeyProvider);
    } catch (e) {
      _showSnackBar('Failed to save API key: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      _showSnackBar('Please enter an API key first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final config = ref.read(chatGPTConfigProvider);
      final isValid = await config.testApiKey(apiKey);

      setState(() {
        _testResult = isValid ? 'API key is valid!' : 'API key test failed';
      });

      if (isValid) {
        _showSnackBar('API key test successful');
      } else {
        _showSnackBar('API key test failed', isError: true);
      }
    } catch (e) {
      setState(() {
        _testResult = 'Error testing API key: $e';
      });
      _showSnackBar('Error testing API key: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveModel(String model) async {
    try {
      final config = ref.read(chatGPTConfigProvider);
      await config.setModel(model);
      _showSnackBar('Model updated to $model');
      ref.invalidate(chatGPTStatusProvider);
    } catch (e) {
      _showSnackBar('Failed to update model: $e', isError: true);
    }
  }

  Future<void> _saveMaxTokens() async {
    final maxTokens = int.tryParse(_maxTokensController.text);
    if (maxTokens == null || maxTokens < 1 || maxTokens > 4000) {
      _showSnackBar(
        'Please enter a valid number between 1 and 4000',
        isError: true,
      );
      return;
    }

    try {
      final config = ref.read(chatGPTConfigProvider);
      await config.setMaxTokens(maxTokens);
      _showSnackBar('Max tokens updated to $maxTokens');
      ref.invalidate(chatGPTStatusProvider);
    } catch (e) {
      _showSnackBar('Failed to update max tokens: $e', isError: true);
    }
  }

  Future<void> _saveTemperature() async {
    final temperature = double.tryParse(_temperatureController.text);
    if (temperature == null || temperature < 0.0 || temperature > 2.0) {
      _showSnackBar(
        'Please enter a valid number between 0.0 and 2.0',
        isError: true,
      );
      return;
    }

    try {
      final config = ref.read(chatGPTConfigProvider);
      await config.setTemperature(temperature);
      _showSnackBar('Temperature updated to $temperature');
      ref.invalidate(chatGPTStatusProvider);
    } catch (e) {
      _showSnackBar('Failed to update temperature: $e', isError: true);
    }
  }

  Future<void> _toggleEnabled(bool enabled) async {
    try {
      final config = ref.read(chatGPTConfigProvider);
      await config.setEnabled(enabled);
      _showSnackBar(enabled ? 'ChatGPT enabled' : 'ChatGPT disabled');
      ref.invalidate(chatGPTEnabledProvider);
    } catch (e) {
      _showSnackBar('Failed to update ChatGPT status: $e', isError: true);
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      final config = ref.read(chatGPTConfigProvider);
      await config.resetToDefaults();
      _loadCurrentSettings();
      _showSnackBar('Settings reset to defaults');
      ref.invalidate(chatGPTStatusProvider);
    } catch (e) {
      _showSnackBar('Failed to reset settings: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    AdaptiveUISystem.showAdaptiveSnackBar(
      context: context,
      message: message,
      isError: isError,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final status = ref.watch(chatGPTStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ChatGPT Settings',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              _buildStatusCard(themeData, colorScheme, status),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),

              // API Key Section
              _buildApiKeySection(themeData, colorScheme),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),

              // Model Selection
              _buildModelSection(themeData, colorScheme),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),

              // Advanced Settings
              _buildAdvancedSettings(themeData, colorScheme),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),

              // Test Results
              if (_testResult != null) ...[
                _buildTestResultCard(themeData, colorScheme),
                SizedBox(height: context.adaptiveLayout.sectionSpacing),
              ],

              // Help Section
              _buildHelpSection(themeData, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Map<String, dynamic> status,
  ) {
    final hasApiKey = status['hasApiKey'] as bool;
    final isEnabled = status['isEnabled'] as bool;
    final model = status['model'] as String;

    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colorScheme.primary, size: 24),
              SizedBox(width: context.adaptiveLayout.cardSpacing / 1.5),
              Text(
                'ChatGPT Status',
                style: themeData.typography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing),
          _buildStatusRow(
            'API Key',
            hasApiKey ? 'Configured' : 'Not configured',
            hasApiKey ? Colors.green : Colors.red,
            themeData,
            colorScheme,
          ),
          _buildStatusRow(
            'Enabled',
            isEnabled ? 'Yes' : 'No',
            isEnabled ? Colors.green : Colors.orange,
            themeData,
            colorScheme,
          ),
          _buildStatusRow('Model', model, Colors.blue, themeData, colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    String value,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: themeData.typography.bodyMedium.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: themeData.typography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeySection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API Key Configuration',
            style: themeData.typography.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing),
          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: 'OpenAI API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _apiKeyController.text),
                  );
                  _showSnackBar('API key copied to clipboard');
                },
                icon: const Icon(Icons.copy),
              ),
            ),
            obscureText: true,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveApiKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save API Key'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _testApiKey,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                  child: const Text('Test API Key'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final config = ref.read(chatGPTConfigProvider);
    final currentModel = config.model;
    final availableModels = config.availableModels;

    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Model Selection',
            style: themeData.typography.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing),
          DropdownButtonFormField<String>(
            value: currentModel,
            decoration: InputDecoration(
              labelText: 'ChatGPT Model',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: availableModels.map((model) {
              return DropdownMenuItem(value: model, child: Text(model));
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                _saveModel(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Settings',
            style: themeData.typography.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing),
          TextField(
            controller: _maxTokensController,
            decoration: InputDecoration(
              labelText: 'Max Tokens (1-4000)',
              hintText: '2000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _saveMaxTokens(),
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing),
          TextField(
            controller: _temperatureController,
            decoration: InputDecoration(
              labelText: 'Temperature (0.0-2.0)',
              hintText: '0.7',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _saveTemperature(),
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing),
          SwitchListTile(
            title: Text(
              'Enable ChatGPT',
              style: themeData.typography.bodyLarge.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Enable or disable ChatGPT integration',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            value: ref.watch(chatGPTEnabledProvider),
            onChanged: _toggleEnabled,
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final isSuccess =
        _testResult!.contains('valid') || _testResult!.contains('successful');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _testResult!,
              style: themeData.typography.bodyMedium.copyWith(
                color: isSuccess ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Help & Information',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            'Getting an API Key',
            'Visit openai.com to create an account and get your API key',
            Icons.key,
            themeData,
            colorScheme,
          ),
          _buildHelpItem(
            'Model Selection',
            'GPT-4 is recommended for best results. GPT-3.5 is faster but less capable',
            Icons.psychology,
            themeData,
            colorScheme,
          ),
          _buildHelpItem(
            'Temperature',
            'Lower values (0.0-0.5) make responses more focused. Higher values (0.7-1.0) make them more creative',
            Icons.thermostat,
            themeData,
            colorScheme,
          ),
          _buildHelpItem(
            'Max Tokens',
            'Controls response length. Higher values allow longer, more detailed responses',
            Icons.text_fields,
            themeData,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(
    String title,
    String description,
    IconData icon,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: themeData.typography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: themeData.typography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
