import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:face_recognition_sdk/face_recognition_sdk.dart';

import '../../app/theme.dart';

const _ok = Color(0xFF15803D);
const _warn = Color(0xFFB45309);

/// Android IdentityGuideView — scrim hole, tick ring, hold progress.
class IdentityGuide extends StatefulWidget {
  const IdentityGuide({
    super.key,
    required this.width,
    required this.height,
    required this.frameW,
    required this.frameH,
    required this.mirror,
    required this.state,
    required this.progress,
  });

  final double width;
  final double height;
  final double frameW;
  final double frameH;
  final bool mirror;
  final CaptureState state;
  final double progress;

  @override
  State<IdentityGuide> createState() => _IdentityGuideState();
}

class _IdentityGuideState extends State<IdentityGuide>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _spin;
  double _displayProgress = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
    _spin.addListener(() {
      _displayProgress +=
          (widget.progress.clamp(0.0, 1.0) - _displayProgress) * 0.22;
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _spin.dispose();
    super.dispose();
  }

  Color _ringColor(CaptureState state) {
    switch (state) {
      case CaptureState.captureOk:
        return _ok;
      case CaptureState.noFace:
        return AppColors.accent;
      case CaptureState.multipleFaces:
      case CaptureState.faceOccluded:
      case CaptureState.spoofedFace:
        return AppColors.danger;
      case CaptureState.fitInCircle:
      case CaptureState.moveCloser:
      case CaptureState.noFront:
      case CaptureState.eyeClosed:
        return _warn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulse, _spin]),
      builder: (_, __) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _IdentityGuidePainter(
            frameW: widget.frameW,
            frameH: widget.frameH,
            mirror: widget.mirror,
            state: widget.state,
            progress: _displayProgress,
            pulse: _pulse.value,
            spinDeg: _spin.value * 360,
            ringColor: _ringColor(widget.state),
          ),
        );
      },
    );
  }
}

class _IdentityGuidePainter extends CustomPainter {
  _IdentityGuidePainter({
    required this.frameW,
    required this.frameH,
    required this.mirror,
    required this.state,
    required this.progress,
    required this.pulse,
    required this.spinDeg,
    required this.ringColor,
  });

  final double frameW;
  final double frameH;
  final bool mirror;
  final CaptureState state;
  final double progress;
  final double pulse;
  final double spinDeg;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final roi = _mapRoi(size);
    final cx = roi.center.dx;
    final cy = roi.center.dy;
    final baseR = math.min(roi.width, roi.height) / 2;
    final searching = state == CaptureState.noFace;
    final allowed = state == CaptureState.captureOk;
    final pulseScale = searching
        ? 1 + 0.035 * pulse
        : (!allowed ? 1 + 0.012 * pulse : 1.0);
    final radius = baseR * pulseScale;

    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
    canvas.drawPath(scrim, Paint()..color = const Color(0x660F1A22));

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = ringColor.withOpacity(allowed ? 0.35 : 0.55);
    canvas.drawCircle(Offset(cx, cy), radius, track);

    _drawTicks(canvas, cx, cy, radius);
    if (searching || !allowed) {
      _drawSpinArc(canvas, cx, cy, radius);
    }
    if (searching) {
      _drawBrackets(canvas, cx, cy, radius * (1.08 + 0.04 * pulse));
    }

    final oval = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = ringColor.withOpacity(
        ((55 + 50 * progress) / 255).clamp(0.0, 0.47),
      );
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = ringColor;
    if (allowed) {
      canvas.drawArc(oval, -math.pi / 2, 2 * math.pi * progress, false, glow);
      canvas.drawArc(oval, -math.pi / 2, 2 * math.pi * progress, false, prog);
    } else {
      canvas.drawArc(oval, -math.pi / 2, 2 * math.pi, false, prog);
    }
  }

  Rect _mapRoi(Size size) {
    if (frameW <= 0 || frameH <= 0) {
      final m = size.width / 6;
      final side = size.width - 2 * m;
      final top = (size.height - side) / 2;
      return Rect.fromLTRB(m, top, size.width - m, top + side);
    }
    final frame = FrameSize(frameW, frameH);
    final roi = getRoiRect1(frame);
    final scale = math.max(size.width / frameW, size.height / frameH);
    final dx = (size.width - frameW * scale) / 2;
    final dy = (size.height - frameH * scale) / 2;
    var left = roi.left * scale + dx;
    var right = roi.right * scale + dx;
    final top = roi.top * scale + dy;
    final bottom = roi.bottom * scale + dy;
    if (mirror) {
      final l = size.width - right;
      final r = size.width - left;
      left = l;
      right = r;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawTicks(Canvas canvas, double cx, double cy, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = ringColor.withOpacity(0.63);
    const count = 36;
    for (var i = 0; i < count; i++) {
      final deg = (i * (360.0 / count) + spinDeg * 0.15) * math.pi / 180;
      final cos = math.cos(deg);
      final sin = math.sin(deg);
      final major = i % 3 == 0;
      final inner = radius + (major ? 4.0 : 2.0);
      final outer = radius + (major ? 12.0 : 7.0);
      canvas.drawLine(
        Offset(cx + cos * inner, cy + sin * inner),
        Offset(cx + cos * outer, cy + sin * outer),
        paint,
      );
    }
  }

  void _drawSpinArc(Canvas canvas, double cx, double cy, double radius) {
    final oval = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = ringColor.withOpacity(0.7);
    final start = spinDeg * math.pi / 180;
    canvas.drawArc(oval, start, 54 * math.pi / 180, false, paint);
    paint.color = ringColor.withOpacity(0.35);
    canvas.drawArc(oval, start + math.pi, 40 * math.pi / 180, false, paint);
  }

  void _drawBrackets(Canvas canvas, double cx, double cy, double half) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ringColor.withOpacity(0.86);
    final len = half * 0.28;
    final inset = half * 0.72;
    void corner(double ox, double oy, double sx, double sy) {
      final path = Path()
        ..moveTo(cx + ox * inset, cy + oy * inset + sy * len)
        ..lineTo(cx + ox * inset, cy + oy * inset)
        ..lineTo(cx + ox * inset + sx * len, cy + oy * inset);
      canvas.drawPath(path, paint);
    }

    corner(-1, -1, 1, 1);
    corner(1, -1, -1, 1);
    corner(-1, 1, 1, -1);
    corner(1, 1, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _IdentityGuidePainter old) {
    return old.state != state ||
        old.progress != progress ||
        old.pulse != pulse ||
        old.spinDeg != spinDeg ||
        old.frameW != frameW ||
        old.frameH != frameH ||
        old.mirror != mirror;
  }
}

/// Android IdentityCapture.messageRes strings.
String identityHint(CaptureState state) {
  switch (state) {
    case CaptureState.noFace:
      return 'Center your face in the circle';
    case CaptureState.multipleFaces:
      return 'One face only';
    case CaptureState.fitInCircle:
      return 'Fit in circle';
    case CaptureState.moveCloser:
      return 'Move closer';
    case CaptureState.noFront:
      return 'Face the camera';
    case CaptureState.faceOccluded:
      return 'Remove obstruction';
    case CaptureState.eyeClosed:
      return 'Open your eyes';
    case CaptureState.spoofedFace:
      return 'Live face required';
    case CaptureState.captureOk:
      return 'Hold still';
  }
}

Color identityHintColor(CaptureState state) {
  switch (state) {
    case CaptureState.captureOk:
      return _ok;
    case CaptureState.noFace:
      return Colors.white;
    case CaptureState.multipleFaces:
    case CaptureState.faceOccluded:
    case CaptureState.spoofedFace:
      return AppColors.danger;
    default:
      return _warn;
  }
}

/// Android IdentityCapture.evaluateBoxes — square ROI (IdentityGuideView.roiInFrame).
CaptureState evaluateIdentity(
  List<FaceBox> boxes,
  CaptureSettings settings,
  FrameSize frame,
) {
  if (boxes.isEmpty) return CaptureState.noFace;
  if (boxes.length > 1) return CaptureState.multipleFaces;

  final faceBox = boxes.first;
  var faceLeft = double.maxFinite;
  var faceRight = 0.0;
  var faceBottom = 0.0;
  final lm = faceBox.landmarks ?? const <double>[];
  final nMarks = math.max(
    0,
    math.min(faceBox.landmarkCount ?? (lm.length ~/ 2), lm.length ~/ 2),
  );
  if (nMarks >= 5) {
    for (var i = 0; i < nMarks; i++) {
      faceLeft = math.min(faceLeft, lm[i * 2]);
      faceRight = math.max(faceRight, lm[i * 2]);
      faceBottom = math.max(faceBottom, lm[i * 2 + 1]);
    }
  } else {
    faceLeft = faceBox.x1;
    faceRight = faceBox.x2;
    faceBottom = faceBox.y2;
  }

  final fw = frame.w > 0 ? frame.w : 720.0;
  final fh = frame.h > 0 ? frame.h : 1280.0;
  final roi = getRoiRect1(FrameSize(fw, fh));
  final centerY = (faceBox.y2 + faceBox.y1) / 2;
  final topY = centerY - ((faceBox.y2 - faceBox.y1) * 2) / 3;
  final interX = math.max(0.0, roi.left - faceLeft) +
      math.max(0.0, faceRight - roi.right);
  final interY = math.max(0.0, roi.top - topY) +
      math.max(0.0, faceBottom - roi.bottom);
  if (interX / roi.width > 0.03 || interY / roi.height > 0.03) {
    return CaptureState.fitInCircle;
  }
  if ((faceBox.y2 - faceBox.y1) * (faceBox.x2 - faceBox.x1) <
      roi.width * roi.height * 0.30) {
    return CaptureState.moveCloser;
  }
  if ((faceBox.yaw ?? 0).abs() > settings.yawThreshold ||
      (faceBox.roll ?? 0).abs() > settings.rollThreshold ||
      (faceBox.pitch ?? 0).abs() > settings.pitchThreshold) {
    return CaptureState.noFront;
  }
  final mask = (faceBox.maskLabel ?? '').toLowerCase();
  if (mask.contains('yes')) return CaptureState.faceOccluded;
  final left = (faceBox.eyesLeftLabel ?? '').toLowerCase();
  final right = (faceBox.eyesRightLabel ?? '').toLowerCase();
  if (left.contains('closed') || right.contains('closed')) {
    return CaptureState.eyeClosed;
  }
  if (left.isEmpty &&
      right.isEmpty &&
      ((faceBox.leftEyeClosed ?? 0) > settings.eyecloseThreshold ||
          (faceBox.rightEyeClosed ?? 0) > settings.eyecloseThreshold)) {
    return CaptureState.eyeClosed;
  }
  return CaptureState.captureOk;
}
