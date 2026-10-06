import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'services/app_state.dart';
import 'services/classifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  final docs = await getApplicationDocumentsDirectory();
  final state = AppState(thumbnailDir: Directory('${docs.path}/riwayat'));
  await state.load();
  runApp(BuahSeruApp(state: state, classifierLoader: TfliteFruitClassifier.load));
}
