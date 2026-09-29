import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:face_recognition_sdk/face_recognition_sdk.dart';
import '../modes/face_mode.dart';
import '../screens/about/about_screen.dart';
import '../screens/attribute/attribute_screen.dart';
import '../screens/capture/capture_screen.dart';
import '../screens/enrolled/enrolled_list_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/identify/identify_screen.dart';
import '../screens/mode/mode_camera_screen.dart';
import '../screens/mode/mode_result_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/settings/settings_screen.dart';

class AttributeResultArgs {
  const AttributeResultArgs({
    required this.faceUri,
    required this.box,
    this.cropLandmarks = const [],
  });

  final String faceUri;
  final FaceBox box;
  final List<({double x, double y})> cropLandmarks;
}

class IdentifyResultArgs {
  const IdentifyResultArgs({
    required this.identifiedUri,
    this.enrolledThumbPath,
    required this.personName,
    required this.similarity,
    required this.box,
    this.cropLandmarks = const [],
  });

  final String identifiedUri;
  final String? enrolledThumbPath;
  final String personName;
  final double similarity;
  final FaceBox box;
  final List<({double x, double y})> cropLandmarks;
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/identify',
      builder: (context, state) => const IdentifyScreen(),
    ),
    GoRoute(
      path: '/capture',
      builder: (context, state) => const CaptureScreen(),
    ),
    GoRoute(
      path: '/enrolled',
      builder: (context, state) => const EnrolledListScreen(),
    ),
    GoRoute(
      path: '/mode/:mode',
      builder: (context, state) {
        final name = state.pathParameters['mode'] ?? 'faceDetect';
        final mode = FaceMode.fromId(name);
        return ModeCameraScreen(mode: mode);
      },
    ),
    GoRoute(
      path: '/mode-result',
      builder: (context, state) {
        final args = state.extra as ModeResultArgs;
        return ModeResultScreen(args: args);
      },
    ),
    GoRoute(
      path: '/attribute',
      builder: (context, state) {
        final args = state.extra as AttributeResultArgs;
        return AttributeScreen(args: args);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) {
        final args = state.extra as IdentifyResultArgs;
        return ResultScreen(args: args);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
);

void goIdentifyResult(BuildContext context, IdentifyResultArgs args) {
  context.pushReplacement('/result', extra: args);
}

void goAttributeResult(BuildContext context, AttributeResultArgs args) {
  context.push('/attribute', extra: args);
}

void goModeResult(BuildContext context, ModeResultArgs args) {
  context.pushReplacement('/mode-result', extra: args);
}
