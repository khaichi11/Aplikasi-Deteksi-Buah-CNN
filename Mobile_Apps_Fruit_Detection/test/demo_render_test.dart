// Rekam layar aplikasi sebagai bingkai PNG untuk GIF demo, tanpa emulator: layar digambar di laptop dengan model
// palsu, lalu disusun menjadi GIF dalam bingkai ponsel. Jalankan:
//   DEMO_FRAMES=build/frames flutter test test/demo_render_test.dart
//   python3 tool/render_gif.py build/frames docs/demo.gif
import 'dart:io';

import 'package:buah_seru/app.dart';
import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/services/app_state.dart';
import 'package:buah_seru/widgets/fruit_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo/demo_recorder.dart';
import 'fakes.dart';

void main() {
  final out = Platform.environment['DEMO_FRAMES'];
  testWidgets('bingkai demo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(
      () => loadFonts({
        for (final family in ['Poppins', 'Inter'])
          family: [
            for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/$family-$w.ttf',
          ],
      }),
    );
    final state = AppState();
    await state.load();
    if (out != null) Directory(out).createSync(recursive: true);
    final r = DemoRecorder(tester, out)..prepare();
    await tester.pumpWidget(
      r.wrap(
        BuahSeruApp(
          state: state,
          enableCamera: false,
          classifierLoader: () async => FakeClassifier(const {Fruit.apel: .93, Fruit.jeruk: .05, Fruit.pisang: .02}),
        ),
      ),
    );

    // 1. pembuka: huruf jatuh, tirai terangkat, buah jatuh; apel, jeruk, dan pisang diketuk
    r.scene = 'pembuka';
    await r.run(4400);
    final loader = tester.getRect(find.byType(FruitLoader));
    await r.tapAt(loader.topLeft + Offset(loader.width * .22, loader.height * .64), after: 900);
    await r.tapAt(loader.topLeft + Offset(loader.width * .5, loader.height * .64), after: 300);
    await r.tapAt(loader.topLeft + Offset(loader.width * .78, loader.height * .64), after: 1200);
    await r.run(2800);

    // 2. beranda
    r.scene = 'beranda';
    await r.settle();
    await r.run(1500);

    // 3. foto contoh apel; anak menebak keliru, melihat lagi, lalu mengganti pilihannya
    r.scene = 'tebak';
    await r.tap(find.text('Contoh'), after: 500);
    await r.settle();
    await r.run(400);
    await r.tap(find.textContaining('Apel').last, after: 300);
    await r.settle();
    await r.run(900);
    final wrong = [
      'Jeruk',
      'Pisang',
      'Mangga',
      'Nanas',
      'Anggur',
      'Semangka',
      'Pepaya',
      'Salak',
    ].firstWhere((n) => find.text(n).evaluate().isNotEmpty);
    await r.tap(find.text(wrong), after: 900);
    await r.scroll(-260, steps: 6);
    await r.run(1400);
    await r.scroll(220, steps: 4);
    await r.tap(find.text('Apel').first, after: 600);
    await r.scroll(-450);
    await r.run(1500);

    // 4. kembali ke beranda dan buka kartu buah
    r.scene = 'kartu';
    Navigator.of(tester.element(find.byType(Scrollable).first)).pop();
    await r.run(700);
    await r.settle();
    await r.tap(find.text('Pisang').first, after: 500);
    await r.settle();
    await r.run(1800);
    r.finish();
  }, skip: out == null);
}
