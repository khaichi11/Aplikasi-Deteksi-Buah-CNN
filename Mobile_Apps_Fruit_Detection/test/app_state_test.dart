import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/services/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> add(AppState s, {required String? truth, required int earned, bool aiCorrect = true}) => s.record(
        ai: Fruit.apel,
        aiConfidence: 0.9,
        guess: 'Apel',
        truth: truth,
        aiCorrect: aiCorrect,
        earned: earned,
      );

  test('poin, beruntun, dan rekor', () async {
    final s = AppState();
    await s.load();
    await add(s, truth: 'Apel', earned: 10);
    await add(s, truth: 'Apel', earned: 10);
    expect(s.points, 20);
    expect(s.streak, 2);
    await add(s, truth: null, earned: 0, aiCorrect: false);
    expect(s.streak, 0);
    expect(s.bestStreak, 2);
    expect(s.aiRightCount, 2);
    expect(s.collection[Fruit.apel], 2);
  });

  test('tersimpan dan dimuat ulang', () async {
    final a = AppState();
    await a.load();
    await add(a, truth: 'Apel', earned: 10);
    final b = AppState();
    await b.load();
    expect(b.points, 10);
    expect(b.history, hasLength(1));
    expect(b.history.first.guess, 'Apel');
  });

  test('riwayat dibatasi', () async {
    final s = AppState();
    await s.load();
    for (var i = 0; i < AppState.maxHistory + 5; i++) {
      await add(s, truth: 'Apel', earned: 10);
    }
    expect(s.history, hasLength(AppState.maxHistory));
  });

  test('hapus riwayat dan mulai poin dari nol', () async {
    final s = AppState();
    await s.load();
    await add(s, truth: 'Apel', earned: 10);
    await s.clearHistory();
    expect(s.history, isEmpty);
    expect(s.points, 10);
    await s.resetScore();
    expect(s.points, 0);
    expect(s.bestStreak, 0);
  });
}
