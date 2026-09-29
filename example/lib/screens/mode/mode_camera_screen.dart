import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_recognition_sdk/face_recognition_sdk.dart'
    hide livenessPassed, qualityText;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../modes/face_mode.dart';
import '../../modes/mode_analyzer.dart';
import '../../services/person_database.dart';
import '../../services/settings_service.dart';
import '../../widgets/dialogs/app_dialogs.dart';
import '../../widgets/overlay/face_overlay.dart';
import '../../widgets/overlay/identity_guide.dart';

class ModeResultArgs {
  const ModeResultArgs({
    required this.mode,
    required this.json,
    this.thumbPath,
    this.thumb2Path,
    this.landmarksXy,
  });

  final FaceMode mode;
  final String json;
  final String? thumbPath;
  final String? thumb2Path;
  final List<double>? landmarksXy;
}

/// Android ModeCameraActivity — live FaceView / IdentityGuide + still analysis.
class ModeCameraScreen extends StatefulWidget {
  const ModeCameraScreen({super.key, required this.mode});

  final FaceMode mode;

  @override
  State<ModeCameraScreen> createState() => _ModeCameraScreenState();
}

class _ModeCameraScreenState extends State<ModeCameraScreen> {
  CameraController? _controller;
  StreamSubscription<String>? _eventsSub;

  bool _initializing = true;
  bool _busy = false;
  bool _frameBusy = false;
  bool _confirming = false;
  bool _resultOpened = false;
  bool _workerReady = false;
  int _lastStreamMs = 0;

  String? _oddPath;
  List<FaceBox> _boxes = [];
  Size _frameSize = const Size(480, 640);
  /// Ingested bitmap size (native `prepared.size`). Prefer over SDK JSON.
  Size? _preparedFrameSize;
  CaptureState _identityState = CaptureState.noFace;
  double _identityProgress = 0;
  int _identityOkSinceMs = 0;
  CaptureState _lastIdentityState = CaptureState.noFace;
  AppSettings? _settings;
  final _picker = ImagePicker();

  bool get _isIdentity => widget.mode == FaceMode.identity;

  CaptureSettings _captureSettings(AppSettings s) => CaptureSettings.fromApp(
        cameraLens: s.cameraLens,
        livenessThreshold: s.livenessThreshold,
        livenessLevel: s.livenessLevel,
        yawThreshold: s.yawThreshold,
        rollThreshold: s.rollThreshold,
        pitchThreshold: s.pitchThreshold,
        eyecloseThreshold: s.eyecloseThreshold,
        matchThreshold: s.identifyThreshold,
        identityHoldDuration: s.identityHoldDuration,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrap());
    });
  }

  @override
  void dispose() {
    unawaited(_stopCamera());
    unawaited(_eventsSub?.cancel());
    unawaited(stopVideoWorker());
    super.dispose();
  }

  Future<void> _stopCamera() async {
    final c = _controller;
    _controller = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
    } catch (_) {}
    await c.dispose();
  }

  Future<void> _bootstrap() async {
    final cam = await Permission.camera.request();
    if (!cam.isGranted) {
      if (mounted) setState(() => _initializing = false);
      return;
    }
    if (!mounted) return;
    try {
      final settings = context.read<SettingsService>().settings;
      _settings = settings;
      final cameras = await availableCameras();
      final preferFront = settings.cameraLens == CameraLens.front;
      final selected = cameras.firstWhere(
        (c) => preferFront
            ? c.lensDirection == CameraLensDirection.front
            : c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;

      _eventsSub = videoWorkerEvents.listen(_onWorkerEvent);
      final code = await startVideoWorker(
        VideoWorkerConfig(matchThreshold: settings.identifyThreshold),
      );
      _workerReady = code == 0;
      await controller.startImageStream(_onCameraImage);

      setState(() => _initializing = false);
    } catch (e) {
      if (mounted) {
        setState(() => _initializing = false);
        AppDialogs.toast(context, 'Camera failed: $e');
      }
    }
  }

  void _onCameraImage(CameraImage image) {
    final c = _controller;
    if (c == null ||
        !c.value.isInitialized ||
        !_workerReady ||
        _frameBusy ||
        _busy ||
        _confirming ||
        _resultOpened) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStreamMs < 120) return;
    _lastStreamMs = now;
    _frameBusy = true;
    unawaited(_processStreamFrame(image));
  }

  Future<void> _processStreamFrame(CameraImage image) async {
    try {
      if (_busy || _confirming || _resultOpened || !mounted) return;
      final c = _controller;
      if (c == null) return;
      final front = _settings?.cameraLens == CameraLens.front;
      final live = await feedCameraFrame(
        image,
        sensorOrientation: c.description.sensorOrientation,
        frontCamera: front,
      );
      if (live.ingested && live.width > 0 && live.height > 0 && mounted) {
        _preparedFrameSize = Size(live.width.toDouble(), live.height.toDouble());
      }
    } catch (_) {
      // drop frame
    } finally {
      _frameBusy = false;
    }
  }

  Future<void> _waitFrameIdle() async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (_frameBusy && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  void _onWorkerEvent(String json) {
    if (_resultOpened || !mounted) return;
    final ev = parseVideoWorkerEvent(json);
    if (ev is! VideoWorkerTracking) return;
    final boxes = ev.faces.map(workerFaceToBox).toList();
    final frame = _preparedFrameSize ??
        Size(
          ev.frameWidth > 0 ? ev.frameWidth.toDouble() : _frameSize.width,
          ev.frameHeight > 0 ? ev.frameHeight.toDouble() : _frameSize.height,
        );

    if (_isIdentity) {
      _onIdentityTracking(boxes, frame);
    } else if (mounted) {
      setState(() {
        _boxes = boxes;
        _frameSize = frame;
      });
    }
  }

  void _onIdentityTracking(List<FaceBox> boxes, Size frame) {
    final settings = _settings;
    if (settings == null || _confirming || _resultOpened) return;
    final state = evaluateIdentity(
      boxes,
      _captureSettings(settings),
      FrameSize(frame.width, frame.height),
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final holdMs =
        mathMax(100, (settings.identityHoldDuration * 1000).round());

    var progress = 0.0;
    var shouldCapture = false;
    if (state == CaptureState.captureOk) {
      if (_identityOkSinceMs == 0 ||
          _lastIdentityState != CaptureState.captureOk) {
        _identityOkSinceMs = now;
      }
      final elapsed = now - _identityOkSinceMs;
      progress = (elapsed / holdMs).clamp(0.0, 1.0);
      if (elapsed >= holdMs) shouldCapture = true;
    } else {
      _identityOkSinceMs = 0;
      progress = 1.0;
    }
    _lastIdentityState = state;

    if (mounted) {
      setState(() {
        _boxes = boxes;
        _frameSize = frame;
        _identityState = state;
        _identityProgress = progress;
      });
    }

    if (shouldCapture && !_confirming) {
      unawaited(_finishIdentity());
    }
  }

  int mathMax(int a, int b) => a > b ? a : b;

  FaceBox _largestBox(List<FaceBox> boxes) {
    var best = boxes.first;
    var bestArea = (best.x2 - best.x1) * (best.y2 - best.y1);
    for (final b in boxes.skip(1)) {
      final a = (b.x2 - b.x1) * (b.y2 - b.y1);
      if (a > bestArea) {
        best = b;
        bestArea = a;
      }
    }
    return best;
  }

  Future<String> _writeTempJpeg(String b64) async {
    final cleaned = b64.contains(',') ? b64.substring(b64.indexOf(',') + 1) : b64;
    final bytes = base64Decode(cleaned);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/mode_thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return file.path;
  }

  /// Android ModeCamera: crop largest face for result thumbs (fallback: full frame).
  Future<String> _cropThumbPath(String imagePath) async {
    try {
      final boxes = await faceDetection(
        imagePath,
        const FaceDetectionParam(allAttributes: false),
      );
      if (boxes.isEmpty) return imagePath;
      final b64 = await cropFace(imagePath, _largestBox(boxes));
      if (b64.isEmpty) return imagePath;
      return await _writeTempJpeg(b64);
    } catch (_) {
      return imagePath;
    }
  }

  Future<({String path, List<double>? landmarksXy})> _cropLandmarksThumb(
    String imagePath,
  ) async {
    try {
      final boxes = await faceDetection(
        imagePath,
        const FaceDetectionParam(checkLandmarks: true),
      );
      if (boxes.isEmpty) return (path: imagePath, landmarksXy: null);
      final box = _largestBox(boxes);
      final b64 = await cropFace(imagePath, box);
      final path = b64.isEmpty ? imagePath : await _writeTempJpeg(b64);

      var srcW = (box.x2 + 1).clamp(1, double.infinity);
      var srcH = (box.y2 + 1).clamp(1, double.infinity);
      try {
        final filePath =
            imagePath.startsWith('file://') ? Uri.parse(imagePath).toFilePath() : imagePath;
        final bytes = await File(filePath).readAsBytes();
        final decoded = await decodeImageFromList(bytes);
        srcW = decoded.width.toDouble();
        srcH = decoded.height.toDouble();
      } catch (_) {
        // box-based fallback
      }

      var outW = 200.0;
      var outH = 200.0;
      try {
        final cropBytes = await File(
          path.startsWith('file://') ? Uri.parse(path).toFilePath() : path,
        ).readAsBytes();
        final cropDecoded = await decodeImageFromList(cropBytes);
        outW = cropDecoded.width.toDouble();
        outH = cropDecoded.height.toDouble();
      } catch (_) {
        // keep fallback 200 until LandmarkImage measures
      }
      final pts = mapLandmarksToCrop(
        box,
        srcW.toDouble(),
        srcH.toDouble(),
        outW,
        outH,
      );
      if (pts.isEmpty) return (path: path, landmarksXy: null);
      final xy = <double>[];
      for (final p in pts) {
        xy.add(p.x);
        xy.add(p.y);
      }
      return (path: path, landmarksXy: xy);
    } catch (_) {
      return (path: imagePath, landmarksXy: null);
    }
  }

  /// extractFeature/getFeature return JSON; similarity needs raw feature b64
  /// (same as enrolled templateExtraction). Matches Android FaceJson + RN probeFeature.
  String? _parseFeatureB64(String json) {
    try {
      final root = jsonDecode(json);
      if (root is! Map) return null;
      dynamic pick(dynamic v) {
        if (v is String && v.trim().isNotEmpty) return v.trim();
        if (v is Map && v['data'] is String) {
          final d = (v['data'] as String).trim();
          return d.isEmpty ? null : d;
        }
        return null;
      }

      final features = root['features'] ?? root['result']?['features'];
      if (features is List && features.isNotEmpty) {
        final first = features.first;
        if (first is Map) {
          final nested = first['features'];
          if (nested is List && nested.isNotEmpty && nested.first is Map) {
            final b = pick(nested.first['feature']);
            if (b != null) return b as String;
          }
          final b = pick(first['feature']);
          if (b != null) return b as String;
        }
      }
      final results = root['results'];
      if (results is List && results.isNotEmpty && results.first is Map) {
        final feats = results.first['features'];
        if (feats is List && feats.isNotEmpty && feats.first is Map) {
          final b = pick(feats.first['feature']);
          if (b != null) return b as String;
        }
      }
      final direct = pick(root['feature'] ?? root['data'] ?? root['featureBase64']);
      if (direct != null) return direct as String;
    } catch (_) {}
    return null;
  }

  Future<String?> _probeFeature(String uri, FaceBox? box) async {
    try {
      final json = await extractFeature(uri);
      final b64 = _parseFeatureB64(json);
      if (b64 != null && b64.isNotEmpty) return b64;
    } catch (_) {}
    if (box != null) {
      try {
        return await templateExtraction(uri, box);
      } catch (_) {}
    }
    return null;
  }

  Future<void> _finishIdentity() async {
    if (_confirming || _resultOpened) return;
    _confirming = true;
    if (mounted) {
      setState(() {
        _identityState = CaptureState.captureOk;
        _identityProgress = 1;
      });
    }
    final db = context.read<PersonDatabase>();
    try {
      final exported = await exportLastLiveFrame();
      final uri = exported.uri;
      if (uri == null || uri.isEmpty) {
        _confirming = false;
        _identityOkSinceMs = 0;
        return;
      }
      FaceBox? bestBox;
      try {
        final boxes = await faceDetection(
          uri,
          const FaceDetectionParam(checkLiveness: false),
        );
        if (boxes.isNotEmpty) bestBox = _largestBox(boxes);
      } catch (_) {}
      final feature = await _probeFeature(uri, bestBox);
      final threshold = _settings?.identifyThreshold ?? 0.67;
      final people = db.persons;
      EnrolledPerson? best;
      var bestScore = 0.0;
      if (feature != null && feature.isNotEmpty) {
        for (final p in people) {
          try {
            final score = await similarity(feature, p.featureBase64);
            if (score >= threshold && score > bestScore) {
              bestScore = score;
              best = p;
            }
          } catch (_) {}
        }
      }

      String? enrolledThumb;
      if (best != null) {
        enrolledThumb = await db.resolveThumbnail(best);
      }

      final thumbPath = await _cropThumbPath(uri);

      final json = jsonEncode({
        'success': best != null,
        'mode': FaceMode.identity.id,
        'matched': best != null,
        if (best != null) 'name': best.name,
        if (best != null) 'id': best.id,
        if (best != null) 'score': bestScore,
      });

      if (!mounted) return;
      _resultOpened = true;
      await stopVideoWorker();
      if (!mounted) return;
      context.pushReplacement(
        '/mode-result',
        extra: ModeResultArgs(
          mode: FaceMode.identity,
          json: json,
          thumbPath: thumbPath,
          thumb2Path: enrolledThumb,
        ),
      );
    } catch (e) {
      _confirming = false;
      _identityOkSinceMs = 0;
      if (mounted) AppDialogs.toast(context, 'Identity failed: $e');
    }
  }

  String get _hint {
    if (_isIdentity) return identityHint(_identityState);
    if (widget.mode == FaceMode.match) {
      return _oddPath == null
          ? 'Capture face 1, then face 2'
          : 'Capture face 2 for match';
    }
    return 'Align face and tap capture';
  }

  Future<void> _fromGallery() async {
    if (_isIdentity || _busy || _resultOpened) return;
    setState(() => _busy = true);
    await _waitFrameIdle();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked == null || !mounted) return;
      await _processPath(picked.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _capture() async {
    if (_isIdentity || _busy || _resultOpened) return;
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() => _busy = true);
    await _waitFrameIdle();
    try {
      // Same as Ionic/RN: use the last live preview frame (no takePicture shutter).
      final exported = await exportLastLiveFrame();
      final uri = exported.uri;
      if (uri == null || uri.isEmpty) {
        if (mounted) {
          AppDialogs.toast(context, 'No camera frame yet');
        }
        return;
      }
      final path = uri.startsWith('file://') ? uri.substring(7) : uri;
      if (!mounted) return;
      await _processPath(path);
    } catch (e) {
      if (mounted) AppDialogs.toast(context, 'Capture failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _processPath(String path) async {
    final mode = widget.mode;
    final settings = context.read<SettingsService>().settings;

    if (mode == FaceMode.match && _oddPath == null) {
      setState(() => _oddPath = path);
      AppDialogs.toast(context, 'Face 1 saved — capture face 2');
      return;
    }

    if (mode == FaceMode.enroll) {
      await _handleEnroll(path);
      return;
    }

    setState(() => _busy = true);
    try {
      final json = await ModeAnalyzer.analyze(
        mode,
        path,
        oddImageUri: _oddPath,
        landmarkMode: settings.landmarkMode,
      );
      if (!mounted) return;
      if (json == null || json.isEmpty) {
        AppDialogs.toast(context, 'Analysis failed');
        return;
      }

      String? thumbPath;
      String? thumb2Path;
      List<double>? landmarksXy;

      if (mode == FaceMode.match) {
        final odd = _oddPath ?? path;
        thumbPath = await _cropThumbPath(odd);
        thumb2Path = await _cropThumbPath(path);
      } else if (mode == FaceMode.landmarks) {
        final cropped = await _cropLandmarksThumb(path);
        thumbPath = cropped.path;
        landmarksXy = cropped.landmarksXy ?? _extractLandmarksXy(json);
      } else {
        thumbPath = await _cropThumbPath(path);
      }

      if (!mounted) return;
      _resultOpened = true;
      await stopVideoWorker();
      if (!mounted) return;
      context.pushReplacement(
        '/mode-result',
        extra: ModeResultArgs(
          mode: mode,
          json: json,
          thumbPath: thumbPath,
          thumb2Path: thumb2Path,
          landmarksXy: landmarksXy,
        ),
      );
    } catch (e) {
      if (mounted) AppDialogs.toast(context, 'Analysis failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleEnroll(String path) async {
    setState(() => _busy = true);
    try {
      final boxes = await faceDetection(
        path,
        const FaceDetectionParam(allAttributes: false),
      );
      if (boxes.length != 1) {
        if (mounted) {
          AppDialogs.toast(
            context,
            boxes.isEmpty ? 'No face detected!' : 'Multiple face detected!',
          );
        }
        return;
      }
      final feature = await templateExtraction(path, boxes.first);
      String? thumb;
      try {
        thumb = await cropFace(path, boxes.first);
      } catch (_) {
        thumb = null;
      }
      if (!mounted) return;
      final name = await _promptName();
      if (name == null || name.trim().isEmpty || !mounted) return;
      final person = await context.read<PersonDatabase>().add(
            name: name.trim(),
            featureBase64: feature,
            thumbnailBase64: thumb,
          );
      if (!mounted) return;
      String thumbPath = path;
      if (thumb != null && thumb.isNotEmpty) {
        try {
          thumbPath = await _writeTempJpeg(thumb);
        } catch (_) {
          thumbPath = await _cropThumbPath(path);
        }
      } else {
        thumbPath = await _cropThumbPath(path);
      }
      final json = jsonEncode({
        'success': true,
        'mode': FaceMode.enroll.id,
        'id': person.id,
        'name': person.name,
      });
      _resultOpened = true;
      await stopVideoWorker();
      if (!mounted) return;
      context.pushReplacement(
        '/mode-result',
        extra: ModeResultArgs(
          mode: FaceMode.enroll,
          json: json,
          thumbPath: thumbPath,
        ),
      );
    } catch (e) {
      if (mounted) AppDialogs.toast(context, 'Enrollment failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptName() async {
    final controller = TextEditingController(text: autoPersonName());
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Enroll name', style: TextStyle(color: AppColors.text)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(hintText: 'Person name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<double>? _extractLandmarksXy(String json) {
    try {
      final decoded = jsonDecode(json);
      dynamic faces;
      if (decoded is List) {
        faces = decoded;
      } else if (decoded is Map) {
        faces = decoded['faces'] ??
            (decoded['result'] is Map ? decoded['result']['faces'] : null);
      }
      if (faces is! List || faces.isEmpty) return null;
      final face = faces.first;
      if (face is! Map) return null;
      final lm = face['landmarks'] ?? face['facePoints'];
      if (lm is! List || lm.isEmpty) return null;
      final out = <double>[];
      for (final p in lm) {
        if (p is Map && p['x'] is num && p['y'] is num) {
          out.add((p['x'] as num).toDouble());
          out.add((p['y'] as num).toDouble());
        } else if (p is List && p.length >= 2 && p[0] is num && p[1] is num) {
          out.add((p[0] as num).toDouble());
          out.add((p[1] as num).toDouble());
        }
      }
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final settings = _settings ?? context.watch<SettingsService>().settings;
    final mirror = settings.cameraLens == CameraLens.front && Platform.isAndroid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_initializing)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          else if (c == null || !c.value.isInitialized)
            const Center(
              child: Text(
                'Camera unavailable',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            CoverCameraPreview(controller: c),
          if (!_isIdentity && c != null && c.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                return FaceOverlay(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  frameW: _frameSize.width,
                  frameH: _frameSize.height,
                  mirror: mirror,
                  boxes: _boxes,
                  settings: settings,
                );
              },
            ),
          if (_isIdentity && c != null && c.value.isInitialized)
            LayoutBuilder(
              builder: (context, constraints) {
                return IdentityGuide(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  frameW: _frameSize.width,
                  frameH: _frameSize.height,
                  mirror: mirror,
                  state: _identityState,
                  progress: _identityProgress,
                );
              },
            ),
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        widget.mode.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!_isIdentity)
                      IconButton(
                        onPressed: _busy ? null : _fromGallery,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: 1,
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _confirming && _isIdentity
                            ? 'Capturing…'
                            : _hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isIdentity
                              ? identityHintColor(_identityState)
                              : Colors.white70,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!_isIdentity) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _busy ? null : _capture,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _busy ? Colors.white38 : Colors.white24,
                          ),
                          child: _busy
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
