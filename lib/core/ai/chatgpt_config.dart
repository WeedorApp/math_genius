import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ChatGPT Configuration Management
/// Handles API keys, settings, and configuration for ChatGPT integration
class ChatGPTConfig {
  static const String _apiKeyKey = 'chatgpt_api_key';
  static const String _modelKey = 'chatgpt_model';
  static const String _maxTokensKey = 'chatgpt_max_tokens';
  static const String _temperatureKey = 'chatgpt_temperature';
  static const String _enabledKey = 'chatgpt_enabled';

  final SharedPreferences _prefs;

  ChatGPTConfig(this._prefs);

  /// Get ChatGPT API key
  String get apiKey {
    // First try environment variable
    const envApiKey = String.fromEnvironment(
      'OPENAI_API_KEY',
      defaultValue: '',
    );
    if (envApiKey.isNotEmpty) {
      return envApiKey;
    }

    // Then try stored key
    return _prefs.getString(_apiKeyKey) ?? '';
  }

  /// Set ChatGPT API key
  Future<void> setApiKey(String apiKey) async {
    await _prefs.setString(_apiKeyKey, apiKey);
  }

  /// Get ChatGPT model
  String get model {
    return _prefs.getString(_modelKey) ?? 'gpt-4';
  }

  /// Set ChatGPT model
  Future<void> setModel(String model) async {
    await _prefs.setString(_modelKey, model);
  }

  /// Get max tokens
  int get maxTokens {
    return _prefs.getInt(_maxTokensKey) ?? 2000;
  }

  /// Set max tokens
  Future<void> setMaxTokens(int maxTokens) async {
    await _prefs.setInt(_maxTokensKey, maxTokens);
  }

  /// Get temperature
  double get temperature {
    return _prefs.getDouble(_temperatureKey) ?? 0.7;
  }

  /// Set temperature
  Future<void> setTemperature(double temperature) async {
    await _prefs.setDouble(_temperatureKey, temperature);
  }

  /// Check if ChatGPT is enabled
  bool get isEnabled {
    return _prefs.getBool(_enabledKey) ?? true;
  }

  /// Enable/disable ChatGPT
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
  }

  /// Check if API key is configured
  bool get hasApiKey {
    return apiKey.isNotEmpty;
  }

  /// Get configuration status
  Map<String, dynamic> get status {
    return {
      'hasApiKey': hasApiKey,
      'isEnabled': isEnabled,
      'model': model,
      'maxTokens': maxTokens,
      'temperature': temperature,
    };
  }

  /// Validate API key format
  bool isValidApiKey(String apiKey) {
    // OpenAI API keys start with 'sk-' and are typically 51 characters long
    return apiKey.startsWith('sk-') && apiKey.length >= 20;
  }

  /// Test API key
  Future<bool> testApiKey(String apiKey) async {
    try {
      // This would make a test call to OpenAI API
      // For now, we'll just validate the format
      return isValidApiKey(apiKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error testing API key: $e');
      }
      return false;
    }
  }

  /// Get available models
  List<String> get availableModels {
    return ['gpt-4', 'gpt-4-turbo', 'gpt-3.5-turbo', 'gpt-3.5-turbo-16k'];
  }

  /// Get default configuration
  Map<String, dynamic> get defaultConfig {
    return {
      'model': 'gpt-4',
      'maxTokens': 2000,
      'temperature': 0.7,
      'enabled': true,
    };
  }

  /// Reset to default configuration
  Future<void> resetToDefaults() async {
    await setModel(defaultConfig['model']);
    await setMaxTokens(defaultConfig['maxTokens']);
    await setTemperature(defaultConfig['temperature']);
    await setEnabled(defaultConfig['enabled']);
  }

  /// Export configuration
  Map<String, dynamic> exportConfig() {
    return {
      'apiKey': hasApiKey ? '***' : '', // Don't export actual key
      'model': model,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'enabled': isEnabled,
    };
  }

  /// Import configuration
  Future<void> importConfig(Map<String, dynamic> config) async {
    if (config['model'] != null) await setModel(config['model']);
    if (config['maxTokens'] != null) await setMaxTokens(config['maxTokens']);
    if (config['temperature'] != null) {
      await setTemperature(config['temperature']);
    }
    if (config['enabled'] != null) await setEnabled(config['enabled']);
  }
}

/// Riverpod providers for ChatGPT configuration
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences should be initialized in main.dart',
  );
});

final chatGPTConfigProvider = Provider<ChatGPTConfig>((ref) {
  return ChatGPTConfig(ref.read(sharedPreferencesProvider));
});

final chatGPTStatusProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.read(chatGPTConfigProvider).status;
});

final chatGPTApiKeyProvider = Provider<String>((ref) {
  return ref.read(chatGPTConfigProvider).apiKey;
});

final chatGPTEnabledProvider = Provider<bool>((ref) {
  return ref.read(chatGPTConfigProvider).isEnabled;
});
