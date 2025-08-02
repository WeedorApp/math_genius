import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';

/// User roles in the Math Genius system
enum UserRole { student, parent, teacher, school }

/// User context containing role, ID, and current device info
class UserContext {
  final String userId;
  final UserRole role;
  final String deviceId;
  final DateTime lastActive;
  final bool isOnline;

  const UserContext({
    required this.userId,
    required this.role,
    required this.deviceId,
    required this.lastActive,
    this.isOnline = false,
  });

  UserContext copyWith({
    String? userId,
    UserRole? role,
    String? deviceId,
    DateTime? lastActive,
    bool? isOnline,
  }) {
    return UserContext(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      deviceId: deviceId ?? this.deviceId,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role.name,
      'deviceId': deviceId,
      'lastActive': lastActive.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory UserContext.fromJson(Map<String, dynamic> json) {
    return UserContext(
      userId: json['userId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      deviceId: json['deviceId'] as String,
      lastActive: DateTime.parse(json['lastActive'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }
}

/// Device context containing screen type and platform info
class DeviceContext {
  final String platform;
  final String deviceModel;
  final String osVersion;
  final double screenWidth;
  final double screenHeight;
  final double pixelRatio;
  final bool isTablet;
  final bool isLandscape;

  const DeviceContext({
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.screenWidth,
    required this.screenHeight,
    required this.pixelRatio,
    required this.isTablet,
    required this.isLandscape,
  });

  DeviceContext copyWith({
    String? platform,
    String? deviceModel,
    String? osVersion,
    double? screenWidth,
    double? screenHeight,
    double? pixelRatio,
    bool? isTablet,
    bool? isLandscape,
  }) {
    return DeviceContext(
      platform: platform ?? this.platform,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      screenWidth: screenWidth ?? this.screenWidth,
      screenHeight: screenHeight ?? this.screenHeight,
      pixelRatio: pixelRatio ?? this.pixelRatio,
      isTablet: isTablet ?? this.isTablet,
      isLandscape: isLandscape ?? this.isLandscape,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'pixelRatio': pixelRatio,
      'isTablet': isTablet,
      'isLandscape': isLandscape,
    };
  }

  factory DeviceContext.fromJson(Map<String, dynamic> json) {
    return DeviceContext(
      platform: json['platform'] as String,
      deviceModel: json['deviceModel'] as String,
      osVersion: json['osVersion'] as String,
      screenWidth: json['screenWidth'] as double,
      screenHeight: json['screenHeight'] as double,
      pixelRatio: json['pixelRatio'] as double,
      isTablet: json['isTablet'] as bool,
      isLandscape: json['isLandscape'] as bool,
    );
  }
}

/// Theme context for light, dark, and user-selected themes
enum ContextThemeMode { light, dark, childFriendly, girlMode, proMode }

class ThemeContext {
  final ContextThemeMode mode;
  final bool isSystemTheme;
  final DateTime lastChanged;

  const ThemeContext({
    required this.mode,
    this.isSystemTheme = false,
    required this.lastChanged,
  });

  ThemeContext copyWith({
    ContextThemeMode? mode,
    bool? isSystemTheme,
    DateTime? lastChanged,
  }) {
    return ThemeContext(
      mode: mode ?? this.mode,
      isSystemTheme: isSystemTheme ?? this.isSystemTheme,
      lastChanged: lastChanged ?? this.lastChanged,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'isSystemTheme': isSystemTheme,
      'lastChanged': lastChanged.toIso8601String(),
    };
  }

  factory ThemeContext.fromJson(Map<String, dynamic> json) {
    return ThemeContext(
      mode: ContextThemeMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => ContextThemeMode.light,
      ),
      isSystemTheme: json['isSystemTheme'] as bool? ?? false,
      lastChanged: DateTime.parse(json['lastChanged'] as String),
    );
  }
}

/// Global context service managing user, device, and theme contexts
class ContextService {
  static const String _userContextKey = 'user_context';
  static const String _deviceContextKey = 'device_context';
  static const String _themeContextKey = 'theme_context';

  final SharedPreferences _prefs;
  final DeviceInfoPlugin _deviceInfo;

  ContextService(this._prefs, this._deviceInfo);

  /// Initialize context service and load saved contexts
  Future<void> initialize() async {
    await _loadDeviceContext();
    await _loadThemeContext();
  }

  /// Save user context to local storage
  Future<void> saveUserContext(UserContext context) async {
    await _prefs.setString(_userContextKey, jsonEncode(context.toJson()));
  }

  /// Load user context from local storage
  UserContext? loadUserContext() {
    final jsonString = _prefs.getString(_userContextKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserContext.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user context: $e');
      }
      return null;
    }
  }

  /// Save device context to local storage
  Future<void> saveDeviceContext(DeviceContext context) async {
    await _prefs.setString(_deviceContextKey, jsonEncode(context.toJson()));
  }

  /// Load device context from local storage
  DeviceContext? loadDeviceContext() {
    final jsonString = _prefs.getString(_deviceContextKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return DeviceContext.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading device context: $e');
      }
      return null;
    }
  }

  /// Save theme context to local storage
  Future<void> saveThemeContext(ThemeContext context) async {
    await _prefs.setString(_themeContextKey, jsonEncode(context.toJson()));
  }

  /// Load theme context from local storage
  ThemeContext? loadThemeContext() {
    final jsonString = _prefs.getString(_themeContextKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ThemeContext.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading theme context: $e');
      }
      return null;
    }
  }

  /// Load device context from device info
  Future<void> _loadDeviceContext() async {
    try {
      String platform = 'unknown';
      String deviceModel = 'unknown';
      String osVersion = 'unknown';

      if (kIsWeb) {
        platform = 'web';
        deviceModel = 'web';
        osVersion = 'web';
      } else {
        final deviceInfo = await _deviceInfo.deviceInfo;
        if (deviceInfo is AndroidDeviceInfo) {
          platform = 'android';
          deviceModel = deviceInfo.model;
          osVersion = deviceInfo.version.release;
        } else if (deviceInfo is IosDeviceInfo) {
          platform = 'ios';
          deviceModel = deviceInfo.model;
          osVersion = deviceInfo.systemVersion;
        } else if (deviceInfo is MacOsDeviceInfo) {
          platform = 'macos';
          deviceModel = deviceInfo.model;
          osVersion = deviceInfo.osRelease;
        } else if (deviceInfo is WindowsDeviceInfo) {
          platform = 'windows';
          deviceModel = deviceInfo.computerName;
          osVersion = deviceInfo.buildNumber.toString();
        } else if (deviceInfo is LinuxDeviceInfo) {
          platform = 'linux';
          deviceModel = deviceInfo.name;
          osVersion = deviceInfo.version ?? 'unknown';
        }
      }

      final context = DeviceContext(
        platform: platform,
        deviceModel: deviceModel,
        osVersion: osVersion,
        screenWidth: 0, // Will be set by UI
        screenHeight: 0, // Will be set by UI
        pixelRatio: 1.0, // Will be set by UI
        isTablet: false, // Will be set by UI
        isLandscape: false, // Will be set by UI
      );

      await saveDeviceContext(context);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading device context: $e');
      }
    }
  }

  /// Load theme context with default values
  Future<void> _loadThemeContext() async {
    final savedContext = loadThemeContext();
    if (savedContext == null) {
      final defaultContext = ThemeContext(
        mode: ContextThemeMode.light,
        isSystemTheme: true,
        lastChanged: DateTime.now(),
      );
      await saveThemeContext(defaultContext);
    }
  }

  /// Clear all contexts (for logout)
  Future<void> clearAllContexts() async {
    await _prefs.remove(_userContextKey);
    await _prefs.remove(_deviceContextKey);
    await _prefs.remove(_themeContextKey);
  }
}

/// Riverpod providers for context management
final contextServiceProvider = Provider<ContextService>((ref) {
  throw UnimplementedError('ContextService must be initialized');
});

final userContextProvider =
    StateNotifierProvider<UserContextNotifier, UserContext?>((ref) {
      return UserContextNotifier(ref.read(contextServiceProvider));
    });

final deviceContextProvider =
    StateNotifierProvider<DeviceContextNotifier, DeviceContext?>((ref) {
      return DeviceContextNotifier(ref.read(contextServiceProvider));
    });

final themeContextProvider =
    StateNotifierProvider<ThemeContextNotifier, ThemeContext?>((ref) {
      return ThemeContextNotifier(ref.read(contextServiceProvider));
    });

/// State notifiers for context management
class UserContextNotifier extends StateNotifier<UserContext?> {
  final ContextService _service;

  UserContextNotifier(this._service) : super(null) {
    _loadContext();
  }

  void _loadContext() {
    state = _service.loadUserContext();
  }

  Future<void> updateContext(UserContext context) async {
    await _service.saveUserContext(context);
    state = context;
  }

  Future<void> clearContext() async {
    state = null;
  }
}

class DeviceContextNotifier extends StateNotifier<DeviceContext?> {
  final ContextService _service;

  DeviceContextNotifier(this._service) : super(null) {
    _loadContext();
  }

  void _loadContext() {
    state = _service.loadDeviceContext();
  }

  Future<void> updateContext(DeviceContext context) async {
    await _service.saveDeviceContext(context);
    state = context;
  }
}

class ThemeContextNotifier extends StateNotifier<ThemeContext?> {
  final ContextService _service;

  ThemeContextNotifier(this._service) : super(null) {
    _loadContext();
  }

  void _loadContext() {
    state = _service.loadThemeContext();
  }

  Future<void> updateContext(ThemeContext context) async {
    await _service.saveThemeContext(context);
    state = context;
  }
}
