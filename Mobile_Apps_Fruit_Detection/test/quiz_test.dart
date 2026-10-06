import 'dart:math';

import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/logic/quiz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quizOptions', () {
    test('selalu tiga pilihan unik dan memuat jawaban AI', () {
      for (var seed = 0; seed < 50; seed++) {
        for (final f in Fruit.values) {
          final o = quizOptions(f, Random(seed));
          expect(o, hasLength(3));
          expect(o.toSet(), hasLength(3));
          expect(o, contains(f.name));
        }
      }
    });
  });

  test('fromLabel menerima label model dan nama tampilan', () {
    expect(FruitX.fromLabel('apel'), Fruit.apel);
    expect(FruitX.fromLabel('Jeruk'), Fruit.jeruk);
    expect(FruitX.fromLabel(' pisang\r'), Fruit.pisang);
    expect(FruitX.fromLabel('Mangga'), isNull);
  });

  group('evaluate', () {
    test('sama dengan AI: keduanya benar dan dapat poin', () {
      final r = evaluate(guess: 'Apel', ai: Fruit.apel);
      expect(r.truth, 'Apel');
      expect(r.userCorrect, isTrue);
      expect(r.aiCorrect, isTrue);
      expect(r.points, pointsPerCorrect);
    });

    test('berbeda, pengguna benar', () {
      final r = evaluate(guess: 'Jeruk', ai: Fruit.apel, verdict: Verdict.mine);
      expect(r.truth, 'Jeruk');
      expect(r.userCorrect, isTrue);
      expect(r.aiCorrect, isFalse);
      expect(r.points, pointsPerCorrect);
    });

    test('berbeda, AI benar', () {
      final r = evaluate(guess: 'Mangga', ai: Fruit.pisang, verdict: Verdict.ai);
      expect(r.truth, 'Pisang');
      expect(r.userCorrect, isFalse);
      expect(r.aiCorrect, isTrue);
      expect(r.points, 0);
    });

    test('bukan keduanya', () {
      final r = evaluate(guess: 'Mangga', ai: Fruit.pisang, verdict: Verdict.neither);
      expect(r.truth, isNull);
      expect(r.userCorrect, isFalse);
      expect(r.aiCorrect, isFalse);
      expect(r.points, 0);
    });
  });
}
