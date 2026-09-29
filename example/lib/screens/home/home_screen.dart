import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../modes/face_mode.dart';
import '../../services/sdk_service.dart';
import '../../widgets/dialogs/app_dialogs.dart';

/// Android / Windows home: Attribute & Liveness 2×3 + Identity row + Settings/About.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openMode(BuildContext context, FaceMode mode) {
    final sdk = context.read<SdkService>();
    if (!sdk.ready) {
      AppDialogs.toast(
        context,
        sdk.loading ? 'Starting SDK…' : 'SDK is not ready',
      );
      return;
    }
    final deny = sdk.license.denyMessage(
      wantRecognition: mode.needsRecognition,
      wantLiveness: mode.needsLiveness,
    );
    if (deny != null) {
      AppDialogs.toast(context, deny);
      return;
    }
    switch (mode) {
      case FaceMode.enrolledList:
        context.push('/enrolled');
      case FaceMode.identity:
      default:
        context.push('/mode/${mode.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sdk = context.watch<SdkService>();
    final modesEnabled = sdk.ready;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: _Chip(
                    text: sdk.license.label.isNotEmpty
                        ? 'License · ${sdk.license.label}'
                        : (sdk.loading ? 'Starting…' : 'No license'),
                  ),
                ),
                const SizedBox(width: 12),
                _Chip(
                  text: sdk.ready
                      ? 'Ready'
                      : (sdk.loading ? 'Loading…' : 'No license'),
                  bold: true,
                ),
              ],
            ),
            if (sdk.status.isNotEmpty && !sdk.ready) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  sdk.status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _GroupLabel('Attribute & Liveness'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _ModeCell(
                        title: 'Face detect',
                        icon: Icons.camera_alt_outlined,
                        enabled: modesEnabled,
                        onTap: () => _openMode(context, FaceMode.faceDetect),
                      ),
                      const SizedBox(width: 8),
                      _ModeCell(
                        title: 'Face attribute',
                        icon: Icons.analytics_outlined,
                        enabled: modesEnabled,
                        onTap: () => _openMode(context, FaceMode.faceAttribute),
                      ),
                      const SizedBox(width: 8),
                      _ModeCell(
                        title: 'Image quality',
                        icon: Icons.high_quality_outlined,
                        enabled: modesEnabled,
                        onTap: () => _openMode(context, FaceMode.imageQuality),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ModeCell(
                        title: 'Landmarks',
                        icon: Icons.scatter_plot_outlined,
                        enabled: modesEnabled,
                        onTap: () => _openMode(context, FaceMode.landmarks),
                      ),
                      const SizedBox(width: 8),
                      _ModeCell(
                        title: 'Match',
                        icon: Icons.person_search_outlined,
                        enabled: modesEnabled,
                        onTap: () => _openMode(context, FaceMode.match),
                      ),
                      const SizedBox(width: 8),
                      _ModeCell(
                        title: 'Liveness',
                        icon: Icons.verified_user_outlined,
                        enabled: modesEnabled,
                        onTap: () => _openMode(context, FaceMode.liveness),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _GroupLabel('Identity'),
            const SizedBox(height: 8),
            SizedBox(
              height: 124,
              child: Row(
                children: [
                  _IdentityTile(
                    title: 'Enroll',
                    icon: Icons.person_add_alt_1,
                    enabled: modesEnabled,
                    onTap: () => _openMode(context, FaceMode.enroll),
                  ),
                  const SizedBox(width: 8),
                  _IdentityTile(
                    title: 'Identity',
                    icon: Icons.face_retouching_natural,
                    enabled: modesEnabled,
                    accent: true,
                    onTap: () => _openMode(context, FaceMode.identity),
                  ),
                  const SizedBox(width: 8),
                  _IdentityTile(
                    title: 'Enrolled list',
                    icon: Icons.people_outline,
                    enabled: modesEnabled,
                    onTap: () => _openMode(context, FaceMode.enrolledList),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 124,
              child: Row(
                children: [
                  Expanded(
                    child: _UtilityTile(
                      title: 'Settings',
                      icon: Icons.settings,
                      onTap: () => context.push('/settings'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _UtilityTile(
                      title: 'About',
                      icon: Icons.info_outline,
                      onTap: () => context.push('/about'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, this.bold = false});
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _ModeCell extends StatelessWidget {
  const _ModeCell({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 96,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: AppColors.accent),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdentityTile extends StatelessWidget {
  const _IdentityTile({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.accent = false,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = accent ? AppColors.accent : AppColors.surface;
    final fg = accent ? AppColors.onPrimary : AppColors.accent;
    final text = accent ? AppColors.onPrimary : AppColors.text;
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: fg),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UtilityTile extends StatelessWidget {
  const _UtilityTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
