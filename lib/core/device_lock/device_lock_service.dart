import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Device lock modes
enum DeviceLockMode { none, study, game, quiz, fullScreen }

/// Device lock service for Math Genius
class DeviceLockService {
  static const String _lockModeKey = 'device_lock_mode';
  static const String _lockStartTimeKey = 'device_lock_start_time';
  static const String _lockDurationKey = 'device_lock_duration';

  final SharedPreferences _prefs;
  Timer? _lockTimer;
  DeviceLockMode _currentMode = DeviceLockMode.none;
  DateTime? _lockStartTime;
  Duration? _lockDuration;

  DeviceLockService(this._prefs) {
    _loadLockState();
  }

  /// Get current lock mode
  DeviceLockMode get currentMode => _currentMode;

  /// Get lock start time
  DateTime? get lockStartTime => _lockStartTime;

  /// Get lock duration
  Duration? get lockDuration => _lockDuration;

  /// Check if device is currently locked
  bool get isLocked => _currentMode != DeviceLockMode.none;

  /// Check if device is in full screen mode
  bool get isFullScreen => _currentMode == DeviceLockMode.fullScreen;

  /// Lock device for study mode
  Future<void> lockForStudy({
    Duration? duration,
    bool preventAppSwitch = true,
  }) async {
    await _setLockMode(
      DeviceLockMode.study,
      duration: duration,
      preventAppSwitch: preventAppSwitch,
    );
  }

  /// Lock device for game mode
  Future<void> lockForGame({
    Duration? duration,
    bool preventAppSwitch = true,
  }) async {
    await _setLockMode(
      DeviceLockMode.game,
      duration: duration,
      preventAppSwitch: preventAppSwitch,
    );
  }

  /// Lock device for quiz mode
  Future<void> lockForQuiz({
    Duration? duration,
    bool preventAppSwitch = true,
  }) async {
    await _setLockMode(
      DeviceLockMode.quiz,
      duration: duration,
      preventAppSwitch: preventAppSwitch,
    );
  }

  /// Lock device in full screen mode
  Future<void> lockFullScreen({
    Duration? duration,
    bool preventAppSwitch = true,
  }) async {
    await _setLockMode(
      DeviceLockMode.fullScreen,
      duration: duration,
      preventAppSwitch: preventAppSwitch,
    );
  }

  /// Unlock device (parent exit)
  Future<void> unlock() async {
    await _setLockMode(DeviceLockMode.none);
  }

  /// Set lock mode with optional duration
  Future<void> _setLockMode(
    DeviceLockMode mode, {
    Duration? duration,
    bool preventAppSwitch = true,
  }) async {
    try {
      // Cancel existing timer
      _lockTimer?.cancel();

      _currentMode = mode;
      _lockStartTime = mode != DeviceLockMode.none ? DateTime.now() : null;
      _lockDuration = duration;

      // Save lock state
      await _saveLockState();

      if (mode != DeviceLockMode.none) {
        // Set system UI overlay style
        await _setSystemUIOverlay(mode);

        // Set app lifecycle behavior
        await _setAppLifecycleBehavior(preventAppSwitch);

        // Start timer if duration is specified
        if (duration != null) {
          _lockTimer = Timer(duration, () {
            unlock();
          });
        }

        if (kDebugMode) {
          print('Device locked for ${mode.name} mode');
        }
      } else {
        // Restore normal system UI
        await _restoreSystemUI();

        if (kDebugMode) {
          print('Device unlocked');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting lock mode: $e');
      }
    }
  }

  /// Set system UI overlay based on lock mode
  Future<void> _setSystemUIOverlay(DeviceLockMode mode) async {
    try {
      switch (mode) {
        case DeviceLockMode.study:
        case DeviceLockMode.game:
        case DeviceLockMode.quiz:
          // Hide status bar and navigation bar for focused learning
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
            overlays: [],
          );
          break;
        case DeviceLockMode.fullScreen:
          // Complete full screen mode
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.immersiveSticky,
            overlays: [],
          );
          break;
        case DeviceLockMode.none:
          // Restore normal UI
          await SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: SystemUiOverlay.values,
          );
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting system UI overlay: $e');
      }
    }
  }

  /// Set app lifecycle behavior
  Future<void> _setAppLifecycleBehavior(bool preventAppSwitch) async {
    try {
      if (preventAppSwitch) {
        // Prevent app switching by setting preferred orientations
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting app lifecycle behavior: $e');
      }
    }
  }

  /// Restore normal system UI
  Future<void> _restoreSystemUI() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      await SystemChrome.setPreferredOrientations([]);
    } catch (e) {
      if (kDebugMode) {
        print('Error restoring system UI: $e');
      }
    }
  }

  /// Get remaining lock time
  Duration? getRemainingLockTime() {
    if (_lockStartTime == null || _lockDuration == null) return null;

    final elapsed = DateTime.now().difference(_lockStartTime!);
    final remaining = _lockDuration! - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if lock is about to expire (within 1 minute)
  bool get isLockExpiringSoon {
    final remaining = getRemainingLockTime();
    return remaining != null && remaining.inMinutes <= 1;
  }

  /// Extend lock duration
  Future<void> extendLock(Duration additionalTime) async {
    if (_lockDuration != null) {
      _lockDuration = _lockDuration! + additionalTime;
      await _saveLockState();
    }
  }

  /// Save lock state to SharedPreferences
  Future<void> _saveLockState() async {
    try {
      await _prefs.setString(_lockModeKey, _currentMode.name);
      if (_lockStartTime != null) {
        await _prefs.setString(
          _lockStartTimeKey,
          _lockStartTime!.toIso8601String(),
        );
      } else {
        await _prefs.remove(_lockStartTimeKey);
      }
      if (_lockDuration != null) {
        await _prefs.setInt(_lockDurationKey, _lockDuration!.inMilliseconds);
      } else {
        await _prefs.remove(_lockDurationKey);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving lock state: $e');
      }
    }
  }

  /// Load lock state from SharedPreferences
  Future<void> _loadLockState() async {
    try {
      final modeString = _prefs.getString(_lockModeKey);
      if (modeString != null) {
        _currentMode = DeviceLockMode.values.firstWhere(
          (e) => e.name == modeString,
        );
      }

      final startTimeString = _prefs.getString(_lockStartTimeKey);
      if (startTimeString != null) {
        _lockStartTime = DateTime.parse(startTimeString);
      }

      final durationMs = _prefs.getInt(_lockDurationKey);
      if (durationMs != null) {
        _lockDuration = Duration(milliseconds: durationMs);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading lock state: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _lockTimer?.cancel();
  }
}

/// Riverpod providers for device lock management
final deviceLockServiceProvider = Provider<DeviceLockService>((ref) {
  throw UnimplementedError('DeviceLockService must be initialized');
});

final deviceLockModeProvider = StateProvider<DeviceLockMode>((ref) {
  final service = ref.read(deviceLockServiceProvider);
  return service.currentMode;
});

final isDeviceLockedProvider = StateProvider<bool>((ref) {
  final service = ref.read(deviceLockServiceProvider);
  return service.isLocked;
});

final remainingLockTimeProvider = StateProvider<Duration?>((ref) {
  final service = ref.read(deviceLockServiceProvider);
  return service.getRemainingLockTime();
});
