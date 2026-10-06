import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/fruits.dart';

/// Satu foto yang pernah ditebak.
class ScanRecord {
  final String id;
  final DateTime time;
  final String? thumbnailPath;
  final Fruit ai;
  final double aiConfidence;
  final String guess;

  /// Jawaban benar menurut pengguna; null bila bukan salah satunya.
  final String? truth;
  final bool aiCorrect;

  const ScanRecord({
    required this.id,
    required this.time,
    required this.thumbnailPath,
    required this.ai,
    required this.aiConfidence,
    required this.guess,
    required this.truth,
    required this.aiCorrect,
  });

  bool get userCorrect => truth != null && guess == truth;

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        if (thumbnailPath != null) 'thumb': thumbnailPath,
        'ai': ai.name,
        'aiConfidence': aiConfidence,
        'guess': guess,
        if (truth != null) 'truth': truth,
        'aiCorrect': aiCorrect,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> j) => ScanRecord(
        id: j['id'] as String,
        time: DateTime.parse(j['time'] as String),
        thumbnailPath: j['thumb'] as String?,
        ai: FruitX.fromLabel(j['ai'] as String) ?? Fruit.apel,
        aiConfidence: (j['aiConfidence'] as num).toDouble(),
        guess: j['guess'] as String,
        truth: j['truth'] as String?,
        aiCorrect: j['aiCorrect'] as bool,
      );
}

/// Skor kuis dan riwayat, disimpan di perangkat (tanpa akun dan tanpa server).
class AppState extends ChangeNotifier {
  static const _kPoints = 'poin';
  static const _kStreak = 'beruntun';
  static const _kBest = 'beruntun_terbaik';
  static const _kHistory = 'riwayat';
  static const int maxHistory = 60;

  SharedPreferences? _prefs;

  /// Folder untuk menyimpan gambar kecil riwayat; null = tidak disimpan.
  final Directory? thumbnailDir;

  AppState({this.thumbnailDir});

  int points = 0;
  int streak = 0;
  int bestStreak = 0;
  final List<ScanRecord> _history = [];

  List<ScanRecord> get history => List.unmodifiable(_history);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    points = p.getInt(_kPoints) ?? 0;
    streak = p.getInt(_kStreak) ?? 0;
    bestStreak = p.getInt(_kBest) ?? 0;
    final raw = p.getString(_kHistory);
    if (raw != null) {
      try {
        _history
          ..clear()
          ..addAll([
            for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>()) ScanRecord.fromJson(e),
          ]);
      } catch (_) {/* abaikan data rusak */}
    }
    notifyListeners();
  }

  /// Berapa kali tebakan AI dinilai benar oleh pengguna.
  int get aiRightCount => _history.where((r) => r.aiCorrect).length;

  /// Jumlah foto per buah yang sudah dikenali (berdasarkan jawaban benar).
  Map<Fruit, int> get collection {
    final m = {for (final f in Fruit.values) f: 0};
    for (final r in _history) {
      final f = r.truth == null ? null : FruitX.fromLabel(r.truth!);
      if (f != null) m[f] = m[f]! + 1;
    }
    return m;
  }

  Future<void> record({
    required Fruit ai,
    required double aiConfidence,
    required String guess,
    required String? truth,
    required bool aiCorrect,
    required int earned,
    Uint8List? thumbnail,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    String? path;
    final dir = thumbnailDir;
    if (thumbnail != null && dir != null) {
      try {
        await dir.create(recursive: true);
        final f = File('${dir.path}/$id.jpg');
        await f.writeAsBytes(thumbnail, flush: true);
        path = f.path;
      } catch (_) {/* riwayat tetap dicatat tanpa gambar */}
    }
    _history.insert(
      0,
      ScanRecord(
        id: id,
        time: DateTime.now(),
        thumbnailPath: path,
        ai: ai,
        aiConfidence: aiConfidence,
        guess: guess,
        truth: truth,
        aiCorrect: aiCorrect,
      ),
    );
    while (_history.length > maxHistory) {
      final old = _history.removeLast();
      _deleteThumb(old);
    }
    if (earned > 0) {
      points += earned;
      streak += 1;
      if (streak > bestStreak) bestStreak = streak;
    } else {
      streak = 0;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    for (final r in _history) {
      _deleteThumb(r);
    }
    _history.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> resetScore() async {
    points = 0;
    streak = 0;
    bestStreak = 0;
    await _persist();
    notifyListeners();
  }

  void _deleteThumb(ScanRecord r) {
    final p = r.thumbnailPath;
    if (p == null) return;
    try {
      File(p).deleteSync();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt(_kPoints, points);
    await p.setInt(_kStreak, streak);
    await p.setInt(_kBest, bestStreak);
    await p.setString(_kHistory, jsonEncode(_history.map((e) => e.toJson()).toList()));
  }
}
