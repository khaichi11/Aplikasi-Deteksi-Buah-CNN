import 'dart:io';

import 'package:buah_seru/app.dart';
import 'package:buah_seru/services/app_state.dart';
import 'package:buah_seru/services/classifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tangkapan layar setiap layar dengan model TFLite sungguhan.
/// Jalankan: flutter drive --driver=test_driver/integration_test.dart \
///   --target=integration_test/screenshots_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tangkapan layar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/riwayat_uji');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    final state = AppState(thumbnailDir: dir);
    await state.load();
    await binding.convertFlutterSurfaceToImage();

    Future<void> settle([int frames = 10]) async {
      for (var i = 0; i < frames; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> shoot(String name) async {
      await settle();
      await binding.takeScreenshot(name);
    }

    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f);
      await settle(3);
      await tester.tap(f);
      await settle();
    }

    /// Model berjalan di isolate, jadi tunggu dengan waktu sungguhan.
    Future<void> waitFor(Finder f) async {
      for (var i = 0; i < 100 && f.evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      expect(f, findsWidgets);
    }

    Future<void> back() async {
      await tester.pageBack();
      await settle();
    }

    Future<void> playSample(String caption, String guess) async {
      await tap(find.text('Contoh'));
      await tap(find.text(caption).last);
      await waitFor(find.text(guess));
      await tap(find.text(guess));
    }

    await tester.pumpWidget(BuahSeruApp(state: state, classifierLoader: TfliteFruitClassifier.load));
    await settle(20);
    await shoot('01-beranda');

    await tap(find.text('Contoh'));
    await shoot('02-foto-contoh');
    await tap(find.text('Jeruk').last);
    await waitFor(find.text('Menurutmu ini buah apa?'));
    await shoot('03-tebak');
    await tap(find.text('Jeruk'));
    await waitFor(find.text('Hebat, kalian sama-sama benar!'));
    await shoot('04-hasil');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await shoot('05-keyakinan-ai');

    await tap(find.textContaining('Kenalan dengan'));
    await shoot('06-kartu-buah');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await shoot('07-kartu-buah-gizi');
    await back();
    await back();

    await playSample('Apel', 'Apel');
    await back();
    await tap(find.text('Contoh'));
    await tap(find.text('Tandan pisang'));
    await waitFor(find.text('Pisang'));
    final other = find.byWidgetPredicate((w) =>
        w is Text && const ['Mangga', 'Nanas', 'Anggur', 'Semangka', 'Pepaya', 'Salak', 'Apel', 'Jeruk']
            .contains(w.data));
    await tap(other.first);
    await tester.ensureVisible(find.text('Kalian berbeda pendapat'));
    await shoot('08-beda-pendapat');
    await tap(find.textContaining('AI yang benar'));
    await back();

    await shoot('09-beranda-terisi');
    await tap(find.byTooltip('Riwayat'));
    await shoot('10-riwayat');
    await back();
    await tap(find.byTooltip('Tentang'));
    await shoot('11-tentang');
  });
}
