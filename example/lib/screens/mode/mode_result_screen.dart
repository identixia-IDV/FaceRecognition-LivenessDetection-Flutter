import 'dart:convert';
import 'dart:io';

import 'package:face_recognition_sdk/face_recognition_sdk.dart' as fr;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../modes/face_mode.dart';
import '../../services/settings_service.dart';
import '../../widgets/overlay/landmark_image.dart';
import 'mode_camera_screen.dart';

/// Android [ModeResultActivity] parity — status, media, fields, raw JSON.
class ModeResultScreen extends StatefulWidget {
  const ModeResultScreen({super.key, required this.args});

  final ModeResultArgs args;

  @override
  State<ModeResultScreen> createState() => _ModeResultScreenState();
}

class _ModeResultScreenState extends State<ModeResultScreen> {
  bool _rawOpen = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>().settings;
    final view = FriendlyModeResult.build(widget.args, settings);
    final pretty = _prettyJson(widget.args.json);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.args.mode.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _StatusCard(view: view),
          if (view.scoreLabel != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                view.scoreLabel!,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          _MediaStrip(args: widget.args, ok: view.ok),
          const SizedBox(height: 8),
          for (final row in view.fields) _FieldRow(row: row),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() => _rawOpen = !_rawOpen),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _rawOpen ? 'Hide raw JSON' : 'Show raw JSON',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_rawOpen) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                pretty,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.view});
  final FriendlyModeResult view;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            view.status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: view.ok ? AppColors.accent : AppColors.danger,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (view.summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              view.summary,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.row});
  final ModeFieldRow row;

  @override
  Widget build(BuildContext context) {
    if (row.section) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
        child: Text(
          row.value.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.title, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          SelectableText(
            row.value,
            style: const TextStyle(color: AppColors.text, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _MediaStrip extends StatelessWidget {
  const _MediaStrip({required this.args, required this.ok});

  final ModeResultArgs args;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final p1 = args.thumbPath;
    if (p1 == null || p1.isEmpty) return const SizedBox.shrink();
    final p2 = args.thumb2Path;
    final mode = args.mode;

    if (mode == FaceMode.landmarks) {
      final pts = _landmarkPoints(args);
      // Landmarks are in cropFace bitmap pixels; LandmarkImage measures size.
      return Center(
        child: LandmarkImage(
          width: 300,
          height: 300,
          filePath: p1,
          landmarks: pts,
        ),
      );
    }

    if (mode == FaceMode.match && p2 != null && p2.isNotEmpty) {
      return _PairRow(
        leftPath: p1,
        rightPath: p2,
        leftLabel: 'Face 1',
        rightLabel: 'Face 2',
        ok: ok,
      );
    }

    if (mode == FaceMode.identity) {
      return _PairRow(
        leftPath: p1,
        rightPath: p2,
        leftLabel: 'Identified',
        rightLabel: 'Enrolled',
        ok: ok,
        rightPlaceholder: p2 == null || p2.isEmpty,
      );
    }

    return _Thumb(
      path: p1,
      label: mode == FaceMode.enroll ? 'Enrolled' : 'Captured face',
      wide: true,
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.leftPath,
    required this.leftLabel,
    required this.rightLabel,
    required this.ok,
    this.rightPath,
    this.rightPlaceholder = false,
  });

  final String leftPath;
  final String? rightPath;
  final String leftLabel;
  final String rightLabel;
  final bool ok;
  final bool rightPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _Thumb(path: leftPath, label: leftLabel)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ok ? '=' : '≠',
            style: TextStyle(
              color: ok ? AppColors.accent : AppColors.danger,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: rightPlaceholder || rightPath == null || rightPath!.isEmpty
              ? _PlaceholderThumb(label: rightLabel)
              : _Thumb(path: rightPath!, label: rightLabel),
        ),
      ],
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.people_outline, color: AppColors.muted, size: 40),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.label, this.wide = false});

  final String path;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (path.startsWith('data:image')) {
      try {
        final comma = path.indexOf(',');
        final bytes = base64Decode(path.substring(comma + 1));
        image = Image.memory(
          bytes,
          height: wide ? 200 : 140,
          width: wide ? double.infinity : null,
          fit: BoxFit.cover,
        );
      } catch (_) {
        image = Container(
          height: 140,
          color: AppColors.surfaceAlt,
          child: const Icon(Icons.broken_image, color: AppColors.muted),
        );
      }
    } else {
      final file = File(
        path.startsWith('file://') ? Uri.parse(path).toFilePath() : path,
      );
      image = file.existsSync()
          ? Image.file(
              file,
              height: wide ? 200 : 140,
              width: wide ? double.infinity : null,
              fit: BoxFit.cover,
            )
          : Container(
              height: 140,
              color: AppColors.surfaceAlt,
              child: const Icon(Icons.broken_image, color: AppColors.muted),
            );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: image,
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}

class ModeFieldRow {
  const ModeFieldRow({required this.section, required this.title, required this.value});
  final bool section;
  final String title;
  final String value;
}

/// Mirrors Android ModeResultActivity.buildFriendlyView.
class FriendlyModeResult {
  const FriendlyModeResult({
    required this.ok,
    required this.status,
    required this.summary,
    required this.scoreLabel,
    required this.fields,
  });

  final bool ok;
  final String status;
  final String summary;
  final String? scoreLabel;
  final List<ModeFieldRow> fields;

  static FriendlyModeResult build(ModeResultArgs args, AppSettings settings) {
    final root = _parseRoot(args.json);
    if (root == null) {
      return const FriendlyModeResult(
        ok: false,
        status: 'Failed',
        summary: 'No face detected',
        scoreLabel: null,
        fields: [],
      );
    }

    final faces = _facesOf(root);
    final score = _extractScore(root);
    final fields = <ModeFieldRow>[];
    final display = fr.ResultDisplaySettings(
      livenessThreshold: settings.livenessThreshold,
    );
    final threshold = settings.identifyThreshold;

    switch (args.mode) {
      case FaceMode.identity:
        final matched = root['matched'] == true ||
            (root['name'] != null && score != null);
        final name = '${root['name'] ?? '—'}';
        if (score != null) {
          fields.add(ModeFieldRow(section: false, title: 'Similarity', value: _formatScore(score)));
        }
        if (root['id'] != null) {
          fields.add(ModeFieldRow(section: false, title: 'Person id', value: '${root['id']}'));
        }
        fields.add(ModeFieldRow(section: false, title: 'Name', value: name));
        return FriendlyModeResult(
          ok: matched,
          status: matched ? 'Identified' : 'No match',
          summary: matched ? 'Matched $name' : 'No enrolled face matched',
          scoreLabel: score != null ? 'Score ${_formatScore(score)}' : null,
          fields: fields,
        );

      case FaceMode.enroll:
        final name = '${root['name'] ?? '—'}';
        fields.add(ModeFieldRow(section: false, title: 'Name', value: name));
        if (root['id'] != null) {
          fields.add(ModeFieldRow(section: false, title: 'Person id', value: '${root['id']}'));
        }
        return FriendlyModeResult(
          ok: root['success'] != false,
          status: 'Enrolled',
          summary: 'Saved $name',
          scoreLabel: null,
          fields: fields,
        );

      case FaceMode.match:
        final same = root['same'] == true ||
            root['matched'] == true ||
            (score != null && score >= threshold);
        if (score != null) {
          fields.add(const ModeFieldRow(section: true, title: 'Match', value: 'Match'));
          fields.add(ModeFieldRow(section: false, title: 'Similarity', value: _formatScore(score)));
          fields.add(ModeFieldRow(section: false, title: 'Threshold', value: _formatScore(threshold)));
          fields.add(ModeFieldRow(
            section: false,
            title: 'Verdict',
            value: same ? 'Same person' : 'Different person',
          ));
        }
        _appendFaceFields(fields, faces, display);
        return FriendlyModeResult(
          ok: same,
          status: same ? 'Same person' : 'Different person',
          summary: score != null
              ? 'Similarity ${_formatScore(score)}'
              : 'No face detected',
          scoreLabel: score != null ? 'Score ${_formatScore(score)}' : null,
          fields: fields,
        );

      case FaceMode.landmarks:
        final count = _landmarkCount(faces);
        _appendFaceFields(fields, faces, display);
        return FriendlyModeResult(
          ok: count > 0 || faces.isNotEmpty,
          status: 'Landmarks',
          summary: count > 0 ? '$count landmarks' : '1 face',
          scoreLabel: null,
          fields: fields,
        );

      case FaceMode.liveness:
        final auth = _authenticityFromFaces(faces, display);
        _appendFaceFields(fields, faces, display, preferAuthenticity: true);
        return FriendlyModeResult(
          ok: auth.ok,
          status: auth.heading,
          summary: faces.isNotEmpty ? '1 face analyzed' : 'No face detected',
          scoreLabel: null,
          fields: fields,
        );

      default:
        final count = faces.length;
        final ok = root['success'] == true ||
            count > 0 ||
            root.containsKey('result') ||
            score != null;
        _appendFaceFields(fields, faces, display);
        _appendTopLevelExtras(fields, root);
        return FriendlyModeResult(
          ok: ok,
          status: ok ? 'OK' : 'Failed',
          summary: count == 1
              ? '1 face'
              : count > 1
                  ? '$count faces'
                  : '${root['message'] ?? 'No face detected'}',
          scoreLabel: score != null ? 'Score ${_formatScore(score)}' : null,
          fields: fields,
        );
    }
  }
}

({bool ok, String heading}) _authenticityFromFaces(
  List<Map<String, dynamic>> faces,
  fr.ResultDisplaySettings settings,
) {
  if (faces.isEmpty) return (ok: false, heading: 'FAKE');
  final face = faces.first;
  final traits = (face['traits'] as Map?) ?? (face['attributes'] as Map?) ?? const {};
  final live = (traits['liveness2d'] as Map?) ??
      (traits['Liveness2D'] as Map?) ??
      (traits['liveness'] as Map?);
  final df = (traits['deepfake'] as Map?) ?? (traits['Deepfake'] as Map?);
  final liveLabel = '${live?['value'] ?? ''}';
  final liveScore =
      (live?['confidence'] is num) ? (live!['confidence'] as num).toDouble() : 0.0;
  var dfRaw = '';
  if (df != null) {
    final v = df['value'];
    dfRaw = v is bool ? '$v' : '${v ?? ''}';
    final conf = df['confidence'];
    if (conf is num && dfRaw.isNotEmpty) dfRaw = '$dfRaw ($conf)';
  }
  final heading = fr.authenticityHeading(settings, liveScore, liveLabel, dfRaw);
  return (ok: heading == 'REAL', heading: heading);
}

void _appendFaceFields(
  List<ModeFieldRow> fields,
  List<Map<String, dynamic>> faces,
  fr.ResultDisplaySettings settings, {
  bool preferAuthenticity = false,
}) {
  if (faces.isEmpty) return;
  for (var i = 0; i < faces.length; i++) {
    final face = faces[i];
    fields.add(ModeFieldRow(
      section: true,
      title: 'Face',
      value: faces.length == 1 ? 'Face' : 'Face ${i + 1}',
    ));

    final region = (face['box'] as Map?) ??
        (face['faceRegion'] as Map?) ??
        (face['region'] as Map?);
    final box = _parseBox(region);
    if (box != null) {
      fields.add(ModeFieldRow(
        section: false,
        title: 'Box',
        value: '${box.$1}, ${box.$2} · ${box.$3}×${box.$4}',
      ));
    }

    final pose = (face['pose'] as Map?) ?? (face['facePose'] as Map?);
    if (pose != null) {
      fields.add(ModeFieldRow(
        section: false,
        title: 'Pose',
        value:
            'yaw ${_fmt1(pose['yaw'])}°  roll ${_fmt1(pose['roll'])}°  pitch ${_fmt1(pose['pitch'])}°',
      ));
    }

    final traits = (face['traits'] as Map?) ??
        (face['attributes'] as Map?) ??
        (face['quality'] as Map?);
    if (traits is Map) {
      if (preferAuthenticity) {
        _appendAuthenticityTraits(fields, Map<String, dynamic>.from(traits), settings);
      }
      final keys = traits.keys.map((e) => '$e').toList()..sort();
      for (final key in keys) {
        final lower = key.toLowerCase();
        if (preferAuthenticity &&
            (lower.contains('liveness') || lower.contains('deepfake'))) {
          continue;
        }
        final shown = lower.contains('deepfake')
            ? _deepfakeTraitText(traits[key])
            : _traitValue(traits[key]);
        if (shown.isNotEmpty) {
          fields.add(ModeFieldRow(section: false, title: _humanize(key), value: shown));
        }
      }
    }

    final landmarks = face['landmarks'] ?? face['facePoints'];
    final lmCount = landmarks is List ? landmarks.length : 0;
    if (lmCount > 0) {
      fields.add(ModeFieldRow(section: false, title: 'Landmarks', value: '$lmCount landmarks'));
    }
  }
}

void _appendAuthenticityTraits(
  List<ModeFieldRow> fields,
  Map<String, dynamic> traits,
  fr.ResultDisplaySettings settings,
) {
  final live = (traits['liveness2d'] as Map?) ??
      (traits['Liveness2D'] as Map?) ??
      (traits['liveness'] as Map?);
  final df = (traits['deepfake'] as Map?) ?? (traits['Deepfake'] as Map?);
  final liveLabel = '${live?['value'] ?? ''}';
  final liveScore =
      (live?['confidence'] is num) ? (live!['confidence'] as num).toDouble() : 0.0;
  var dfRaw = '';
  if (df != null) {
    final v = df['value'];
    dfRaw = v is bool ? '$v' : '${v ?? ''}';
    final conf = df['confidence'];
    if (conf is num && dfRaw.isNotEmpty) dfRaw = '$dfRaw ($conf)';
  }
  final verdict = fr.authenticityHeading(settings, liveScore, liveLabel, dfRaw);
  fields.add(const ModeFieldRow(section: true, title: 'Authenticity', value: 'Authenticity'));
  fields.add(ModeFieldRow(section: false, title: 'Verdict', value: verdict));
  if (live != null) {
    fields.add(ModeFieldRow(
      section: false,
      title: 'Liveness',
      value: fr.livenessText(settings, liveScore, liveLabel),
    ));
  }
  final dfText = fr.deepfakeText(dfRaw);
  if (dfText.isNotEmpty) {
    fields.add(ModeFieldRow(section: false, title: 'Deepfake', value: dfText));
  }
}

void _appendTopLevelExtras(List<ModeFieldRow> fields, Map<String, dynamic> root) {
  for (final key in ['liveness', 'quality', 'label', 'message']) {
    if (!root.containsKey(key)) continue;
    if (key == 'message' && fields.isNotEmpty) continue;
    final shown = _traitValue(root[key]);
    if (shown.isEmpty) continue;
    final title = _humanize(key);
    if (fields.any((f) => !f.section && f.title.toLowerCase() == title.toLowerCase())) {
      continue;
    }
    fields.add(ModeFieldRow(section: false, title: title, value: shown));
  }
}

(int, int, int, int)? _parseBox(Map? region) {
  if (region == null) return null;
  if (region.containsKey('width') ||
      region.containsKey('height') ||
      region.containsKey('x') ||
      region.containsKey('y')) {
    final x = _asInt(region['x']);
    final y = _asInt(region['y']);
    final w = _asInt(region['width']);
    final h = _asInt(region['height']);
    if (w > 0 && h > 0) return (x, y, w, h);
  }
  final l = region.containsKey('left')
      ? _asInt(region['left'])
      : region.containsKey('x1')
          ? _asInt(region['x1'])
          : null;
  final t = region.containsKey('top')
      ? _asInt(region['top'])
      : region.containsKey('y1')
          ? _asInt(region['y1'])
          : null;
  final r = region.containsKey('right')
      ? _asInt(region['right'])
      : region.containsKey('x2')
          ? _asInt(region['x2'])
          : null;
  final b = region.containsKey('bottom')
      ? _asInt(region['bottom'])
      : region.containsKey('y2')
          ? _asInt(region['y2'])
          : null;
  if (l == null || t == null || r == null || b == null) return null;
  final w = r - l;
  final h = b - t;
  if (w <= 0 || h <= 0) return null;
  return (l, t, w, h);
}

List<Map<String, dynamic>> _facesOf(Map<String, dynamic> root) {
  dynamic faces = root['faces'] ??
      (root['result'] is Map ? (root['result'] as Map)['faces'] : null);

  // Native SDK often returns `{ "data": [ face, ... ] }` (array), not `{ data: { faces } }`.
  if (faces == null) {
    final data = root['data'];
    if (data is List) {
      faces = data;
    } else if (data is Map) {
      faces = data['faces'];
    }
  }

  if (faces == null) {
    final detects = root['detects'];
    if (detects is List) {
      final merged = <Map<String, dynamic>>[];
      for (final d in detects) {
        if (d is! Map) continue;
        final f = d['faces'];
        if (f is List) {
          for (final face in f) {
            if (face is Map) merged.add(Map<String, dynamic>.from(face));
          }
        }
      }
      return merged;
    }
  }

  if (faces is Map) faces = [faces];
  if (faces is! List) return const [];
  return faces
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

double? _extractScore(Map<String, dynamic> root) {
  double? from(Map? obj) {
    if (obj == null) return null;
    final s = obj['score'] ?? obj['similarity'];
    if (s is num) return s.toDouble();
    return null;
  }

  final direct = from(root);
  if (direct != null) return direct;

  for (final key in ['pairs', 'match']) {
    final arr = root[key];
    if (arr is List && arr.isNotEmpty && arr.first is Map) {
      final s = from(Map<String, dynamic>.from(arr.first as Map));
      if (s != null) return s;
    }
  }

  final faces = _facesOf(root);
  if (faces.isNotEmpty) return from(faces.first);
  return null;
}

int _landmarkCount(List<Map<String, dynamic>> faces) {
  if (faces.isEmpty) return 0;
  final lm = faces.first['landmarks'] ?? faces.first['facePoints'];
  return lm is List ? lm.length : 0;
}

List<({double x, double y})> _landmarkPoints(ModeResultArgs args) {
  final xy = args.landmarksXy;
  if (xy != null && xy.length >= 2) {
    final out = <({double x, double y})>[];
    for (var i = 0; i + 1 < xy.length; i += 2) {
      out.add((x: xy[i], y: xy[i + 1]));
    }
    return out;
  }
  final root = _parseRoot(args.json);
  if (root == null) return const [];
  final faces = _facesOf(root);
  if (faces.isEmpty) return const [];
  final lm = faces.first['landmarks'] ?? faces.first['facePoints'];
  if (lm is! List) return const [];
  final out = <({double x, double y})>[];
  for (final p in lm) {
    if (p is Map) {
      final x = p['x'];
      final y = p['y'];
      if (x is num && y is num) out.add((x: x.toDouble(), y: y.toDouble()));
    } else if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
      out.add((x: (p[0] as num).toDouble(), y: (p[1] as num).toDouble()));
    }
  }
  return out;
}

Map<String, dynamic>? _parseRoot(String json) {
  if (json.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(json);
    if (decoded is List) return {'faces': decoded};
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {}
  return null;
}

String _formatScore(double score) {
  final pct = (score * 100).round().clamp(0, 100);
  return '$pct% (${score.toStringAsFixed(3)})';
}

String _fmt1(Object? v) {
  if (v is num) return v.toStringAsFixed(1);
  return '0.0';
}

int _asInt(Object? v) {
  if (v is num) return v.round();
  return 0;
}

String _traitValue(Object? value) {
  if (value == null) return '';
  if (value is Map) {
    final v = value['value'] ?? value['label'];
    if (v == null && value['confidence'] is num) {
      return _formatScore((value['confidence'] as num).toDouble());
    }
    if (v == null) return '';
    return '$v';
  }
  if (value is num) {
    final d = value.toDouble();
    if (d >= 0 && d <= 1) return _formatScore(d);
    return d.toStringAsFixed(1);
  }
  if (value is bool) return value ? 'Yes' : 'No';
  return '$value';
}

String _deepfakeTraitText(Object? value) {
  if (value == null) return '';
  if (value is Map) {
    final v = value['value'];
    var raw = v is bool ? '$v' : '${v ?? ''}';
    final conf = value['confidence'];
    if (conf is num && raw.isNotEmpty) raw = '$raw ($conf)';
    final shown = fr.deepfakeText(raw);
    return shown.isNotEmpty ? shown : _traitValue(value);
  }
  return fr.deepfakeText('$value');
}

String _humanize(String key) {
  if (key.isEmpty) return key;
  return key
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ')
      .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());
}

String _prettyJson(String raw) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(raw));
  } catch (_) {
    return raw;
  }
}
