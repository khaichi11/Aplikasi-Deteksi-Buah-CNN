import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/classifier.dart';
import 'theme.dart';

/// Layanan bersama untuk seluruh layar.
class AppScope extends InheritedNotifier<AppState> {
  final Future<FruitClassifier> Function() classifierLoader;

  const AppScope({
    super.key,
    required AppState state,
    required this.classifierLoader,
    required super.child,
  }) : super(notifier: state);

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  static AppScope read(BuildContext context) =>
      context.getElementForInheritedWidgetOfExactType<AppScope>()!.widget as AppScope;

  AppState get state => notifier!;
}

class BuahSeruApp extends StatefulWidget {
  final AppState state;
  final Future<FruitClassifier> Function() classifierLoader;

  /// Matikan fitur kamera (dipakai di uji widget tanpa plugin native).
  final bool enableCamera;

  const BuahSeruApp({
    super.key,
    required this.state,
    required this.classifierLoader,
    this.enableCamera = true,
  });

  @override
  State<BuahSeruApp> createState() => _BuahSeruAppState();
}

class _BuahSeruAppState extends State<BuahSeruApp> {
  Future<FruitClassifier>? _classifier;

  /// Model dimuat sekali, lalu dipakai bersama.
  Future<FruitClassifier> _load() => _classifier ??= widget.classifierLoader();

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
        home: HomeScreen(enableCamera: widget.enableCamera),
      ),
    );
  }
}
