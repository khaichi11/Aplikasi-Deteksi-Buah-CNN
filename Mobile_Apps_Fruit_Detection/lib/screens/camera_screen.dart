import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';

/// Kamera dengan lingkaran pemandu seperti versi awal aplikasi. Mengembalikan
/// foto (JPEG) lewat Navigator.pop.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _error;
  bool _busy = false;
  bool _starting = false;
  FlashMode _flash = FlashMode.off;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      _controller = null;
      c?.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && c == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) throw CameraException('none', 'Tidak ada kamera');
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      await c.setFlashMode(_flash);
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _error = null;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt'
          ? 'Izin kamera ditolak. Izinkan kamera di pengaturan, atau pakai kamera bawaan HP.'
          : 'Kamera tidak bisa dibuka. Coba pakai kamera bawaan HP.');
    } finally {
      _starting = false;
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || _busy || !c.value.isInitialized) return;
    setState(() => _busy = true);
    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) Navigator.of(context).pop(bytes);
    } on CameraException {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memotret. Coba lagi.')));
      }
    }
  }

  /// Cadangan bila plugin kamera gagal: pakai aplikasi kamera bawaan HP.
  Future<void> _systemCamera() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (mounted) Navigator.of(context).pop(bytes);
  }

  Future<void> _toggleFlash() async {
    final c = _controller;
    if (c == null) return;
    final next = _flash == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await c.setFlashMode(next);
      setState(() => _flash = next);
    } on CameraException {/* HP tanpa lampu kilat */}
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && c.value.isInitialized)
            Center(child: CameraPreview(c))
          else if (_error == null)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (_error == null) const IgnorePointer(child: CustomPaint(painter: _GuidePainter())),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, color: Colors.white, size: 44),
                    const SizedBox(height: 14),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4)),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _systemCamera, child: const Text('Pakai kamera bawaan')),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Tutup',
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      if (c != null)
                        IconButton(
                          onPressed: _toggleFlash,
                          tooltip: 'Lampu',
                          icon: Icon(
                            _flash == FlashMode.off ? Icons.flash_off_rounded : Icons.flash_on_rounded,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error == null)
                  Text('Taruh buah di dalam lingkaran',
                      style: displayStyle(size: 17, color: Colors.white, weight: FontWeight.w600)),
                const Spacer(),
                if (_error == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Semantics(
                      button: true,
                      label: 'Ambil foto',
                      child: GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 78,
                          height: 78,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _busy ? Colors.white54 : AppColors.purple,
                            ),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gelapkan sekeliling lingkaran supaya anak tahu di mana buah diletakkan.
class _GuidePainter extends CustomPainter {
  const _GuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.46);
    final radius = math.min(size.width, size.height) * 0.38;
    final circle = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final scrim = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), circle);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.45));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
