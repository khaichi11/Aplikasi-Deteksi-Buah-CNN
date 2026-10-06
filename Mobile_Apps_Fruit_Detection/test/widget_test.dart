import 'dart:io';
import 'dart:math';

import 'package:buah_seru/app.dart';
import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/logic/quiz.dart';
import 'package:buah_seru/screens/result_screen.dart';
import 'package:buah_seru/services/app_state.dart';
import 'package:buah_seru/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

const _apel = {Fruit.apel: 0.92, Fruit.jeruk: 0.05, Fruit.pisang: 0.03};

void main() {
  late AppState state;

  /// Ukuran layar HP pada umumnya (412 x 892 dp).
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    state = AppState();
    await state.load();
  });

  testWidgets('beranda menampilkan merek, poin, dan tiga buah', (tester) async {
    phone(tester);
    await tester.pumpWidget(BuahSeruApp(
      state: state,
      classifierLoader: () async => FakeClassifier(_apel),
      enableCamera: false,
    ));
    await tester.pump();
    expect(find.text('Buah-Seru'), findsOneWidget);
    expect(find.text('Ayo tebak buah!'), findsOneWidget);
    expect(find.text('Poin'), findsOneWidget);
    for (final f in Fruit.values) {
      expect(find.text(f.name), findsOneWidget);
    }
    expect(find.text('Kamera'), findsOneWidget);
  });

  testWidgets('foto contoh: tebakan sama dengan AI menambah poin', (tester) async {
    phone(tester);
    final fake = FakeClassifier(_apel);
    await tester.pumpWidget(BuahSeruApp(state: state, classifierLoader: () async => fake, enableCamera: false));
    await tester.pump();

    await tester.tap(find.text('Contoh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apel').last);
    await tester.pumpAndSettle();

    expect(find.text('Menurutmu ini buah apa?'), findsOneWidget);
    expect(fake.calls, 1);
    await tester.ensureVisible(find.text('Apel'));
    await tester.tap(find.text('Apel'));
    await tester.pumpAndSettle();

    expect(find.text('Hebat, kalian sama-sama benar!'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
    expect(state.points, 10);
    expect(state.history.single.truth, 'Apel');
  });

  testWidgets('berbeda pendapat: anak memutuskan dirinya benar', (tester) async {
    phone(tester);
    final bytes = File('assets/samples/apel_tim.jpg').readAsBytesSync();
    final other = quizOptions(Fruit.apel, Random(3)).firstWhere((o) => o != 'Apel');
    await tester.pumpWidget(AppScope(
      state: state,
      classifierLoader: () async => FakeClassifier(_apel),
      child: MaterialApp(theme: buildTheme(), home: ResultScreen(imageBytes: bytes, random: Random(3))),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(other));
    await tester.tap(find.text(other));
    await tester.pumpAndSettle();
    expect(find.text('Kalian berbeda pendapat'), findsOneWidget);

    await tester.ensureVisible(find.text('Aku yang benar, ini $other'));
    await tester.tap(find.text('Aku yang benar, ini $other'));
    await tester.pumpAndSettle();
    expect(find.text('Kamu lebih jeli dari AI!'), findsOneWidget);
    expect(state.points, 10);
    expect(state.history.single.aiCorrect, isFalse);
  });
}
