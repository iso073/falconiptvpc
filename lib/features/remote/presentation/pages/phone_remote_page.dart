import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/device/app_layout.dart';
import '../../../../core/remote/phone_remote_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/exit_confirm_dialog.dart';
import '../../../../core/widgets/glassmorphism_bar.dart';
import '../../../../core/widgets/neon_focus_card.dart';
import '../../../../core/widgets/tv_back_scope.dart';

class PhoneRemotePage extends StatefulWidget {
  const PhoneRemotePage({super.key});

  @override
  State<PhoneRemotePage> createState() => _PhoneRemotePageState();
}

class _PhoneRemotePageState extends State<PhoneRemotePage> {
  PhoneRemoteSession? _session;
  String? _error;
  Timer? _pulse;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
    _pulse = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pulse?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final PhoneRemoteSession session = await PhoneRemoteService.ensureStarted();
      if (mounted) {
        setState(() => _session = session);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    }
  }

  bool get _recentCommand {
    final DateTime? at = PhoneRemoteService.lastCommandAt;
    return at != null && DateTime.now().difference(at) < const Duration(seconds: 3);
  }

  @override
  Widget build(BuildContext context) {
    final Uri? uri = _session?.uri;
    return TvBackScope(
      onBack: () => popToPreviousPage(context),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.ambientGlow),
          child: SafeArea(
            child: Padding(
              padding: AppLayout.pagePadding(context),
              child: Column(
                children: [
                  GlassmorphismBar(
                    child: Row(
                      children: [
                        NeonFocusCard(
                          autofocus: true,
                          width: AppLayout.backButton(context),
                          height: AppLayout.backButton(context),
                          padding: EdgeInsets.zero,
                          focusedScale: 1.0,
                          onActivate: () => Navigator.of(context).maybePop(),
                          child: const Center(child: Icon(Icons.arrow_back_rounded)),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.settings_remote_rounded, color: AppColors.neonCyan, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Telefon Kumandası',
                            style: TextStyle(
                              fontSize: AppLayout.titleSize(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _error != null
                        ? Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 20, height: 1.4),
                                  ),
                                  const SizedBox(height: 18),
                                  NeonFocusCard(
                                    onActivate: _start,
                                    child: const Text(
                                      'Yeniden Dene',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: uri == null
                                      ? const SizedBox(
                                          width: 240,
                                          height: 240,
                                          child: Center(
                                            child: CircularProgressIndicator(color: AppColors.neonCyan),
                                          ),
                                        )
                                      : QrImageView(
                                          data: uri.toString(),
                                          size: 240,
                                          backgroundColor: Colors.white,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Telefonunuzun kamerası ile karekodu okutunuz.',
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Açılan sayfa kumanda olur. Telefon ile PC aynı Wi‑Fi ağında olmalıdır. Windows ilk seferde ağ izni sorabilir; izin veriniz.',
                                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                    const SizedBox(height: 18),
                                    if (uri != null) ...[
                                      SelectableText(
                                        uri.toString(),
                                        style: const TextStyle(
                                          color: AppColors.neonCyan,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Kod: ${_session!.token}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          letterSpacing: 1.4,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      _recentCommand
                                          ? 'Kumanda komutu alındı.'
                                          : 'Kumanda bekleniyor. Bu sayfadan çıksanız da bağlantı açık kalır.',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: _recentCommand ? AppColors.success : AppColors.neonPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
