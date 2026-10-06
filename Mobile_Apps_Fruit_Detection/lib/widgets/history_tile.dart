import 'dart:io';

import 'package:flutter/material.dart';

import '../data/fruits.dart';
import '../services/app_state.dart';
import '../theme.dart';

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Contoh: "7 Okt, 14.05".
String formatWaktu(DateTime t) {
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${t.day} ${_bulan[t.month - 1]}, ${dua(t.hour)}.${dua(t.minute)}';
}

/// Satu baris riwayat tebakan.
class HistoryTile extends StatelessWidget {
  final ScanRecord record;

  const HistoryTile({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final r = record;
    final benar = r.userCorrect;
    final path = r.thumbnailPath;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: path != null && File(path).existsSync()
                  ? Image.file(File(path), fit: BoxFit.cover, cacheWidth: 168)
                  : ColoredBox(
                      color: r.ai.info.soft,
                      child: Center(
                        child: Text(r.ai.name[0], style: displayStyle(size: 22, color: r.ai.info.color)),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.truth ?? 'Bukan buah yang dikenal',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  'Kamu: ${r.guess} · AI: ${r.ai.name} ${(r.aiConfidence * 100).round()}%',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                Text(formatWaktu(r.time), style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: benar ? AppColors.leafSoft : AppColors.wormSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              benar ? 'Benar' : 'Belum',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: benar ? AppColors.leaf : AppColors.worm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
