import 'package:flutter/foundation.dart';

import '../core/constants/license.dart';
import 'package:face_recognition_sdk/face_recognition_sdk.dart' as fr;

class SdkService extends ChangeNotifier {
  String _status = 'Starting SDK…';
  bool _ready = false;
  bool _loading = true;
  String _machine = '';
  fr.LicenseStatus _license = fr.LicenseStatus.notLicensed;

  String get status => _status;
  bool get ready => _ready;
  bool get loading => _loading;
  String get machine => _machine;
  fr.LicenseStatus get license => _license;

  Future<void> bootstrap() async {
    _loading = true;
    _ready = false;
    _status = 'Starting SDK…';
    _license = fr.LicenseStatus.notLicensed;
    notifyListeners();

    try {
      final mc = await fr.getMachineCode();
      _machine = mc;
      debugPrint('[FaceRecognition] machine=$mc');

      final act = await fr.setActivation(demoLicense());
      debugPrint('[FaceRecognition] setActivation=$act');
      if (act != fr.sdkSuccess) {
        final detail = await fr.lastLicenseError();
        try {
          _license = fr.LicenseStatus.fromJson(await fr.getLicenseStatus());
        } catch (_) {}
        _status = '${_statusLabel(act)}${detail.isNotEmpty ? ': $detail' : ''}';
        _ready = false;
        _loading = false;
        notifyListeners();
        return;
      }

      final code = await fr.init();
      debugPrint('[FaceRecognition] init=$code');
      if (code == fr.sdkSuccess) {
        try {
          _license = fr.LicenseStatus.fromJson(await fr.getLicenseStatus());
          _status = fr.readyStatusMessage(_license.label);
        } catch (_) {
          _status = 'Ready';
        }
        _ready = true;
      } else {
        _status = _statusLabel(code);
        _ready = false;
      }
      _loading = false;
      notifyListeners();

      try {
        await fr.writeStatus({
          'step': 'dart',
          'status': _status,
          'ready': _ready,
          'machine': mc,
          'code': code,
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('[FaceRecognition] init exception=$e');
      _status = 'Init error: $e';
      _ready = false;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => bootstrap();

  String _statusLabel(int code) {
    switch (code) {
      case fr.sdkSuccess:
        return 'Ready';
      case fr.sdkLicenseInvalid:
        return 'Invalid license!';
      case fr.sdkLicenseExpired:
        return 'License expired';
      case fr.sdkNotActivated:
        return 'No activated!';
      case fr.sdkInitFailed:
        return 'Init error!';
      default:
        return 'Failed ($code)';
    }
  }
}
