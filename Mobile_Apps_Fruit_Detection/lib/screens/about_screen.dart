import 'package:flutter/material.dart';

import '../app.dart';
import '../theme.dart';
import '../widgets/common.dart';

const String appVersion = '2.0.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _resetScore(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mulai poin dari nol?'),
        content: const Text('Poin dan rekor benar beruntun akan kembali ke 0. Riwayat tidak dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mulai dari nol')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await AppScope.read(context).state.resetScore();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poin sudah kembali ke 0.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
        children: [
          Row(
            children: [
              Image.asset('assets/logo_buah_seru.png', width: 72, height: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Buah-Seru', style: displayStyle(size: 24)),
                    const Text('Versi $appVersion · aplikasi belajar mengenal buah',
                        style: TextStyle(color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SectionTitle('Cara bermain'),
          const _Step(1, 'Foto apel, jeruk, atau pisang. Bisa juga dari galeri atau foto contoh.'),
          const _Step(2, 'Tebak nama buahnya sebelum jawaban AI dibuka.'),
          const _Step(3, 'Bila kamu dan AI berbeda, putuskan mana yang benar.'),
          const _Step(4, 'Tebakan yang benar memberi 10 poin. Baca juga kartu gizi buahnya.'),
          const SectionTitle('Tentang AI-nya'),
          const Panel(
            child: Text(
              'Buah-Seru memakai model CNN (jaringan saraf konvolusi) yang dilatih tim untuk '
              'mengenali tiga buah: apel, jeruk, dan pisang. Foto diperkecil ke 320 × 258 piksel '
              'lalu diproses langsung di HP dengan TensorFlow Lite, tanpa internet.\n\n'
              'AI ini selalu memilih salah satu dari tiga buah itu, bahkan untuk buah lain, dan '
              'kadang terlalu yakin. Karena itu kamu yang menjadi juri terakhir.',
              style: TextStyle(height: 1.5),
            ),
          ),
          const SectionTitle('Data dan privasi'),
          const Panel(
            child: Text(
              'Foto tidak dikirim ke mana pun. Poin dan riwayat (dengan foto kecil) hanya disimpan '
              'di HP ini dan ikut terhapus bila aplikasi dihapus.',
              style: TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: state.points == 0 && state.bestStreak == 0 ? null : () => _resetScore(context),
            child: const Text('Mulai poin dari nol'),
          ),
          const SectionTitle('Sumber'),
          const _Credit('Data gizi', 'USDA FoodData Central (SR Legacy), per 100 gram.'),
          const _Credit('Foto apel dan jeruk', 'Foto tim Buah-Seru dari uji aplikasi versi pertama.'),
          const _Credit('Foto pisang', '"Bunch of bananas" oleh Pdpics.com, CC0, Wikimedia Commons.'),
          const _Credit('Foto tandan pisang', '"Jalgaon Banana Bunch closeup" oleh Amol Pandharkar, CC0, Wikimedia Commons.'),
          const _Credit('Huruf', 'Poppins dan Inter, SIL Open Font License 1.1.'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Buah-Seru',
                applicationVersion: appVersion,
              ),
              child: const Text('Lisensi pustaka'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String text;

  const _Step(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text('$number.', style: numberStyle(size: 16, color: AppColors.purple)),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

class _Credit extends StatelessWidget {
  final String title;
  final String text;

  const _Credit(this.title, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(text, style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
        ],
      ),
    );
  }
}
