import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../data/fruits.dart';

/// Hasil klasifikasi satu foto.
class Prediction {
  /// Peluang tiap buah (jumlahnya 1).
  final Map<Fruit, double> probabilities;

  const Prediction(this.probabilities);

  Fruit get top => probabilities.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

  double get confidence => probabilities[top] ?? 0;

  /// Di bawah ambang ini aplikasi memberi tahu bahwa model kurang yakin.
  static const double confidentThreshold = 0.6;

  bool get isConfident => confidence >= confidentThreshold;
}

/// Hasil pra-proses: masukan model dan gambar kecil untuk riwayat.
class Prepared {
  final Float32List input;
  final Uint8List thumbnail;

  const Prepared(this.input, this.thumbnail);
}

abstract class FruitClassifier {
  Future<Prediction> classify(Uint8List imageBytes);

  /// Gambar kecil (JPEG) dari foto terakhir, untuk disimpan di riwayat.
  Uint8List? get lastThumbnail;

  void dispose();
}

/// Pra-proses sama seperti saat pelatihan: ubah ukuran ke 320x258 tanpa
/// memotong, lalu nilai piksel RGB dibagi 255. Orientasi EXIF diterapkan dulu
/// agar foto dari kamera tidak masuk ke model dalam keadaan terputar.
Prepared prepare(Uint8List bytes, {int width = 320, int height = 258}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Berkas bukan gambar yang bisa dibaca');
  }
  final upright = img.bakeOrientation(decoded);
  final resized = img.copyResize(
    upright,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
  final input = Float32List(width * height * 3);
  var i = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = resized.getPixel(x, y);
      input[i++] = p.r / 255.0;
      input[i++] = p.g / 255.0;
      input[i++] = p.b / 255.0;
    }
  }
  final longest = math.max(upright.width, upright.height);
  final thumb = longest > 480
      ? img.copyResize(upright,
          width: upright.width >= upright.height ? 480 : null,
          height: upright.height > upright.width ? 480 : null)
      : upright;
  return Prepared(input, Uint8List.fromList(img.encodeJpg(thumb, quality: 82)));
}

/// Klasifikasi dengan model CNN (TensorFlow Lite) di perangkat.
class TfliteFruitClassifier implements FruitClassifier {
  final Interpreter _interpreter;
  final List<Fruit> _labels;
  Uint8List? _lastThumbnail;

  TfliteFruitClassifier._(this._interpreter, this._labels);

  static const String modelAsset = 'assets/model/buah_cnn_258x320.tflite';
  static const String labelAsset = 'assets/model/label.txt';

  static Future<TfliteFruitClassifier> load() async {
    final interpreter = await Interpreter.fromAsset(
      modelAsset,
      options: InterpreterOptions()..threads = 4,
    );
    final raw = await rootBundle.loadString(labelAsset);
    final labels = [
      for (final l in raw.split('\n'))
        if (l.trim().isNotEmpty) FruitX.fromLabel(l)!,
    ];
    return TfliteFruitClassifier._(interpreter, labels);
  }

  @override
  Uint8List? get lastThumbnail => _lastThumbnail;

  @override
  Future<Prediction> classify(Uint8List imageBytes) async {
    // Decode dan ubah ukuran foto 12 MP cukup berat, jadi dikerjakan di isolate
    // lain agar layar tidak tersendat.
    final prepared = await Isolate.run(() => prepare(imageBytes));
    _lastThumbnail = prepared.thumbnail;
    final output = Float32List(_labels.length);
    _interpreter.run(prepared.input.buffer, output.buffer);
    return Prediction({for (var i = 0; i < _labels.length; i++) _labels[i]: output[i]});
  }

  @override
  void dispose() => _interpreter.close();
}
