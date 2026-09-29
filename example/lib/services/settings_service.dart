import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:face_recognition_sdk/face_recognition_sdk.dart' show CameraLens;

/// FaceRecognitionSDK Apps defaults (Android SettingsActivity schema v4).
class AppSettings {
  const AppSettings({
    this.cameraLens = CameraLens.front,
    this.livenessThreshold = 0.5,
    this.identifyThreshold = 0.67,
    this.yawThreshold = 40,
    this.rollThreshold = 40,
    this.pitchThreshold = 40,
    this.eyecloseThreshold = 0.5,
    this.identityHoldDuration = 0.5,
    this.landmarkMode = 68,
  });

  final CameraLens cameraLens;
  final double livenessThreshold;
  final double identifyThreshold;
  final double yawThreshold;
  final double rollThreshold;
  final double pitchThreshold;
  final double eyecloseThreshold;

  /// Seconds the face must stay valid before identity auto-capture (0.1–5).
  final double identityHoldDuration;

  /// Landmark mode: 14 or 68 (default 68).
  final int landmarkMode;

  /// Always High Accuracy (2d_ensemble_heavy). Light model is not shipped.
  int get livenessLevel => 0;

  static const defaults = AppSettings();

  AppSettings copyWith({
    CameraLens? cameraLens,
    double? livenessThreshold,
    double? identifyThreshold,
    double? yawThreshold,
    double? rollThreshold,
    double? pitchThreshold,
    double? eyecloseThreshold,
    double? identityHoldDuration,
    int? landmarkMode,
  }) {
    return AppSettings(
      cameraLens: cameraLens ?? this.cameraLens,
      livenessThreshold: livenessThreshold ?? this.livenessThreshold,
      identifyThreshold: identifyThreshold ?? this.identifyThreshold,
      yawThreshold: yawThreshold ?? this.yawThreshold,
      rollThreshold: rollThreshold ?? this.rollThreshold,
      pitchThreshold: pitchThreshold ?? this.pitchThreshold,
      eyecloseThreshold: eyecloseThreshold ?? this.eyecloseThreshold,
      identityHoldDuration:
          identityHoldDuration ?? this.identityHoldDuration,
      landmarkMode: landmarkMode ?? this.landmarkMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'camera_lens': cameraLens == CameraLens.back ? 'back' : 'front',
        'liveness_threshold': livenessThreshold,
        'identify_threshold': identifyThreshold,
        'yaw_threshold': yawThreshold,
        'roll_threshold': rollThreshold,
        'pitch_threshold': pitchThreshold,
        'eyeclose_threshold': eyecloseThreshold,
        'identity_hold_duration': identityHoldDuration,
        'landmark_mode': landmarkMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final hold = _num(json['identity_hold_duration'], defaults.identityHoldDuration)
        .clamp(0.1, 5.0);
    final lm = _int(json['landmark_mode'], defaults.landmarkMode);
    return AppSettings(
      cameraLens:
          json['camera_lens'] == 'back' ? CameraLens.back : CameraLens.front,
      livenessThreshold:
          _num(json['liveness_threshold'], defaults.livenessThreshold),
      identifyThreshold:
          _num(json['identify_threshold'], defaults.identifyThreshold),
      yawThreshold: _num(json['yaw_threshold'], defaults.yawThreshold),
      rollThreshold: _num(json['roll_threshold'], defaults.rollThreshold),
      pitchThreshold: _num(json['pitch_threshold'], defaults.pitchThreshold),
      eyecloseThreshold:
          _num(json['eyeclose_threshold'], defaults.eyecloseThreshold),
      identityHoldDuration: hold.toDouble(),
      landmarkMode: (lm == 14) ? 14 : 68,
    );
  }
}

double _num(Object? v, double fallback) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _int(Object? v, int fallback) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Real vs spoof for Identify / Capture / overlay. Spoof labels always fail.
/// Matches Android SettingsActivity.livenessPassed (no score≤0.001 special case).
bool livenessPassed(AppSettings settings, double score, [String? label]) {
  final lower = (label ?? '').toLowerCase();
  if (lower.contains('spoof') || lower.contains('fake')) return false;
  return score >= settings.livenessThreshold;
}

String qualityText(double score) {
  if (score < 0.5) return 'Low · ${(score * 100).round()}%';
  if (score < 0.75) return 'Medium · ${(score * 100).round()}%';
  return 'High · ${(score * 100).round()}%';
}

class SettingsService extends ChangeNotifier {
  static const _prefsKey = 'face_settings_sdk_v4';
  static const _schemaKey = 'face_settings_schema';
  static const _schemaVw = 4;

  AppSettings _settings = AppSettings.defaults;
  Future<void> Function()? _clearPersons;

  AppSettings get settings => _settings;

  void setClearPersonsCallback(Future<void> Function() clear) {
    _clearPersons = clear;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final schema = prefs.getInt(_schemaKey) ?? 0;
    if (schema < _schemaVw) {
      // Migrate to Android prefs schema v4 defaults; drop liveness_level.
      _settings = AppSettings.defaults;
      await prefs.setString(_prefsKey, jsonEncode(_settings.toJson()));
      await prefs.setInt(_schemaKey, _schemaVw);
      notifyListeners();
      return;
    }
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      _settings = AppSettings.defaults;
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        map.remove('liveness_level');
        _settings = AppSettings.fromJson(map);
      } else {
        _settings = AppSettings.defaults;
      }
    } catch (e) {
      debugPrint('[SettingsService] load failed: $e');
      _settings = AppSettings.defaults;
    }
    notifyListeners();
  }

  Future<void> save(AppSettings next) async {
    _settings = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(next.toJson()));
    await prefs.setInt(_schemaKey, _schemaVw);
    notifyListeners();
  }

  Future<void> patch(AppSettings Function(AppSettings) update) {
    return save(update(_settings));
  }

  Future<AppSettings> restoreDefaults() async {
    await save(AppSettings.defaults);
    return _settings;
  }

  Future<void> clearAllPersons() async {
    final cb = _clearPersons;
    if (cb != null) await cb();
  }
}
