import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'fruit_loader.dart';

/// Pembuka Buah-Seru: di layar ungu huruf "Halo!" jatuh dan memantul seperti buah yang mendarat, lalu layar ungu
/// terangkat seperti tirai berupa panel datar bersudut membulat. Buah-buahan jatuh dari atas dan memantul di tengah layar
/// sementara model dimuat. Setelah [ready] selesai, semuanya memudar dan [onDone] dipanggil. Ketuk layar saat sapaan
/// untuk melewatinya; selama anak masih mengetuk buah, pembuka menunggu sampai beberapa detik.
class OpeningIntro extends StatefulWidget {
  const OpeningIntro({super.key, required this.onDone, this.ready});

  final Future<void>? ready;
  final VoidCallback onDone;

  @override
  State<OpeningIntro> createState() => _OpeningIntroState();
}

class _OpeningIntroState extends State<OpeningIntro> with SingleTickerProviderStateMixin {
  static const _greetSec = 2.4, _enterSec = 1.8, _exitSec = .6;
  static const _minHold = 1.2, _maxHold = 10.0, _quiet = 2.5; // detik: tampil minimal, menunggu maksimal, jeda bermain
  static const colors = [Color(0xFF7E57C2), AppColors.purple];

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _h = 0, _e = 0, _x = 0, _hold = 0, _clock = 0;
  double _poked = -10;
  bool _ready = false, _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    final ready = widget.ready;
    if (ready == null) {
      _ready = true;
    } else {
      ready.whenComplete(() => _ready = true).ignore();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _ticker.start());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// Selisih antarbingkai dibatasi 1/30 detik supaya gerakan tidak melompat saat ponsel sempat tersendat.
  void _tick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 1 / 30);
    _last = elapsed;
    _clock += dt;
    if (_h < 1) {
      _h = math.min(1, _h + dt / _greetSec);
    } else if (_e < 1) {
      _e = math.min(1, _e + dt / _enterSec);
    } else if (!_ready || _hold < _minHold || (_clock - _poked < _quiet && _hold < _maxHold)) {
      _hold += dt;
    } else if (_x < 1) {
      _x = math.min(1, _x + dt / _exitSec);
    } else if (!_done) {
      _done = true;
      _ticker.stop();
      widget.onDone();
      return;
    }
    setState(() {});
  }

  static double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final center = Offset(size.width / 2, math.min(size.height * .42, 380));
        final lift = _h < 1 ? 0.0 : Curves.easeInOutCubic.transform(_seg(_e, .05, .6));
        final leave = Curves.easeInCubic.transform(_x);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: lift < .5 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _h < .75 ? () => setState(() => _h = .75) : null,
            child: Stack(
              children: [
                if (_h == 1) ..._fruits(center, leave),
                if (lift < 1)
                  Positioned.fill(
                    child: IgnorePointer(child: CustomPaint(painter: _CurtainPainter(lift))),
                  ),
                if (_h < 1) ..._greeting(center),
              ],
            ),
          ),
        );
      },
    ),
  );

  /// Buah jatuh dari atas dan memantul setelah tirai lewat, lalu judul dan garis kemajuan muncul.
  List<Widget> _fruits(Offset center, double leave) {
    final drop = Curves.bounceOut.transform(_seg(_e, .35, .85));
    final words = Curves.easeOutCubic.transform(_seg(_e, .75, 1));
    return [
      Positioned.fromRect(
        rect: Rect.fromCenter(center: center, width: 240, height: 240),
        child: Opacity(
          opacity: (_seg(_e, .35, .45) * (1 - leave)).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -260 * (1 - drop) - 40 * leave),
            child: Listener(onPointerDown: (_) => _poked = _clock, child: const FruitLoader(size: 240)),
          ),
        ),
      ),
      if (words > 0)
        Positioned(
          left: 32,
          right: 32,
          top: center.dy + 120,
          child: Opacity(
            opacity: words * (1 - leave),
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - words) + 10 * leave),
              child: Column(
                children: [
                  Text('Buah-Seru', style: displayStyle(size: 30)),
                  const SizedBox(height: 4),
                  const Text('Tebak buah bersama AI', style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _ready ? 1 : null,
                        minHeight: 3,
                        color: AppColors.purple,
                        backgroundColor: AppColors.purpleSoft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Ketuk buahnya', style: TextStyle(fontSize: 12.5, color: AppColors.ink.withValues(alpha: .45))),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  /// Huruf "Halo!" jatuh satu per satu, memantul, dan sedikit miring seperti buah yang mendarat.
  List<Widget> _greeting(Offset center) {
    const letters = 'Halo!';
    final out = Curves.easeInCubic.transform(_seg(_h, .75, .95));
    final welcome = Curves.easeOutCubic.transform(_seg(_h, .45, .62));
    return [
      Positioned(
        left: 0,
        right: 0,
        top: center.dy - 40,
        child: Opacity(
          opacity: 1 - out,
          child: Transform.translate(
            offset: Offset(0, -40 * out),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < letters.length; i++)
                  Builder(
                    builder: (_) {
                      final t = _seg(_h, .02 + i * .07, .32 + i * .07);
                      final fall = Curves.bounceOut.transform(t);
                      return Opacity(
                        opacity: t == 0 ? 0 : 1,
                        child: Transform.translate(
                          offset: Offset(0, -220 * (1 - fall)),
                          child: Transform.rotate(
                            angle: (i.isEven ? -1 : 1) * .25 * (1 - fall),
                            child: Text(
                              letters[i],
                              style: displayStyle(size: 52, color: Colors.white).copyWith(height: 1.1),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        top: center.dy + 34,
        child: Opacity(
          opacity: welcome * (1 - out),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - welcome)),
            child: Text(
              'Selamat datang di Buah-Seru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: .92)),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Layar ungu yang terangkat seperti tirai: panel datar dengan sudut bawah membulat.
class _CurtainPainter extends CustomPainter {
  _CurtainPainter(this.lift);

  final double lift; // 0 menutup penuh, 1 sudah terangkat

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final bottom = h * (1 - lift);
    if (bottom <= 0) return;
    // sudut membulat baru terlihat saat panel mulai naik
    final r = 32 * (lift * 6).clamp(0.0, 1.0);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(0, -40, w, bottom, bottomLeft: Radius.circular(r), bottomRight: Radius.circular(r)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _OpeningIntroState.colors,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_CurtainPainter old) => old.lift != lift;
}
