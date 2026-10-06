import 'dart:typed_data';

import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/services/classifier.dart';

/// Pengklasifikasi palsu dengan jawaban tetap, untuk uji tanpa TFLite.
class FakeClassifier implements FruitClassifier {
  final Map<Fruit, double> probabilities;
  int calls = 0;

  FakeClassifier(this.probabilities);

  @override
  Future<Prediction> classify(Uint8List imageBytes) async {
    calls++;
    return Prediction(probabilities);
  }

  @override
  Uint8List? get lastThumbnail => null;

  @override
  void dispose() {}
}
