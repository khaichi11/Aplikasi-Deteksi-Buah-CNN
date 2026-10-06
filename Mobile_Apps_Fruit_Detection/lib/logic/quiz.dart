import 'dart:math';

import '../data/fruits.dart';

/// Nama buah pengecoh untuk pilihan kuis (selain tiga buah yang dikenali model).
const List<String> distractorNames = ['Mangga', 'Nanas', 'Anggur', 'Semangka', 'Pepaya', 'Salak'];

/// Tiga pilihan jawaban: tebakan AI ditambah dua pengecoh, diacak.
List<String> quizOptions(Fruit aiAnswer, Random rng) {
  final pool = [
    for (final f in Fruit.values)
      if (f != aiAnswer) f.name,
    ...distractorNames,
  ]..shuffle(rng);
  return [aiAnswer.name, ...pool.take(2)]..shuffle(rng);
}

/// Pendapat pengguna ketika tebakannya berbeda dengan tebakan AI.
enum Verdict { mine, ai, neither }

/// Hasil satu putaran kuis.
class QuizOutcome {
  /// Jawaban benar menurut pengguna; null bila bukan salah satunya.
  final String? truth;
  final bool userCorrect;

  /// Apakah tebakan AI benar menurut pengguna.
  final bool aiCorrect;
  final int points;

  const QuizOutcome({
    required this.truth,
    required this.userCorrect,
    required this.aiCorrect,
    required this.points,
  });
}

const int pointsPerCorrect = 10;

/// Nilai satu putaran. Bila tebakan pengguna sama dengan AI, keduanya dianggap
/// benar. Bila berbeda, pengguna memilih mana yang benar ([verdict]).
QuizOutcome evaluate({required String guess, required Fruit ai, Verdict? verdict}) {
  if (guess == ai.name) {
    return QuizOutcome(truth: guess, userCorrect: true, aiCorrect: true, points: pointsPerCorrect);
  }
  switch (verdict) {
    case Verdict.mine:
      return QuizOutcome(truth: guess, userCorrect: true, aiCorrect: false, points: pointsPerCorrect);
    case Verdict.ai:
      return QuizOutcome(truth: ai.name, userCorrect: false, aiCorrect: true, points: 0);
    case Verdict.neither:
    case null:
      return const QuizOutcome(truth: null, userCorrect: false, aiCorrect: false, points: 0);
  }
}
