import 'package:flutter/material.dart';

import '../data/fruits.dart';
import '../theme.dart';

/// Judul bagian.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 26, 2, 12),
      child: Row(
        children: [
          Expanded(child: Text(text, style: displayStyle(size: 18))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Kartu putih dengan garis tepi tipis.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AppColors.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: child,
    );
  }
}

/// Batang peluang untuk satu buah.
class ProbabilityBar extends StatelessWidget {
  final Fruit fruit;
  final double value;
  final bool highlight;

  const ProbabilityBar({super.key, required this.fruit, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final info = fruit.info;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(info.name,
                style: TextStyle(
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.ink,
                )),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppColors.line,
                valueColor: AlwaysStoppedAnimation(highlight ? info.color : AppColors.inkSoft.withValues(alpha: 0.35)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            child: Text('${(value * 100).round()}%',
                textAlign: TextAlign.right,
                style: numberStyle(size: 14, weight: highlight ? FontWeight.w700 : FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// Logo Buah-Seru (di kotak putih) dengan nama aplikasi, untuk header ungu.
class BrandTitle extends StatelessWidget {
  final double logo;

  const BrandTitle({super.key, this.logo = 38});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logo,
          height: logo,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Image.asset('assets/logo_buah_seru.png'),
        ),
        const SizedBox(width: 10),
        Text('Buah-Seru', style: displayStyle(size: 21, color: Colors.white)),
      ],
    );
  }
}
