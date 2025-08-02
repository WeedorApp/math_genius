import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// Privacy compliance types
enum PrivacyCompliance { gdpr, ccpa, coppa, ferpa }

/// Data retention policies
enum DataRetentionPolicy {
  immediate, // Delete immediately
  thirtyDays, // Keep for 30 days
  ninetyDays, // Keep for 90 days
  oneYear, // Keep for 1 year
  indefinite, // Keep indefinitely
}

/// Privacy settings model
class PrivacySettings {
  final bool allowAnalytics;
  final bool allowCrashReporting;
  final bool allowPersonalization;
  final bool allowDataSharing;
  final bool allowPushNotifications;
  final DataRetentionPolicy dataRetention;
  final Map<PrivacyCompliance, bool> complianceConsent;
  final bool isOfflineMode;

  const PrivacySettings({
    this.allowAnalytics = true,
    this.allowCrashReporting = true,
    this.allowPersonalization = true,
    this.allowDataSharing = false,
    this.allowPushNotifications = true,
    this.dataRetention = DataRetentionPolicy.ninetyDays,
    this.complianceConsent = const {},
    this.isOfflineMode = false,
  });

  PrivacySettings copyWith({
    bool? allowAnalytics,
    bool? allowCrashReporting,
    bool? allowPersonalization,
    bool? allowDataSharing,
    bool? allowPushNotifications,
    DataRetentionPolicy? dataRetention,
    Map<PrivacyCompliance, bool>? complianceConsent,
    bool? isOfflineMode,
  }) {
    return PrivacySettings(
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowCrashReporting: allowCrashReporting ?? this.allowCrashReporting,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
      allowDataSharing: allowDataSharing ?? this.allowDataSharing,
      allowPushNotifications:
          allowPushNotifications ?? this.allowPushNotifications,
      dataRetention: dataRetention ?? this.dataRetention,
      complianceConsent: complianceConsent ?? this.complianceConsent,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowAnalytics': allowAnalytics,
      'allowCrashReporting': allowCrashReporting,
      'allowPersonalization': allowPersonalization,
      'allowDataSharing': allowDataSharing,
      'allowPushNotifications': allowPushNotifications,
      'dataRetention': dataRetention.name,
      'complianceConsent': complianceConsent.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'isOfflineMode': isOfflineMode,
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
      allowCrashReporting: json['allowCrashReporting'] as bool? ?? true,
      allowPersonalization: json['allowPersonalization'] as bool? ?? true,
      allowDataSharing: json['allowDataSharing'] as bool? ?? false,
      allowPushNotifications: json['allowPushNotifications'] as bool? ?? true,
      dataRetention: DataRetentionPolicy.values.firstWhere(
        (e) => e.name == json['dataRetention'],
        orElse: () => DataRetentionPolicy.ninetyDays,
      ),
      complianceConsent:
          (json['complianceConsent'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              PrivacyCompliance.values.firstWhere((e) => e.name == key),
              value as bool,
            ),
          ) ??
          {},
      isOfflineMode: json['isOfflineMode'] as bool? ?? false,
    );
  }
}

/// Privacy service for Math Genius
class PrivacyService {
  static const String _privacySettingsKey = 'privacy_settings';

  final SharedPreferences _prefs;
  final Box? _hiveBox;

  PrivacyService(this._prefs, this._hiveBox);

  /// Get current privacy settings
  Future<PrivacySettings> getPrivacySettings() async {
    final settingsString = _prefs.getString(_privacySettingsKey);
    if (settingsString == null) {
      return const PrivacySettings();
    }

    try {
      final json = Map<String, dynamic>.from(
        jsonDecode(settingsString) as Map<String, dynamic>,
      );
      return PrivacySettings.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading privacy settings: $e');
      }
      return const PrivacySettings();
    }
  }

  /// Save privacy settings
  Future<void> savePrivacySettings(PrivacySettings settings) async {
    await _prefs.setString(_privacySettingsKey, jsonEncode(settings.toJson()));
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings(PrivacySettings settings) async {
    await savePrivacySettings(settings);
  }

  /// Check GDPR compliance
  Future<bool> isGDPRCompliant() async {
    final settings = await getPrivacySettings();
    return settings.complianceConsent[PrivacyCompliance.gdpr] ?? false;
  }

  /// Set GDPR consent
  Future<void> setGDPRConsent(bool consent) async {
    final settings = await getPrivacySettings();
    final updatedConsent = Map<PrivacyCompliance, bool>.from(
      settings.complianceConsent,
    );
    updatedConsent[PrivacyCompliance.gdpr] = consent;

    final updatedSettings = settings.copyWith(
      complianceConsent: updatedConsent,
    );
    await savePrivacySettings(updatedSettings);
  }

  /// Check if offline mode is enabled
  Future<bool> isOfflineMode() async {
    final settings = await getPrivacySettings();
    return settings.isOfflineMode;
  }

  /// Set offline mode
  Future<void> setOfflineMode(bool enabled) async {
    final settings = await getPrivacySettings();
    final updatedSettings = settings.copyWith(isOfflineMode: enabled);
    await savePrivacySettings(updatedSettings);
  }

  /// Delete user account and all associated data
  Future<void> deleteAccount(String userId) async {
    try {
      // Delete from SharedPreferences
      await _prefs.clear();

      // Delete from Hive database
      if (_hiveBox != null) {
        await _hiveBox.clear();
      }

      // Delete local files
      await _deleteLocalFiles();

      // Delete from Firebase (if connected)
      await _deleteFromFirebase(userId);

      if (kDebugMode) {
        print('Account and data deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      rethrow;
    }
  }

  /// Delete local files
  Future<void> _deleteLocalFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final appSupportDir = await getApplicationSupportDirectory();
      final tempDir = await getTemporaryDirectory();

      // Delete app documents directory
      if (await appDir.exists()) {
        await appDir.delete(recursive: true);
      }

      // Delete app support directory
      if (await appSupportDir.exists()) {
        await appSupportDir.delete(recursive: true);
      }

      // Delete temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting local files: $e');
      }
    }
  }

  /// Delete from Firebase (placeholder for future implementation)
  Future<void> _deleteFromFirebase(String userId) async {
    // Todo: Implement Firebase deletion when Firebase is added
    if (kDebugMode) {
      print('Firebase deletion not implemented yet');
    }
  }

  /// Get data retention policy
  Future<DataRetentionPolicy> getDataRetentionPolicy() async {
    final settings = await getPrivacySettings();
    return settings.dataRetention;
  }

  /// Set data retention policy
  Future<void> setDataRetentionPolicy(DataRetentionPolicy policy) async {
    final settings = await getPrivacySettings();
    final updatedSettings = settings.copyWith(dataRetention: policy);
    await savePrivacySettings(updatedSettings);
  }

  /// Clean up old data based on retention policy
  Future<void> cleanupOldData() async {
    final policy = await getDataRetentionPolicy();
    final now = DateTime.now();

    switch (policy) {
      case DataRetentionPolicy.immediate:
        // Delete all data immediately
        await _deleteAllData();
        break;
      case DataRetentionPolicy.thirtyDays:
        await _deleteDataOlderThan(now.subtract(const Duration(days: 30)));
        break;
      case DataRetentionPolicy.ninetyDays:
        await _deleteDataOlderThan(now.subtract(const Duration(days: 90)));
        break;
      case DataRetentionPolicy.oneYear:
        await _deleteDataOlderThan(now.subtract(const Duration(days: 365)));
        break;
      case DataRetentionPolicy.indefinite:
        // Don't delete any data
        break;
    }
  }

  /// Delete all data
  Future<void> _deleteAllData() async {
    try {
      // Clear SharedPreferences
      await _prefs.clear();

      // Clear Hive database
      if (_hiveBox != null) {
        await _hiveBox.clear();
      }

      // Delete local files
      await _deleteLocalFiles();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all data: $e');
      }
    }
  }

  /// Delete data older than specified date
  Future<void> _deleteDataOlderThan(DateTime cutoffDate) async {
    try {
      // This is a placeholder implementation
      // In a real app, you would query your database for old records
      if (kDebugMode) {
        print('Deleting data older than: $cutoffDate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting old data: $e');
      }
    }
  }

  /// Get privacy policy URL based on user role
  String getPrivacyPolicyUrl(String userRole) {
    switch (userRole.toLowerCase()) {
      case 'parent':
        return 'https://mathgenius.com/privacy/parent';
      case 'teacher':
        return 'https://mathgenius.com/privacy/teacher';
      case 'school':
        return 'https://mathgenius.com/privacy/school';
      case 'student':
      default:
        return 'https://mathgenius.com/privacy/student';
    }
  }

  /// Get terms of service URL based on user role
  String getTermsOfServiceUrl(String userRole) {
    switch (userRole.toLowerCase()) {
      case 'parent':
        return 'https://mathgenius.com/terms/parent';
      case 'teacher':
        return 'https://mathgenius.com/terms/teacher';
      case 'school':
        return 'https://mathgenius.com/terms/school';
      case 'student':
      default:
        return 'https://mathgenius.com/terms/student';
    }
  }

  /// Export user data
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final data = <String, dynamic>{};

      // Export SharedPreferences data
      final prefsData = <String, dynamic>{};
      for (final key in _prefs.getKeys()) {
        prefsData[key] = _prefs.get(key);
      }
      data['shared_preferences'] = prefsData;

      // Export Hive data
      if (_hiveBox != null) {
        final hiveData = <String, dynamic>{};
        for (final key in _hiveBox.keys) {
          hiveData[key.toString()] = _hiveBox.get(key);
        }
        data['hive_database'] = hiveData;
      }

      // Add metadata
      data['export_timestamp'] = DateTime.now().toIso8601String();
      data['user_id'] = userId;
      data['app_version'] = '1.0.0';

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting user data: $e');
      }
      rethrow;
    }
  }

  /// Check if analytics are allowed
  Future<bool> isAnalyticsAllowed() async {
    final settings = await getPrivacySettings();
    return settings.allowAnalytics;
  }

  /// Check if crash reporting is allowed
  Future<bool> isCrashReportingAllowed() async {
    final settings = await getPrivacySettings();
    return settings.allowCrashReporting;
  }

  /// Check if personalization is allowed
  Future<bool> isPersonalizationAllowed() async {
    final settings = await getPrivacySettings();
    return settings.allowPersonalization;
  }

  /// Check if data sharing is allowed
  Future<bool> isDataSharingAllowed() async {
    final settings = await getPrivacySettings();
    return settings.allowDataSharing;
  }

  /// Check if push notifications are allowed
  Future<bool> isPushNotificationsAllowed() async {
    final settings = await getPrivacySettings();
    return settings.allowPushNotifications;
  }
}

/// Riverpod providers for privacy management
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  throw UnimplementedError('PrivacyService must be initialized');
});

final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
      return PrivacySettingsNotifier(ref.read(privacyServiceProvider));
    });

/// State notifier for privacy settings
class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  final PrivacyService _service;

  PrivacySettingsNotifier(this._service) : super(const PrivacySettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = await _service.getPrivacySettings();
  }

  Future<void> updateSettings(PrivacySettings settings) async {
    await _service.savePrivacySettings(settings);
    state = settings;
  }

  Future<void> setGDPRConsent(bool consent) async {
    await _service.setGDPRConsent(consent);
    await _loadSettings();
  }

  Future<void> setOfflineMode(bool enabled) async {
    await _service.setOfflineMode(enabled);
    await _loadSettings();
  }

  Future<void> setDataRetentionPolicy(DataRetentionPolicy policy) async {
    await _service.setDataRetentionPolicy(policy);
    await _loadSettings();
  }
}
