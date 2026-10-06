import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/fruits.dart';
import '../logic/quiz.dart';
import '../services/classifier.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'fruit_screen.dart';

/// Satu putaran kuis: anak menebak dulu, baru jawaban AI dibuka.
class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;

  /// Untuk uji: pengacak pilihan jawaban yang bisa ditebak.
  final Random? random;

  const ResultScreen({super.key, required this.imageBytes, this.random});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  Prediction? _prediction;
  Uint8List? _thumbnail;
  Object? _error;
  List<String> _options = const [];

  String? _guess;
  QuizOutcome? _outcome;

  @override
  void initState() {
    super.initState();
    _classify();
  }

  Future<void> _classify() async {
    try {
      final classifier = await AppScope.read(context).classifierLoader();
      final p = await classifier.classify(widget.imageBytes);
      if (!mounted) return;
      setState(() {
        _prediction = p;
        _thumbnail = classifier.lastThumbnail;
        _options = quizOptions(p.top, widget.random ?? Random());
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _pick(String guess) {
    final ai = _prediction!.top;
    setState(() => _guess = guess);
    if (guess == ai.name) _finish(evaluate(guess: guess, ai: ai));
  }

  void _decide(Verdict v) => _finish(evaluate(guess: _guess!, ai: _prediction!.top, verdict: v));

  void _finish(QuizOutcome o) {
    final p = _prediction!;
    setState(() => _outcome = o);
    AppScope.read(context).state.record(
          ai: p.top,
          aiConfidence: p.confidence,
          guess: _guess!,
          truth: o.truth,
          aiCorrect: o.aiCorrect,
          earned: o.points,
          thumbnail: _thumbnail,
        );
  }

  @override
  Widget build(BuildContext context) {
    final p = _prediction;
    return Scaffold(
      appBar: AppBar(title: const Text('Tebak buahnya')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: ColoredBox(
                color: AppColors.line,
                child: Image.memory(widget.imageBytes, fit: BoxFit.cover, cacheWidth: 900, gaplessPlayback: true),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (_error != null)
            _ErrorPanel(onBack: () => Navigator.of(context).pop())
          else if (p == null)
            const _Loading()
          else ...[
            _GuessStep(options: _options, guess: _guess, ai: p.top, onPick: _guess == null ? _pick : null),
            if (_guess != null && _guess != p.top.name && _outcome == null) ...[
              const SizedBox(height: 16),
              _VerdictStep(guess: _guess!, prediction: p, onDecide: _decide),
            ],
            if (_outcome != null) ...[
              const SizedBox(height: 16),
              _OutcomePanel(outcome: _outcome!, ai: p.top, streak: AppScope.of(context).state.streak),
              const SizedBox(height: 16),
              _ConfidencePanel(prediction: p),
              _LearnMore(fruit: FruitX.fromLabel(_outcome!.truth ?? '') ?? (_outcome!.aiCorrect ? p.top : null)),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Tebak buah lain'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text('AI sedang melihat fotonya...', style: TextStyle(color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final VoidCallback onBack;

  const _ErrorPanel({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Panel(
      color: AppColors.wormSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fotonya tidak bisa dibaca', style: displayStyle(size: 17)),
          const SizedBox(height: 6),
          const Text('Coba foto lain, misalnya foto JPG atau PNG dari kamera.', style: TextStyle(height: 1.4)),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onBack, child: const Text('Kembali')),
        ],
      ),
    );
  }
}

/// Langkah 1: pilih satu dari tiga nama buah.
class _GuessStep extends StatelessWidget {
  final List<String> options;
  final String? guess;
  final Fruit ai;
  final ValueChanged<String>? onPick;

  const _GuessStep({required this.options, required this.guess, required this.ai, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Menurutmu ini buah apa?', style: displayStyle(size: 20)),
        const SizedBox(height: 4),
        Text(
          guess == null ? 'Pilih dulu, baru jawaban AI dibuka.' : 'Jawaban AI: ${ai.name}',
          style: const TextStyle(color: AppColors.inkSoft),
        ),
        const SizedBox(height: 14),
        for (final o in options) ...[
          _OptionButton(label: o, state: _stateOf(o), onTap: onPick == null ? null : () => onPick!(o)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  _OptionState _stateOf(String o) {
    if (guess == null) return _OptionState.idle;
    final mine = o == guess;
    final isAi = o == ai.name;
    if (mine && isAi) return _OptionState.both;
    if (mine) return _OptionState.mine;
    if (isAi) return _OptionState.ai;
    return _OptionState.dim;
  }
}

enum _OptionState { idle, mine, ai, both, dim }

class _OptionButton extends StatelessWidget {
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionButton({required this.label, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, String? note) = switch (state) {
      _OptionState.idle => (AppColors.surface, AppColors.line, null),
      _OptionState.mine => (AppColors.purpleSoft, AppColors.purple, 'Pilihanmu'),
      _OptionState.ai => (AppColors.appleSoft, const Color(0xFFE9B949), 'Tebakan AI'),
      _OptionState.both => (AppColors.leafSoft, AppColors.leaf, 'Kamu dan AI'),
      _OptionState.dim => (AppColors.surface, AppColors.line, null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: state == _OptionState.idle ? 1.5 : 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: displayStyle(
                    size: 17,
                    weight: FontWeight.w600,
                    color: state == _OptionState.dim ? AppColors.inkSoft : AppColors.ink,
                  ),
                ),
              ),
              if (note != null)
                Text(note, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: border)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Langkah 2 (bila berbeda): anak memutuskan mana yang benar.
class _VerdictStep extends StatelessWidget {
  final String guess;
  final Prediction prediction;
  final ValueChanged<Verdict> onDecide;

  const _VerdictStep({required this.guess, required this.prediction, required this.onDecide});

  @override
  Widget build(BuildContext context) {
    final ai = prediction.top.name;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kalian berbeda pendapat', style: displayStyle(size: 18)),
          const SizedBox(height: 6),
          Text(
            'Kamu memilih $guess, AI menebak $ai. Lihat lagi fotonya, mana yang benar?',
            style: const TextStyle(height: 1.45),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => onDecide(Verdict.mine), child: Text('Aku yang benar, ini $guess')),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => onDecide(Verdict.ai), child: Text('AI yang benar, ini $ai')),
          const SizedBox(height: 4),
          TextButton(onPressed: () => onDecide(Verdict.neither), child: const Text('Bukan dua-duanya')),
        ],
      ),
    );
  }
}

class _OutcomePanel extends StatelessWidget {
  final QuizOutcome outcome;
  final Fruit ai;
  final int streak;

  const _OutcomePanel({required this.outcome, required this.ai, required this.streak});

  @override
  Widget build(BuildContext context) {
    final o = outcome;
    final good = o.points > 0;
    final String title;
    final String body;
    if (o.userCorrect && o.aiCorrect) {
      title = 'Hebat, kalian sama-sama benar!';
      body = 'Ini memang ${o.truth}.';
    } else if (o.userCorrect) {
      title = 'Kamu lebih jeli dari AI!';
      body = 'Ini ${o.truth}. AI salah mengira ini ${ai.name}.';
    } else if (o.aiCorrect) {
      title = 'Kali ini AI yang benar';
      body = 'Ini ${o.truth}. Tidak apa-apa, coba lagi dengan buah lain.';
    } else {
      title = 'Buah ini belum dikenal AI';
      body = 'AI Buah-Seru baru mengenal apel, jeruk, dan pisang.';
    }
    return Panel(
      color: good ? AppColors.leafSoft : AppColors.appleSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: displayStyle(size: 18)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(height: 1.4)),
                if (good && streak > 1) ...[
                  const SizedBox(height: 6),
                  Text('$streak kali benar berturut-turut',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.leaf)),
                ],
              ],
            ),
          ),
          if (good) ...[
            const SizedBox(width: 12),
            Text('+${o.points}', style: numberStyle(size: 26, color: AppColors.leaf)),
          ],
        ],
      ),
    );
  }
}

class _ConfidencePanel extends StatelessWidget {
  final Prediction prediction;

  const _ConfidencePanel({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final p = prediction;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seberapa yakin AI?', style: displayStyle(size: 17)),
          const SizedBox(height: 10),
          for (final f in Fruit.values)
            ProbabilityBar(fruit: f, value: p.probabilities[f] ?? 0, highlight: f == p.top),
          const SizedBox(height: 8),
          Text(
            p.isConfident
                ? 'AI hanya bisa memilih apel, jeruk, atau pisang, jadi buah lain tetap akan '
                    'ditebak sebagai salah satunya.'
                : 'AI kurang yakin dengan foto ini. Coba foto lebih dekat, di tempat terang, '
                    'dengan satu buah saja.',
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LearnMore extends StatelessWidget {
  final Fruit? fruit;

  const _LearnMore({required this.fruit});

  @override
  Widget build(BuildContext context) {
    final f = fruit;
    if (f == null) return const SizedBox.shrink();
    final info = f.info;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FruitScreen(fruit: f))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(info.sample, width: 64, height: 64, fit: BoxFit.cover, cacheWidth: 192),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kenalan dengan ${info.name}', style: displayStyle(size: 16)),
                      const SizedBox(height: 2),
                      Text(info.funFact,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.35)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.inkSoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
