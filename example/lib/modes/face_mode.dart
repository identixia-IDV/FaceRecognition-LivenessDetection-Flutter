/// Demo modes — Flutter edition of Android FaceMode / Windows Gradio tabs.
enum FaceMode {
  faceDetect(
    'FACE_DETECT',
    'Face detect',
    needsRecognition: true,
    needsLiveness: false,
  ),
  faceAttribute(
    'FACE_ATTRIBUTE',
    'Face attribute',
    needsRecognition: true,
    needsLiveness: false,
  ),
  imageQuality(
    'IMAGE_QUALITY',
    'Image quality',
    needsRecognition: true,
    needsLiveness: false,
  ),
  landmarks(
    'LANDMARKS',
    'Landmarks',
    needsRecognition: true,
    needsLiveness: false,
  ),
  match(
    'MATCH',
    'Match',
    needsRecognition: true,
    needsLiveness: false,
  ),
  liveness(
    'LIVENESS',
    'Liveness',
    needsRecognition: false,
    needsLiveness: true,
  ),
  enroll(
    'ENROLL',
    'Enroll',
    needsRecognition: true,
    needsLiveness: false,
  ),
  identity(
    'IDENTITY',
    'Identity',
    needsRecognition: true,
    needsLiveness: false,
    usesVideoWorker: true,
  ),
  enrolledList(
    'ENROLLED_LIST',
    'Enrolled list',
    needsRecognition: true,
    needsLiveness: false,
  );

  const FaceMode(
    this.id,
    this.title, {
    required this.needsRecognition,
    required this.needsLiveness,
    this.usesVideoWorker = false,
  });

  /// Android `FaceMode.name` (e.g. FACE_DETECT).
  final String id;
  final String title;
  final bool needsRecognition;
  final bool needsLiveness;
  final bool usesVideoWorker;

  static FaceMode fromId(String? raw) {
    if (raw == null || raw.isEmpty) return FaceMode.faceDetect;
    for (final m in FaceMode.values) {
      if (m.id == raw ||
          m.id.toLowerCase() == raw.toLowerCase() ||
          m.name.toLowerCase() == raw.toLowerCase()) {
        return m;
      }
    }
    return FaceMode.faceDetect;
  }

  /// Alias for [fromId].
  static FaceMode fromName(String? raw) => fromId(raw);
}
