import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Audio service for Math Genius game sounds and music
class AudioService {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _volumeKey = 'audio_volume';

  final SharedPreferences _prefs;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _volume = 0.7;

  AudioService(this._prefs) {
    _loadSettings();
  }

  /// Load audio settings
  Future<void> _loadSettings() async {
    _soundEnabled = _prefs.getBool(_soundEnabledKey) ?? true;
    _musicEnabled = _prefs.getBool(_musicEnabledKey) ?? true;
    _volume = _prefs.getDouble(_volumeKey) ?? 0.7;
  }

  /// Play sound effect with category-specific audio
  Future<void> playSound(SoundType soundType, {String? category}) async {
    if (!_soundEnabled) return;

    try {
      String soundPath;
      
      switch (soundType) {
        case SoundType.correct:
          soundPath = _getCategorySoundPath(category, 'correct');
          break;
        case SoundType.incorrect:
          soundPath = 'sounds/incorrect.mp3';
          break;
        case SoundType.streak:
          soundPath = 'sounds/streak.mp3';
          break;
        case SoundType.fire:
          soundPath = 'sounds/fire_streak.mp3';
          break;
        case SoundType.buttonTap:
          soundPath = 'sounds/button_tap.mp3';
          break;
        case SoundType.gameStart:
          soundPath = 'sounds/game_start.mp3';
          break;
        case SoundType.gameComplete:
          soundPath = 'sounds/game_complete.mp3';
          break;
        case SoundType.achievement:
          soundPath = 'sounds/achievement.mp3';
          break;
        case SoundType.hint:
          soundPath = 'sounds/hint.mp3';
          break;
        case SoundType.timeWarning:
          soundPath = 'sounds/time_warning.mp3';
          break;
      }

      // Use SystemSound for now (can be replaced with audio player)
      SystemSound.play(SystemSoundType.click);
      
      if (kDebugMode) {
        debugPrint('🔊 Playing sound: $soundPath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing sound: $e');
      }
    }
  }

  /// Get category-specific sound path
  String _getCategorySoundPath(String? category, String type) {
    if (category == null) return 'sounds/${type}_default.mp3';
    
    switch (category.toLowerCase()) {
      case 'addition':
        return 'sounds/${type}_cheerful.mp3';
      case 'subtraction':
        return 'sounds/${type}_calm.mp3';
      case 'multiplication':
        return 'sounds/${type}_energetic.mp3';
      case 'division':
        return 'sounds/${type}_focused.mp3';
      case 'fractions':
        return 'sounds/${type}_creative.mp3';
      case 'percentages':
        return 'sounds/${type}_analytical.mp3';
      case 'algebra':
        return 'sounds/${type}_sophisticated.mp3';
      case 'geometry':
        return 'sounds/${type}_spatial.mp3';
      default:
        return 'sounds/${type}_default.mp3';
    }
  }

  /// Play background music
  Future<void> playBackgroundMusic(MusicType musicType) async {
    if (!_musicEnabled) return;
    
    try {
      String musicPath;
      switch (musicType) {
        case MusicType.gamePlay:
          musicPath = 'music/gameplay_ambient.mp3';
          break;
        case MusicType.results:
          musicPath = 'music/results_celebration.mp3';
          break;
        case MusicType.menu:
          musicPath = 'music/menu_background.mp3';
          break;
      }
      
      if (kDebugMode) {
        debugPrint('🎵 Playing music: $musicPath');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error playing music: $e');
      }
    }
  }

  /// Stop all audio
  Future<void> stopAll() async {
    // Stop all playing audio
  }

  /// Set volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _prefs.setDouble(_volumeKey, _volume);
  }

  /// Enable/disable sound effects
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Enable/disable background music
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs.setBool(_musicEnabledKey, enabled);
  }

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get volume => _volume;
}

/// Sound effect types
enum SoundType {
  correct,
  incorrect,
  streak,
  fire,
  buttonTap,
  gameStart,
  gameComplete,
  achievement,
  hint,
  timeWarning,
}

/// Background music types
enum MusicType {
  gamePlay,
  results,
  menu,
}

/// Riverpod provider for audio service
final audioServiceProvider = Provider<AudioService>((ref) {
  throw UnimplementedError('AudioService must be initialized with SharedPreferences');
});
