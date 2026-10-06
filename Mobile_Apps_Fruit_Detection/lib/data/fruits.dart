import 'package:flutter/material.dart';

/// Tiga buah yang dikenali model (urutan sama dengan assets/model/label.txt).
enum Fruit { apel, jeruk, pisang }

/// Nilai gizi per 100 g bagian yang dapat dimakan.
class Nutrition {
  final int energyKcal;
  final double carbG;
  final double fiberG;
  final double sugarG;
  final double vitaminCMg;
  final int potassiumMg;

  const Nutrition({
    required this.energyKcal,
    required this.carbG,
    required this.fiberG,
    required this.sugarG,
    required this.vitaminCMg,
    required this.potassiumMg,
  });
}

class FruitInfo {
  final Fruit fruit;
  final String name;
  final String latin;
  final String tagline;
  final Color color;
  final Color soft;
  final String sample;
  final List<String> benefits;
  final Nutrition nutrition;
  final String usdaName;
  final String tip;
  final String funFact;

  const FruitInfo({
    required this.fruit,
    required this.name,
    required this.latin,
    required this.tagline,
    required this.color,
    required this.soft,
    required this.sample,
    required this.benefits,
    required this.nutrition,
    required this.usdaName,
    required this.tip,
    required this.funFact,
  });
}

/// Sumber gizi: USDA FoodData Central (SR Legacy), per 100 g.
const Map<Fruit, FruitInfo> fruitInfo = {
  Fruit.apel: FruitInfo(
    fruit: Fruit.apel,
    name: 'Apel',
    latin: 'Malus domestica',
    tagline: 'Renyah, berserat, enak dimakan dengan kulitnya.',
    color: Color(0xFFD9473F),
    soft: Color(0xFFFCE3E1),
    sample: 'assets/samples/apel_tim.jpg',
    benefits: [
      'Seratnya, termasuk pektin, membantu pencernaan dan membuat kenyang lebih lama.',
      'Banyak senyawa baik (polifenol) ada di kulitnya, jadi cuci bersih lalu makan bersama kulitnya.',
      'Rendah kalori, cocok sebagai camilan sehat.',
    ],
    nutrition: Nutrition(
      energyKcal: 52,
      carbG: 13.8,
      fiberG: 2.4,
      sugarG: 10.4,
      vitaminCMg: 4.6,
      potassiumMg: 107,
    ),
    usdaName: 'Apples, raw, with skin',
    tip: 'Pilih yang keras dan kulitnya mulus tanpa memar. Simpan di kulkas agar tetap renyah lebih lama.',
    funFact: 'Apel bisa mengapung di air karena sekitar seperempat isinya adalah udara.',
  ),
  Fruit.jeruk: FruitInfo(
    fruit: Fruit.jeruk,
    name: 'Jeruk',
    latin: 'Citrus × sinensis',
    tagline: 'Segar dan kaya vitamin C.',
    color: Color(0xFFEE8A1E),
    soft: Color(0xFFFDEBD3),
    sample: 'assets/samples/jeruk_tim.jpg',
    benefits: [
      'Satu jeruk sedang (±130 g) mengandung sekitar 69 mg vitamin C, lebih dari kebutuhan harian anak usia sekolah.',
      'Vitamin C membantu daya tahan tubuh dan membantu tubuh menyerap zat besi dari makanan.',
      'Banyak mengandung air, membantu tubuh tetap terhidrasi.',
    ],
    nutrition: Nutrition(
      energyKcal: 47,
      carbG: 11.8,
      fiberG: 2.4,
      sugarG: 9.4,
      vitaminCMg: 53.2,
      potassiumMg: 181,
    ),
    usdaName: 'Oranges, raw, all commercial varieties',
    tip: 'Pilih yang terasa berat untuk ukurannya, tanda airnya banyak. Kulit hijau tidak selalu berarti belum manis.',
    funFact: 'Di daerah tropis seperti Indonesia, jeruk yang sudah matang bisa tetap berkulit hijau karena udaranya hangat.',
  ),
  Fruit.pisang: FruitInfo(
    fruit: Fruit.pisang,
    name: 'Pisang',
    latin: 'Musa spp.',
    tagline: 'Sumber energi cepat dan kalium.',
    color: Color(0xFFD9A400),
    soft: Color(0xFFFFF1C2),
    sample: 'assets/samples/pisang.jpg',
    benefits: [
      'Sumber kalium yang baik untuk kerja otot dan saraf, serta membantu menjaga tekanan darah.',
      'Karbohidratnya memberi energi cepat, cocok dimakan sebelum bermain atau berolahraga.',
      'Mengandung vitamin B6 yang dibutuhkan tubuh untuk mengolah makanan menjadi energi.',
    ],
    nutrition: Nutrition(
      energyKcal: 89,
      carbG: 22.8,
      fiberG: 2.6,
      sugarG: 12.2,
      vitaminCMg: 8.7,
      potassiumMg: 358,
    ),
    usdaName: 'Bananas, raw',
    tip: 'Kuning dengan bintik cokelat kecil berarti manis dan siap dimakan. Simpan terpisah dari buah lain bila tidak ingin cepat matang.',
    funFact: 'Secara botani pisang termasuk buah beri, dan tanamannya bukan pohon melainkan terna raksasa.',
  ),
};

extension FruitX on Fruit {
  FruitInfo get info => fruitInfo[this]!;
  String get name => info.name;

  /// Menerima label model ("apel") maupun nama tampilan ("Apel").
  /// Catatan: `f.name` di sini adalah nama tampilan dari ekstensi ini, bukan
  /// nama enum, jadi nama enum diambil lewat EnumName.
  static Fruit? fromLabel(String label) {
    final l = label.trim().toLowerCase();
    for (final f in Fruit.values) {
      if (EnumName(f).name == l || f.info.name.toLowerCase() == l) return f;
    }
    return null;
  }
}

/// Foto contoh untuk mencoba tanpa buah asli: apel dan jeruk foto tim sendiri,
/// pisang dari Wikimedia Commons (CC0).
class SamplePhoto {
  final String asset;
  final Fruit fruit;
  final String caption;

  const SamplePhoto(this.asset, this.fruit, this.caption);
}

const List<SamplePhoto> samplePhotos = [
  SamplePhoto('assets/samples/apel_tim.jpg', Fruit.apel, 'Apel'),
  SamplePhoto('assets/samples/jeruk_tim.jpg', Fruit.jeruk, 'Jeruk'),
  SamplePhoto('assets/samples/pisang.jpg', Fruit.pisang, 'Pisang'),
  SamplePhoto('assets/samples/pisang_tandan.jpg', Fruit.pisang, 'Tandan pisang'),
];
