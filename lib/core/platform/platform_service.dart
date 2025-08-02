import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Platform types supported by Math Genius
enum PlatformType { ios, android, web, desktop, unknown }

/// Platform service for platform-aware utilities
class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PlatformType? _platformType;
  Map<String, dynamic>? _deviceInfoData;

  /// Get the current platform type
  PlatformType get platformType {
    if (_platformType != null) return _platformType!;

    if (kIsWeb) {
      _platformType = PlatformType.web;
    } else {
      // For mobile platforms, we'll detect them from device info
      _platformType = PlatformType.unknown;
    }

    return _platformType!;
  }

  /// Get detailed device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_deviceInfoData != null) return _deviceInfoData!;

    try {
      final deviceInfo = await _deviceInfo.deviceInfo;
      Map<String, dynamic> info = {};

      switch (platformType) {
        case PlatformType.android:
          if (deviceInfo is AndroidDeviceInfo) {
            info = {
              'platform': 'android',
              'model': deviceInfo.model,
              'brand': deviceInfo.brand,
              'device': deviceInfo.device,
              'product': deviceInfo.product,
              'androidVersion': deviceInfo.version.release,
              'sdkInt': deviceInfo.version.sdkInt,
              'manufacturer': deviceInfo.manufacturer,
              'isPhysicalDevice': deviceInfo.isPhysicalDevice,
            };
          }
          break;
        case PlatformType.ios:
          if (deviceInfo is IosDeviceInfo) {
            info = {
              'platform': 'ios',
              'model': deviceInfo.model,
              'name': deviceInfo.name,
              'systemName': deviceInfo.systemName,
              'systemVersion': deviceInfo.systemVersion,
              'localizedModel': deviceInfo.localizedModel,
              'identifierForVendor': deviceInfo.identifierForVendor,
              'isPhysicalDevice': deviceInfo.isPhysicalDevice,
            };
          }
          break;
        case PlatformType.web:
          info = {'platform': 'web', 'userAgent': deviceInfo.toString()};
          break;
        case PlatformType.desktop:
          if (deviceInfo is MacOsDeviceInfo) {
            info = {
              'platform': 'macos',
              'model': deviceInfo.model,
              'computerName': deviceInfo.computerName,
              'osRelease': deviceInfo.osRelease,
              'activeCPUs': deviceInfo.activeCPUs,
            };
          } else if (deviceInfo is WindowsDeviceInfo) {
            info = {
              'platform': 'windows',
              'computerName': deviceInfo.computerName,
              'majorVersion': deviceInfo.majorVersion,
              'minorVersion': deviceInfo.minorVersion,
              'buildNumber': deviceInfo.buildNumber,
            };
          } else if (deviceInfo is LinuxDeviceInfo) {
            info = {
              'platform': 'linux',
              'name': deviceInfo.name,
              'version': deviceInfo.version,
              'id': deviceInfo.id,
              'versionCodename': deviceInfo.versionCodename,
            };
          }
          break;
        case PlatformType.unknown:
          info = {'platform': 'unknown', 'deviceInfo': deviceInfo.toString()};
          break;
      }

      _deviceInfoData = info;
      return info;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device info: $e');
      }
      return {'platform': platformType.name, 'error': e.toString()};
    }
  }

  /// Get platform-specific animation duration
  Duration getAnimationDuration(AnimationType type) {
    switch (platformType) {
      case PlatformType.ios:
        switch (type) {
          case AnimationType.fast:
            return const Duration(milliseconds: 200);
          case AnimationType.normal:
            return const Duration(milliseconds: 300);
          case AnimationType.slow:
            return const Duration(milliseconds: 500);
        }
      case PlatformType.android:
        switch (type) {
          case AnimationType.fast:
            return const Duration(milliseconds: 150);
          case AnimationType.normal:
            return const Duration(milliseconds: 250);
          case AnimationType.slow:
            return const Duration(milliseconds: 400);
        }
      case PlatformType.web:
      case PlatformType.desktop:
        switch (type) {
          case AnimationType.fast:
            return const Duration(milliseconds: 100);
          case AnimationType.normal:
            return const Duration(milliseconds: 200);
          case AnimationType.slow:
            return const Duration(milliseconds: 300);
        }
      case PlatformType.unknown:
        return const Duration(milliseconds: 300);
    }
  }

  /// Get platform-specific curve
  Curve getAnimationCurve(AnimationType type) {
    switch (platformType) {
      case PlatformType.ios:
        return Curves.easeInOut;
      case PlatformType.android:
        return Curves.fastOutSlowIn;
      case PlatformType.web:
      case PlatformType.desktop:
        return Curves.easeInOut;
      case PlatformType.unknown:
        return Curves.easeInOut;
    }
  }

  /// Get platform-specific dialog style
  DialogStyle getDialogStyle() {
    switch (platformType) {
      case PlatformType.ios:
        return DialogStyle.cupertino;
      case PlatformType.android:
        return DialogStyle.material;
      case PlatformType.web:
      case PlatformType.desktop:
        return DialogStyle.material;
      case PlatformType.unknown:
        return DialogStyle.material;
    }
  }

  /// Request platform-specific permissions
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    Permission permission;

    switch (type) {
      case PermissionType.camera:
        permission = Permission.camera;
        break;
      case PermissionType.microphone:
        permission = Permission.microphone;
        break;
      case PermissionType.storage:
        permission = Permission.storage;
        break;
      case PermissionType.notification:
        permission = Permission.notification;
        break;
      case PermissionType.location:
        permission = Permission.location;
        break;
    }

    return await permission.request();
  }

  /// Check if permission is granted
  Future<bool> isPermissionGranted(PermissionType type) async {
    Permission permission;

    switch (type) {
      case PermissionType.camera:
        permission = Permission.camera;
        break;
      case PermissionType.microphone:
        permission = Permission.microphone;
        break;
      case PermissionType.storage:
        permission = Permission.storage;
        break;
      case PermissionType.notification:
        permission = Permission.notification;
        break;
      case PermissionType.location:
        permission = Permission.location;
        break;
    }

    return await permission.isGranted;
  }

  /// Get platform-specific haptic feedback
  void triggerHapticFeedback(HapticFeedbackType type) {
    switch (platformType) {
      case PlatformType.ios:
        switch (type) {
          case HapticFeedbackType.light:
            HapticFeedback.lightImpact();
            break;
          case HapticFeedbackType.medium:
            HapticFeedback.mediumImpact();
            break;
          case HapticFeedbackType.heavy:
            HapticFeedback.heavyImpact();
            break;
          case HapticFeedbackType.selection:
            HapticFeedback.selectionClick();
            break;
        }
        break;
      case PlatformType.android:
        switch (type) {
          case HapticFeedbackType.light:
            HapticFeedback.lightImpact();
            break;
          case HapticFeedbackType.medium:
            HapticFeedback.mediumImpact();
            break;
          case HapticFeedbackType.heavy:
            HapticFeedback.heavyImpact();
            break;
          case HapticFeedbackType.selection:
            HapticFeedback.selectionClick();
            break;
        }
        break;
      case PlatformType.web:
      case PlatformType.desktop:
      case PlatformType.unknown:
        // No haptic feedback on web/desktop
        break;
    }
  }

  /// Check if device supports specific features
  bool supportsFeature(DeviceFeature feature) {
    switch (feature) {
      case DeviceFeature.hapticFeedback:
        return platformType == PlatformType.ios ||
            platformType == PlatformType.android;
      case DeviceFeature.camera:
        return platformType == PlatformType.ios ||
            platformType == PlatformType.android;
      case DeviceFeature.microphone:
        return platformType == PlatformType.ios ||
            platformType == PlatformType.android;
      case DeviceFeature.biometric:
        return platformType == PlatformType.ios ||
            platformType == PlatformType.android;
      case DeviceFeature.pushNotifications:
        return platformType == PlatformType.ios ||
            platformType == PlatformType.android;
      case DeviceFeature.backgroundProcessing:
        return platformType == PlatformType.ios ||
            platformType == PlatformType.android;
    }
  }
}

/// Animation types for platform-specific durations
enum AnimationType { fast, normal, slow }

/// Dialog styles for different platforms
enum DialogStyle { material, cupertino }

/// Permission types
enum PermissionType { camera, microphone, storage, notification, location }

/// Haptic feedback types
enum HapticFeedbackType { light, medium, heavy, selection }

/// Device features
enum DeviceFeature {
  hapticFeedback,
  camera,
  microphone,
  biometric,
  pushNotifications,
  backgroundProcessing,
}

/// Riverpod provider for platform service
final platformServiceProvider = Provider<PlatformService>((ref) {
  return PlatformService();
});
