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

  const QuizOutcome({required this.truth, required this.userCorrect, required this.aiCorrect, required this.points});
}

const int pointsPerCorrect = 10;

/// Nilai satu putaran. Bila tebakan pengguna sama dengan AI, keduanya dianggap benar. Bila berbeda, pengguna memilih
/// mana yang benar ([verdict]). Anak boleh mengganti pilihan saat berbeda pendapat ([guess] adalah pilihan terakhir,
/// [firstGuess] yang pertama), tetapi poin hanya diberikan bila tebakan pertamanya benar; mengganti ke jawaban yang
/// benar tetap dihargai lewat pesan, bukan poin, supaya jawaban AI tidak bisa disalin.
QuizOutcome evaluate({required String guess, required Fruit ai, Verdict? verdict, String? firstGuess}) {
  final first = firstGuess ?? guess;
  final String? truth;
  final bool aiCorrect;
  if (guess == ai.name) {
    truth = guess;
    aiCorrect = true;
  } else {
    switch (verdict) {
      case Verdict.mine:
        truth = guess;
        aiCorrect = false;
      case Verdict.ai:
        truth = ai.name;
        aiCorrect = true;
      case Verdict.neither:
      case null:
        truth = null;
        aiCorrect = false;
    }
  }
  final userCorrect = truth != null && first == truth;
  return QuizOutcome(
    truth: truth,
    userCorrect: userCorrect,
    aiCorrect: aiCorrect,
    points: userCorrect ? pointsPerCorrect : 0,
  );
}
