import 'dart:io';

import 'package:flutter/material.dart';

import '../services/tv_toast_service.dart';
import '../theme/app_colors.dart';
import '../widgets/exit_confirm_dialog.dart';
import 'app_update_config.dart';
import 'app_update_service.dart';

abstract final class AppUpdateFlow {
  static Future<void> check(
    BuildContext context,
    AppUpdateService service, {
    bool force = false,
  }) async {
    if (!force && !service.shouldAutoCheck) {
      return;
    }
    try {
      final GithubReleaseInfo? latest = await service.fetchLatest();
      await service.markChecked();
      if (!context.mounted) {
        return;
      }
      if (latest == null) {
        if (force) {
          TvToastService.show(
            context,
            'Yüklü PC sürümü ${AppVersionInfo.current.name}. GitHub’da Windows paketi yok.',
            type: TvToastType.info,
          );
        }
        return;
      }
      if (!latest.version.isNewerThan(AppVersionInfo.current)) {
        if (force) {
          TvToastService.show(
            context,
            'Falcon IPTV PC ${AppVersionInfo.current.name} güncel.',
            type: TvToastType.success,
          );
        }
        return;
      }
      final GithubReleaseInfo update = latest;
      final bool install = await showNeonConfirmDialog(
        context: context,
        title: 'Yeni PC Sürümü',
        message:
            'Sürüm ${update.version.name} GitHub’da yayımlandı. Şu an ${AppVersionInfo.current.name} yüklü. Windows paketini indirmek ister misiniz?',
        cancelLabel: 'Daha sonra',
        confirmLabel: 'İndir',
        confirmColor: AppColors.neonCyan,
      );
      if (!install || !context.mounted) {
        return;
      }
      final File? cached = await service.cachedPackage(update);
      if (cached != null) {
        if (context.mounted) {
          TvToastService.show(
            context,
            'İndirilmiş paket kullanılıyor.',
            type: TvToastType.success,
          );
        }
        await service.revealPackage(cached);
        return;
      }
      await _downloadAndReveal(context, service, update);
    } catch (_) {
      if (force && context.mounted) {
        TvToastService.show(
          context,
          'Sürüm denetimi yapılamadı. İnternet bağlantınızı kontrol ediniz.',
        );
      }
    }
  }

  static Future<void> _downloadAndReveal(
    BuildContext context,
    AppUpdateService service,
    GithubReleaseInfo update,
  ) async {
    final ValueNotifier<double?> progress = ValueNotifier<double?>(null);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.45), width: 2),
          ),
          title: const Text(
            'Windows paketi indiriliyor',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          content: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    color: AppColors.neonCyan,
                    backgroundColor: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    value == null ? 'Hazırlanıyor…' : '%${(value * 100).clamp(0, 100).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, color: AppColors.textSecondary),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    try {
      final File file = await service.downloadPackage(
        update,
        onProgress: (int received, int total) {
          if (total > 0) {
            progress.value = received / total;
          }
        },
      );
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        TvToastService.show(
          context,
          'Paket indirildi. Klasör açılıyor; yeni exe ile değiştiriniz.',
          type: TvToastType.success,
        );
      }
      await service.revealPackage(file);
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        TvToastService.show(context, 'Güncelleme indirilemedi. Lütfen daha sonra yeniden deneyiniz.');
      }
    } finally {
      progress.dispose();
    }
  }
}
