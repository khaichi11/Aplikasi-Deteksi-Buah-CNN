import 'dart:io';
import 'dart:typed_data';

import 'package:buah_seru/data/fruits.dart';
import 'package:buah_seru/services/classifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('prepare: ukuran masukan 320x258x3 dan nilai 0..1', () {
    final src = img.Image(width: 640, height: 480);
    img.fill(src, color: img.ColorRgb8(255, 128, 0));
    final p = prepare(Uint8List.fromList(img.encodeJpg(src)));
    expect(p.input.length, 320 * 258 * 3);
    expect(p.input.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(1.0));
    expect(p.input[0], closeTo(1.0, 0.03));
    expect(p.input[1], closeTo(0.5, 0.03));
    expect(p.input[2], closeTo(0.0, 0.03));
  });

  test('prepare: gambar kecil untuk riwayat paling panjang 480 px', () {
    final bytes = File('assets/samples/pisang.jpg').readAsBytesSync();
    final thumb = img.decodeJpg(prepare(bytes).thumbnail)!;
    expect(thumb.width <= 480 && thumb.height <= 480, isTrue);
  });

  test('prepare: berkas rusak menimbulkan galat', () {
    expect(() => prepare(Uint8List.fromList([1, 2, 3])), throwsA(anything));
  });

  test('Prediction memilih peluang terbesar', () {
    const p = Prediction({Fruit.apel: 0.2, Fruit.jeruk: 0.7, Fruit.pisang: 0.1});
    expect(p.top, Fruit.jeruk);
    expect(p.confidence, 0.7);
    expect(p.isConfident, isTrue);
    expect(const Prediction({Fruit.apel: 0.4, Fruit.jeruk: 0.35, Fruit.pisang: 0.25}).isConfident, isFalse);
  });
}
