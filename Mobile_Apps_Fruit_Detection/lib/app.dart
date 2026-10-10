import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/classifier.dart';
import 'theme.dart';
import 'widgets/fruit_loader.dart';
import 'widgets/opening_intro.dart';

/// Layanan bersama untuk seluruh layar.
class AppScope extends InheritedNotifier<AppState> {
  final Future<FruitClassifier> Function() classifierLoader;

  const AppScope({super.key, required AppState state, required this.classifierLoader, required super.child})
    : super(notifier: state);

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static AppScope read(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope;

  AppState get state => notifier!;
}

class BuahSeruApp extends StatefulWidget {
  final AppState state;
  final Future<FruitClassifier> Function() classifierLoader;

  /// Matikan fitur kamera (dipakai di uji widget tanpa plugin native).
  final bool enableCamera;

  /// Tampilkan pembuka saat aplikasi dibuka (dimatikan di uji widget).
  final bool intro;

  const BuahSeruApp({
    super.key,
    required this.state,
    required this.classifierLoader,
    this.enableCamera = true,
    this.intro = true,
  });

  @override
  State<BuahSeruApp> createState() => _BuahSeruAppState();
}

class _BuahSeruAppState extends State<BuahSeruApp> {
  Future<FruitClassifier>? _classifier;
  late bool _introDone = !widget.intro;

  /// Model dimuat sekali, lalu dipakai bersama. Bila gagal, percobaan berikutnya memuat ulang, bukan mengulang
  /// kegagalan yang sama.
  Future<FruitClassifier> _load() => _classifier ??= widget.classifierLoader()
    ..catchError((Object e) {
      _classifier = null;
      throw e;
    }).ignore();

  @override
  void dispose() {
    _classifier?.then((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      classifierLoader: _load,
      child: MaterialApp(
        title: 'Buah-Seru',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _introDone
              ? HomeScreen(enableCamera: widget.enableCamera)
              : OpeningIntro(
                  appName: 'Buah-Seru',
                  tagline: 'Tebak buah bersama AI',
                  mark: const FruitLoader(),
                  hint: 'Ketuk buahnya',
                  colors: const [Color(0xFF7E57C2), AppColors.purple],
                  paper: AppColors.background,
                  accent: AppColors.purple,
                  ink: AppColors.ink,
                  displayFont: AppFonts.display,
                  bodyFont: AppFonts.body,
                  // model dimuat selama pembuka, jadi tebakan pertama tidak menunggu lama
                  ready: _load().then((_) {}),
                  onDone: () => setState(() => _introDone = true),
                ),
        ),
      ),
    );
  }
}
