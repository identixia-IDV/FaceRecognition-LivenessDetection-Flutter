import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Face crop with numbered landmark dots (Android LandmarkImageView).
class LandmarkImage extends StatefulWidget {
  const LandmarkImage({
    super.key,
    required this.width,
    required this.height,
    this.uri,
    this.filePath,
    this.landmarks = const [],
    this.imageSize,
  });

  final double width;
  final double height;
  final String? uri;
  final String? filePath;
  final List<({double x, double y})> landmarks;
  /// Source image pixel size for landmark coords. When null, measured from image.
  final Size? imageSize;

  @override
  State<LandmarkImage> createState() => _LandmarkImageState();
}

class _LandmarkImageState extends State<LandmarkImage> {
  Size? _measured;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  @override
  void didUpdateWidget(covariant LandmarkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri ||
        oldWidget.filePath != widget.filePath ||
        oldWidget.imageSize != widget.imageSize) {
      _measured = null;
      _measure();
    }
  }

  Future<void> _measure() async {
    if (widget.imageSize != null &&
        widget.imageSize!.width > 0 &&
        widget.imageSize!.height > 0) {
      return;
    }
    try {
      final bytes = await _loadBytes();
      if (bytes == null || !mounted) return;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _measured = Size(
          frame.image.width.toDouble(),
          frame.image.height.toDouble(),
        );
      });
      frame.image.dispose();
    } catch (_) {}
  }

  Future<Uint8List?> _loadBytes() async {
    final src = widget.filePath ?? widget.uri;
    if (src == null || src.isEmpty) return null;
    if (src.startsWith('data:image')) {
      final comma = src.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(src.substring(comma + 1));
    }
    final path = src.startsWith('file://') ? Uri.parse(src).toFilePath() : src;
    if (path.startsWith('/')) {
      return File(path).readAsBytes();
    }
    return null;
  }

  ImageProvider? _providerFor(String? src) {
    if (src == null || src.isEmpty) return null;
    if (src.startsWith('data:image')) {
      final comma = src.indexOf(',');
      if (comma < 0) return null;
      try {
        return MemoryImage(base64Decode(src.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    if (src.startsWith('file://')) {
      return FileImage(File(Uri.parse(src).toFilePath()));
    }
    if (src.startsWith('/')) {
      return FileImage(File(src));
    }
    return NetworkImage(src);
  }

  @override
  Widget build(BuildContext context) {
    final space = widget.imageSize ?? _measured ?? const Size(200, 200);
    final mapped = <Offset>[];
    if (widget.landmarks.isNotEmpty && space.width > 0 && space.height > 0) {
      final scale = (widget.width / space.width) < (widget.height / space.height)
          ? widget.width / space.width
          : widget.height / space.height;
      final dx = (widget.width - space.width * scale) / 2;
      final dy = (widget.height - space.height * scale) / 2;
      for (final p in widget.landmarks) {
        mapped.add(Offset(p.x * scale + dx, p.y * scale + dy));
      }
    }

    final provider =
        _providerFor(widget.filePath) ?? _providerFor(widget.uri);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.blackBg),
          if (provider != null)
            Image(
              image: provider,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const ColoredBox(color: AppColors.blackBg),
            ),
          for (var i = 0; i < mapped.length; i++)
            Positioned(
              left: mapped[i].dx - 4,
              top: mapped[i].dy - 4,
              child: IgnorePointer(
                child: SizedBox(
                  width: 8,
                  height: 8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E5FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Positioned(
                        top: -12,
                        left: -6,
                        width: 20,
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
