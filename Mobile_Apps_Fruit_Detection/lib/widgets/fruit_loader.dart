import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Animasi pembuka: apel, jeruk, dan pisang melompat bergantian, dan sesekali seekor ulat mengintip dari lubang apel.
/// Ketuk sebuah buah untuk membuatnya melompat tinggi sambil berputar; ketuk apel untuk memanggil ulatnya keluar.
/// Semua digambar dengan kode, tanpa gambar dari luar.
class FruitLoader extends StatefulWidget {
  const FruitLoader({super.key, this.size = 180});

  final double size;

  @override
  State<FruitLoader> createState() => _FruitLoaderState();
}

class _FruitLoaderState extends State<FruitLoader> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _t = 0;
  final _jump = [0.0, 0.0, 0.0]; // sisa waktu lompatan tinggi tiap buah
  double _worm = 0; // sisa waktu ulat keluar karena apel diketuk

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration elapsed) {
    final dt = math.min((elapsed - _last).inMicroseconds / 1e6, 1 / 30);
    _last = elapsed;
    setState(() {
      _t += dt;
      for (var i = 0; i < 3; i++) {
        _jump[i] = math.max(0, _jump[i] - dt);
      }
      _worm = math.max(0, _worm - dt);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tap(TapDownDetails d) {
    final x = d.localPosition.dx / widget.size;
    final i = x < .37 ? 0 : (x < .63 ? 1 : 2);
    HapticFeedback.lightImpact();
    _jump[i] = _FruitPainter.jumpSec;
    if (i == 0) _worm = 2.2;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Buah melompat bergantian',
    child: GestureDetector(
      onTapDown: _tap,
      child: SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(painter: _FruitPainter(_t, List.of(_jump), _worm)),
      ),
    ),
  );
}

class _FruitPainter extends CustomPainter {
  _FruitPainter(this.t, this.jump, this.worm);

  final double t, worm;
  final List<double> jump;

  static const jumpSec = .9;
  static const _xs = [.22, .5, .78];
  static const _ground = .64;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.scale(s);
    for (var i = 0; i < 3; i++) {
      // lompatan kecil bergantian seperti ombak; lompatan tinggi saat diketuk
      final phase = (t * .9 - i * .18) % 1;
      final hop = phase < .5 ? math.sin(phase * 2 * math.pi) : 0.0;
      final j = jump[i] > 0 ? math.sin((1 - jump[i] / jumpSec) * math.pi) : 0.0;
      final lift = .07 * hop + .3 * j;
      final spin = jump[i] > 0 ? (1 - jump[i] / jumpSec) * 2 * math.pi : 0.0;
      // gepeng sedikit saat menyentuh tanah
      final squash = hop == 0 && jump[i] == 0 ? 1 - .06 * math.sin((phase - .5) * 4 * math.pi).abs() : 1.0;
      final x = _xs[i];
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, _ground + .15),
          width: .2 * (1 - lift * 1.4),
          height: .04 * (1 - lift * 1.4),
        ),
        Paint()..color = const Color(0x1F221B2E),
      );
      canvas.save();
      canvas.translate(x, _ground - lift);
      canvas.rotate(spin);
      canvas.scale(1.4 * (2 - squash), 1.4 * squash);
      switch (i) {
        case 0:
          _apple(canvas);
        case 1:
          _orange(canvas);
        default:
          _banana(canvas);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  void _apple(Canvas canvas) {
    final body = Path()
      ..moveTo(0, -.055)
      ..cubicTo(.05, -.1, .115, -.06, .105, .0)
      ..cubicTo(.1, .07, .045, .1, 0, .085)
      ..cubicTo(-.045, .1, -.1, .07, -.105, .0)
      ..cubicTo(-.115, -.06, -.05, -.1, 0, -.055)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE5484D));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-.045, -.03), width: .03, height: .05),
      Paint()..color = const Color(0x55FFFFFF),
    );
    canvas.drawLine(
      const Offset(0, -.055),
      const Offset(.012, -.1),
      Paint()
        ..color = const Color(0xFF7A4B2A)
        ..strokeWidth = .012
        ..strokeCap = StrokeCap.round,
    );
    final leaf = Path()
      ..moveTo(.014, -.09)
      ..quadraticBezierTo(.05, -.13, .075, -.1)
      ..quadraticBezierTo(.045, -.075, .014, -.09);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF2E9D57));
    // ulat mengintip dari lubang di sisi kanan apel: muncul sebentar setiap beberapa detik, lebih lama saat diketuk
    final cycle = t % 4.2;
    final peek = worm > 0
        ? math.min(1.0, math.min(2.2 - worm, worm) / .3)
        : (cycle > 3.2 ? math.sin((cycle - 3.2) / 1.0 * math.pi) : 0.0);
    canvas.drawCircle(const Offset(.06, .02), .016, Paint()..color = const Color(0xFF8E2C30));
    if (peek > 0) {
      final head = Offset(.06 + .05 * peek, .02 - .035 * peek);
      final wave = worm > 0 ? math.sin(t * 14) * .01 : 0.0;
      canvas.drawLine(
        const Offset(.06, .02),
        head + Offset(wave, 0),
        Paint()
          ..color = const Color(0xFF8CCF6A)
          ..strokeWidth = .026
          ..strokeCap = StrokeCap.round,
      );
      final eye = Paint()..color = const Color(0xFF221B2E);
      canvas.drawCircle(head + Offset(wave - .006, -.004), .0045, eye);
      canvas.drawCircle(head + Offset(wave + .006, -.004), .0045, eye);
    }
  }

  void _orange(Canvas canvas) {
    canvas.drawCircle(Offset.zero, .095, Paint()..color = const Color(0xFFF59E2E));
    final dots = Paint()..color = const Color(0x33FFFFFF);
    for (final p in const [
      Offset(-.04, -.03),
      Offset(.03, -.045),
      Offset(.045, .03),
      Offset(-.02, .05),
      Offset(.0, .0),
    ]) {
      canvas.drawCircle(p, .007, dots);
    }
    canvas.drawCircle(const Offset(0, -.092), .012, Paint()..color = const Color(0xFF6B8E23));
    final leaf = Path()
      ..moveTo(0, -.095)
      ..quadraticBezierTo(-.035, -.135, -.065, -.11)
      ..quadraticBezierTo(-.03, -.085, 0, -.095);
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF2E9D57));
  }

  void _banana(Canvas canvas) {
    final body = Path()
      ..moveTo(-.1, -.06)
      ..quadraticBezierTo(-.08, .1, .1, .06)
      ..quadraticBezierTo(.115, .045, .095, .03)
      ..quadraticBezierTo(-.04, .03, -.07, -.07)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFF6CF4A));
    canvas.drawPath(
      Path()
        ..moveTo(-.075, -.035)
        ..quadraticBezierTo(-.04, .05, .07, .045),
      Paint()
        ..color = const Color(0x40B07A12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .008,
    );
    final tip = Paint()..color = const Color(0xFF6B4A1F);
    canvas.drawCircle(const Offset(-.088, -.066), .012, tip);
    canvas.drawCircle(const Offset(.1, .05), .007, tip);
  }

  @override
  bool shouldRepaint(_FruitPainter old) => true;
}
