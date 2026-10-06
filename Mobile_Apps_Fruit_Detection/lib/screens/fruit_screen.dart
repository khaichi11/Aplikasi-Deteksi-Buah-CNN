import 'package:flutter/material.dart';

import '../app.dart';
import '../data/fruits.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Kartu pengetahuan satu buah: gizi, manfaat, tips, dan fakta unik.
class FruitScreen extends StatelessWidget {
  final Fruit fruit;

  const FruitScreen({super.key, required this.fruit});

  @override
  Widget build(BuildContext context) {
    final info = fruit.info;
    final found = AppScope.of(context).state.collection[fruit] ?? 0;
    final n = info.nutrition;
    String num1(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

    return Scaffold(
      appBar: AppBar(title: Text(info.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(info.sample, fit: BoxFit.cover, cacheWidth: 900),
            ),
          ),
          const SizedBox(height: 18),
          Text(info.name, style: displayStyle(size: 28)),
          Text(info.latin, style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          Text(info.tagline, style: const TextStyle(fontSize: 16, height: 1.45)),
          const SizedBox(height: 10),
          Text(
            found == 0 ? 'Belum pernah kamu temukan. Ayo cari dan foto!' : 'Sudah kamu temukan $found kali.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: found == 0 ? AppColors.inkSoft : AppColors.leaf,
            ),
          ),
          const SectionTitle('Kandungan per 100 gram'),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                _Row('Energi', '${n.energyKcal} kkal'),
                _Row('Karbohidrat', '${num1(n.carbG)} g'),
                _Row('Serat', '${num1(n.fiberG)} g'),
                _Row('Gula alami', '${num1(n.sugarG)} g'),
                _Row('Vitamin C', '${num1(n.vitaminCMg)} mg'),
                _Row('Kalium', '${n.potassiumMg} mg', last: true),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sumber: USDA FoodData Central, "${info.usdaName}".',
            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SectionTitle('Manfaatnya'),
          for (final b in info.benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.check_circle_rounded, color: AppColors.leaf, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: const TextStyle(height: 1.45))),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Panel(
            color: AppColors.appleSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tips memilih', style: displayStyle(size: 16)),
                const SizedBox(height: 6),
                Text(info.tip, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            color: AppColors.purpleSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahukah kamu?', style: displayStyle(size: 16, color: AppColors.purple)),
                const SizedBox(height: 6),
                Text(info.funFact, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _Row(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.inkSoft))),
          Text(value, style: numberStyle(size: 15, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
