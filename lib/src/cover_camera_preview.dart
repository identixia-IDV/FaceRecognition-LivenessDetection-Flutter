import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Full-bleed cover preview — same idea as VisionCamera `resizeMode="cover"`
/// / Android PreviewView FILL_CENTER.
class CoverCameraPreview extends StatelessWidget {
  const CoverCameraPreview({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final preview = controller.value.previewSize;
    // previewSize is sensor-landscape; portrait box matches upright analysis frames.
    final w = preview?.height ?? 9.0;
    final h = preview?.width ?? 16.0;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: w,
          height: h,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
