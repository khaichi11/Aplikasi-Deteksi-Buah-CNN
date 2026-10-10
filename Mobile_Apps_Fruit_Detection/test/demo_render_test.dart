// ignore_for_file: avoid_print
// Rekam layar aplikasi sebagai bingkai PNG untuk GIF demo, tanpa emulator: layar digambar di laptop dengan model
// palsu, lalu disusun menjadi GIF dalam bingkai ponsel. Jalankan:
//   DEMO_FRAMES=build/frames flutter test test/demo_render_test.dart
//   python3 tool/render_gif.py build/frames docs/demo.gif
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:buah_seru/app.dart';
import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/services/app_state.dart';
import 'package:buah_seru/widgets/fruit_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Future<void> _fonts() async {
  for (final (family, weights) in [
    ('Poppins', ['Regular', 'Medium', 'SemiBold', 'Bold']),
    ('Inter', ['Regular', 'Medium', 'SemiBold', 'Bold']),
  ]) {
    final loader = FontLoader(family);
    for (final w in weights) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$family-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter';
  final icons = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())))).load();
  }
}

/// Lingkaran sentuhan yang ikut terekam, supaya ketukan terlihat di GIF.
class _Touches extends StatelessWidget {
  const _Touches({required this.touch, required this.child});
  final ValueNotifier<(Offset, double)?> touch;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    textDirection: TextDirection.ltr,
    children: [
      child,
      ValueListenableBuilder(
        valueListenable: touch,
        builder: (_, t, _) => t == null
            ? const SizedBox.shrink()
            : Positioned(
                left: t.$1.dx - 22 - 10 * t.$2,
                top: t.$1.dy - 22 - 10 * t.$2,
                child: IgnorePointer(
                  child: Container(
                    width: 44 + 20 * t.$2,
                    height: 44 + 20 * t.$2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: .18 * (1 - t.$2)),
                      border: Border.all(color: Colors.white.withValues(alpha: .7 * (1 - t.$2)), width: 2),
                    ),
                  ),
                ),
              ),
      ),
    ],
  );
}

void main() {
  final out = Platform.environment['DEMO_FRAMES'];
  testWidgets('bingkai demo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_fonts);
    final state = AppState();
    await state.load();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    final touch = ValueNotifier<(Offset, double)?>(null);
    final manifest = <Map<String, dynamic>>[];
    var frame = 0, scene = '';
    if (out != null) Directory(out).createSync(recursive: true);

    Future<void> capture() async {
      if (out == null) return;
      await tester.runAsync(() async {
        final img = await (key.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage(pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        final name = 'f${(frame++).toString().padLeft(4, '0')}.png';
        File('$out/$name').writeAsBytesSync(png!.buffer.asUint8List());
        manifest.add({'file': name, 'scene': scene, 'ms': 100});
      });
    }

    // gambar setiap 33 ms seperti layar 30 fps, simpan setiap 100 ms
    Future<void> run(int ms) async {
      for (var t = 0; t < ms; t += 99) {
        for (var k = 0; k < 3; k++) {
          await tester.pump(const Duration(milliseconds: 33));
        }
        await capture();
      }
    }

    // biarkan gambar aset dan foto selesai didekode di luar jam palsu pengujian
    Future<void> settleImages() => tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));

    Future<void> tapAt(Offset at, {int after = 600}) async {
      for (var i = 0; i < 3; i++) {
        touch.value = (at, i / 6);
        await run(99);
      }
      await tester.tapAt(at);
      for (var i = 3; i < 6; i++) {
        touch.value = (at, i / 6);
        await run(99);
      }
      touch.value = null;
      await run(after);
    }

    Future<void> tap(Finder f, {int after = 600}) => tapAt(tester.getCenter(f), after: after);

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: _Touches(
          touch: touch,
          child: BuahSeruApp(
            state: state,
            enableCamera: false,
            classifierLoader: () async => FakeClassifier(const {Fruit.apel: .93, Fruit.jeruk: .05, Fruit.pisang: .02}),
          ),
        ),
      ),
    );

    // 1. pembuka: sapaan, logo bergerak, lalu cacing diketuk dan menari
    scene = 'pembuka';
    await run(3600);
    // ketuk apel (ulat keluar), lalu jeruk dan pisang (melompat sambil berputar)
    final loader = tester.getRect(find.byType(FruitLoader));
    await tapAt(loader.topLeft + Offset(loader.width * .22, loader.height * .7), after: 900);
    await tapAt(loader.topLeft + Offset(loader.width * .5, loader.height * .7), after: 300);
    await tapAt(loader.topLeft + Offset(loader.width * .78, loader.height * .7), after: 1200);
    await run(2600);

    // 2. beranda
    scene = 'beranda';
    await settleImages();
    await run(1500);

    // 3. foto contoh apel; anak menebak keliru, melihat lagi, lalu mengganti pilihannya
    scene = 'tebak';
    await tap(find.text('Contoh'), after: 500);
    await settleImages();
    await run(400);
    await tap(find.textContaining('Apel').last, after: 300);
    await settleImages();
    await run(900);
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
    await tap(find.text(wrong), after: 900);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -260));
    await run(1400);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 220));
    await run(300);
    await tap(find.text('Apel').first, after: 600);
    for (var i = 0; i < 10; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -45));
      await run(99);
    }
    await run(1500);

    // 4. kembali ke beranda dan buka kartu buah
    scene = 'kartu';
    Navigator.of(tester.element(find.byType(Scrollable).first)).pop();
    await run(700);
    await settleImages();
    await tap(find.text('Pisang').first, after: 500);
    await settleImages();
    await run(1800);

    if (out != null) File('$out/manifest.json').writeAsStringSync(jsonEncode(manifest));
  }, skip: out == null);
}
