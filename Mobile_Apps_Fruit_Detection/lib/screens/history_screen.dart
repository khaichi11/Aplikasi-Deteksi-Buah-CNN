import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/history_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _clear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua riwayat?'),
        content: const Text('Foto kecil dan catatan tebakan akan dihapus dari HP ini. Poin tidak berubah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true && context.mounted) await AppScope.read(context).state.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    final items = state.history;
    final userRight = items.where((r) => r.userCorrect).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              onPressed: () => _clear(context),
              tooltip: 'Hapus riwayat',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Belum ada tebakan. Tebakanmu akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                Panel(
                  child: Row(
                    children: [
                      _Summary(value: '${items.length}', label: 'Foto'),
                      _Summary(value: '$userRight', label: 'Tebakanmu benar'),
                      _Summary(value: '${state.aiRightCount}', label: 'Tebakan AI benar'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const Divider(),
                        HistoryTile(record: items[i]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Riwayat hanya disimpan di HP ini, paling banyak 60 foto terakhir.',
                  style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                ),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final String value;
  final String label;

  const _Summary({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: numberStyle(size: 22)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}
