import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';

import '../app.dart';
import '../data/fruits.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/history_tile.dart';
import 'about_screen.dart';
import 'camera_screen.dart';
import 'fruit_screen.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatelessWidget {
  final bool enableCamera;

  const HomeScreen({super.key, this.enableCamera = true});

  Future<void> _open(BuildContext context, Uint8List? bytes) async {
    if (bytes == null || !context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(imageBytes: bytes)));
  }

  Future<void> _fromCamera(BuildContext context) async {
    if (!enableCamera) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamera tidak tersedia.')));
      return;
    }
    final bytes = await Navigator.of(context)
        .push<Uint8List>(MaterialPageRoute(builder: (_) => const CameraScreen()));
    if (context.mounted) await _open(context, bytes);
  }

  Future<void> _fromGallery(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) await _open(context, bytes);
  }

  Future<void> _fromSamples(BuildContext context) async {
    final sample = await showModalBottomSheet<SamplePhoto>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _SampleSheet(),
    );
    if (sample == null) return;
    final data = await rootBundle.load(sample.asset);
    if (context.mounted) await _open(context, data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    final recent = state.history.take(3).toList();
    final collection = state.collection;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(
            onHistory: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
            onAbout: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Panel(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        _Stat(value: '${state.points}', label: 'Poin'),
                        const _StatDivider(),
                        _Stat(value: '${state.streak}', label: 'Benar beruntun'),
                        const _StatDivider(),
                        _Stat(
                          value: state.history.isEmpty ? '-' : '${state.aiRightCount}/${state.history.length}',
                          label: 'AI benar',
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionTitle('Kenali buah'),
                      Row(
                        children: [
                          for (final f in Fruit.values) ...[
                            if (f != Fruit.values.first) const SizedBox(width: 12),
                            Expanded(
                              child: _FruitCard(
                                fruit: f,
                                found: collection[f] ?? 0,
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => FruitScreen(fruit: f))),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SectionTitle(
                        'Tebakan terakhir',
                        trailing: state.history.isEmpty
                            ? null
                            : TextButton(
                                onPressed: () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                                child: const Text('Lihat semua'),
                              ),
                      ),
                      if (recent.isEmpty)
                        const Panel(
                          child: Text(
                            'Belum ada tebakan. Foto apel, jeruk, atau pisang, '
                            'atau coba dulu dengan foto contoh.',
                            style: TextStyle(color: AppColors.inkSoft, height: 1.45),
                          ),
                        )
                      else
                        Panel(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(
                            children: [
                              for (var i = 0; i < recent.length; i++) ...[
                                if (i > 0) const Divider(),
                                HistoryTile(record: recent[i]),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        onGallery: () => _fromGallery(context),
        onCamera: () => _fromCamera(context),
        onSamples: () => _fromSamples(context),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onAbout;

  const _Header({required this.onHistory, required this.onAbout});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.purple,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 10, 8, 50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandTitle(),
              const Spacer(),
              IconButton(
                onPressed: onHistory,
                tooltip: 'Riwayat',
                icon: const Icon(Icons.history_rounded, color: Colors.white),
              ),
              IconButton(
                onPressed: onAbout,
                tooltip: 'Tentang',
                icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ayo tebak buah!', style: displayStyle(size: 26, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Foto buahnya, tebak namanya, lalu lihat apakah AI setuju denganmu.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: numberStyle(size: 22)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 34, color: AppColors.line);
}

class _FruitCard extends StatelessWidget {
  final Fruit fruit;
  final int found;
  final VoidCallback onTap;

  const _FruitCard({required this.fruit, required this.found, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = fruit.info;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.asset(info.sample, fit: BoxFit.cover, cacheWidth: 360),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.name, style: displayStyle(size: 16)),
                    const SizedBox(height: 2),
                    Text(
                      found == 0 ? 'Belum ditemukan' : 'Ditemukan $found×',
                      style: TextStyle(
                        fontSize: 12,
                        color: found == 0 ? AppColors.inkSoft : AppColors.leaf,
                        fontWeight: found == 0 ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bilah bawah: galeri, tombol kamera besar, dan foto contoh.
class _ActionBar extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onSamples;

  const _ActionBar({required this.onGallery, required this.onCamera, required this.onSamples});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(child: _BarButton(icon: Icons.photo_library_outlined, label: 'Galeri', onTap: onGallery)),
              Semantics(
                button: true,
                label: 'Foto dengan kamera',
                child: GestureDetector(
                  onTap: onCamera,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.apple, width: 5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 4),
                      const Text('Kamera',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.purple)),
                    ],
                  ),
                ),
              ),
              Expanded(child: _BarButton(icon: Icons.collections_outlined, label: 'Contoh', onTap: onSamples)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BarButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.ink, size: 26),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class _SampleSheet extends StatelessWidget {
  const _SampleSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coba dengan foto contoh', style: displayStyle(size: 19)),
            const SizedBox(height: 4),
            const Text('Tidak ada buah di dekatmu? Pilih salah satu foto ini.',
                style: TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            GridView(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final s in samplePhotos)
                  InkWell(
                    onTap: () => Navigator.of(context).pop(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(s.asset, fit: BoxFit.cover, width: double.infinity, cacheWidth: 240),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(s.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
