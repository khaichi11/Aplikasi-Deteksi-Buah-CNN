import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, SystemUiOverlayStyle, SystemChrome;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';


class AppColors {
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color accentGreen = Color(0xFF8BC34A);
  static const Color lightGreen = Color(0xFFB2FF59);

  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: AppColors.primaryPurple,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Buah-Seru Project Sistem Cerdas',
    theme: ThemeData(
      primarySwatch: Colors.green,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primaryPurple,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
    ),
    home: ScannerPage(cameras: cameras),
    debugShowCheckedModeBanner: false,
  );
}

class ScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ScannerPage({super.key, required this.cameras});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  late final Classifier _classifier;
  bool _modelLoaded = false;
  File? _image;
  Map<String, double>? _results;
  bool _busy = false;
  String? _error;

  // Quiz-related variables
  bool _showQuiz = false;
  String? _selectedFruit;
  bool _quizAnswered = false;
  String? _detectedFruit;

  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Camera controller
  CameraController? _cameraController;
  bool _showCameraPreview = false;

  // Fruit information
  final Map<String, String> _fruitBenefits = {
    'apel': 'Apel mengandung serat, vitamin C, dan vitamin A yang bermanfaat untuk menjaga kesehatan jantung dan menurunkan risiko penyakit diabetes, serta menyehatkan mata!',
    'pisang': 'Pisang memiliki kandungan kalium yang dapat melancarkan pencernaan dan menurunkan risiko stroke!',
    'jeruk': 'jeruk memiliki vitamin C yang berguna untuk memelihara kesehatan rambut dan kulit, serta meningkatkan fungsi otak !',
  };

  @override
  void initState() {
    super.initState();
    _loadModel();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Ensure the status bar is the same color as the AppBar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.deepPurple,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _loadModel() async {
    setState(() {
      _modelLoaded = false;
      _error = null;
    });
    try {
      _classifier = await Classifier.create(
        inputHeight: 258,
        inputWidth: 320,
        threshold: 0.5,
      );
      setState(() {
        _modelLoaded = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat model: $e';
      });
      print('Model loading error: $e'); // Debugging output
    }
  }

  // Inisialisasi kamera
  void _initializeCamera() async {
    if (widget.cameras.isEmpty) {
      setState(() {
        _error = 'Tidak ada kamera yang ditemukan';
      });
      return;
    }

    // Pilih kamera belakang
    final rearCamera = widget.cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _cameraController = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _showCameraPreview = true;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal menginisialisasi kamera: $e';
      });
    }
  }

  void _closeCameraPreview() {
    setState(() {
      _showCameraPreview = false;
    });
    _cameraController?.dispose();
    _cameraController = null;
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _showCameraPreview = false;
        _busy = true;
        _image = File(image.path);
        _results = null;
        _error = null;
        _showQuiz = false;
        _quizAnswered = false;
        _selectedFruit = null;
      });

      // Dispose camera controller
      _cameraController?.dispose();
      _cameraController = null;

      // Analyze image
      await _analyzeImage();
    } catch (e) {
      setState(() {
        _error = 'Gagal mengambil gambar: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_modelLoaded) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _busy = true;
      _image = File(picked.path);
      _results = null;
      _error = null;
      _showQuiz = false;
      _quizAnswered = false;
      _selectedFruit = null;
    });

    await _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    try {
      final res = await _classifier.predict(_image!);
      setState(() {
        _results = res;
        if (_results != null && _results!.isNotEmpty) {
          // Get fruit with highest probability
          String topFruit = _results!.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          _detectedFruit = topFruit.toLowerCase();
          _showQuiz = true;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal menganalisis: $e';
      });
      print('Prediction error: $e'); // Debugging output
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _answerQuiz(String fruit) {
    setState(() {
      _selectedFruit = fruit;
      _quizAnswered = true;
      _animationController.forward();
    });
  }

  void _resetQuiz() {
    setState(() {
      _showQuiz = false;
      _quizAnswered = false;
      _selectedFruit = null;
      _image = null;
      _results = null;
      _animationController.reset();
    });
  }

  List<String> _getQuizOptions() {
    List<String> options = ['apel', 'pisang', 'jeruk', 'mangga', 'nanas', 'anggur'];

    // Pastikan detectedFruit selalu ada dalam opsi
    if (_detectedFruit != null) {
      // Hapus detectedFruit dari daftar jika sudah ada
      options.remove(_detectedFruit);
      // Pilih 2 opsi lain secara acak
      options.shuffle();
      List<String> finalOptions = options.take(2).toList();
      // Tambahkan detectedFruit ke daftar final
      finalOptions.add(_detectedFruit!);
      // Acak lagi urutan opsi
      finalOptions.shuffle();
      return finalOptions;
    } else {
      // Fallback jika tidak ada detectedFruit
      options.shuffle();
      return options.take(3).toList();
    }
  }

  @override
  void dispose() {
    if (_modelLoaded) _classifier.close();
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove default app bar and use custom app bar within the body
      // to merge with status bar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Custom App Bar that extends to status bar
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).viewPadding.top, // Add padding for status bar
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                color: AppColors.primaryPurple,
                child: Row(
                  children: [
                    // Logo gambar - Ganti dengan logo custom
                    Image.asset(
                      'assets/fruit_icon.png', // Ganti dengan path logo Anda
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Buah-Seru Siscer Project',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Main content area with expanded height
              Expanded(
                child: _showCameraPreview ? _buildCameraPreview() : _buildMainContent(),
              ),
            ],
          ),

          // Bottom camera and gallery buttons
          if (!_showCameraPreview)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomButtons(),
            ),
        ],
      ),
    );
  }


  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Dapatkan ukuran preview kamera asli
    final previewSize = _cameraController!.value.previewSize!;
    final double previewWidth = previewSize.width;
    final double previewHeight = previewSize.height;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Tampilkan preview dengan orientasi portrait (height > width)
        Center(
          child: AspectRatio(
            // note: flip width/height untuk portrait
            aspectRatio: previewHeight / previewWidth,
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Overlay hitam semi-transparan dengan lubang di tengah
        Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                color: Colors.transparent,
              ),
            ),
          ),
        ),

        // Tombol di bawah
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'cancel',
                onPressed: _closeCameraPreview,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                child: const Icon(Icons.close),
              ),
              const SizedBox(width: 40),
              FloatingActionButton.large(
                heroTag: 'capture',
                onPressed: _takePicture,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera, size: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildMainContent() {
    if (!_modelLoaded) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Memuat Model...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_image == null) {
      // Show welcome instructions
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo-buah-seru.png',
                height: 300,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image,
                  size: 150,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selamat Datang di Buah-Seru!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ambil atau pilih foto buah dan jawab kuis untuk belajar tentang manfaat buah-buahan.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Tekan tombol kamera atau galeri di bawah untuk memulai!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_busy) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.file(
              _image!,
              height: 220,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Menganalisis Gambar...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    // Show the image with quiz or results
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _image!,
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Quiz section
            if (_showQuiz) ...[
              if (!_quizAnswered) ...[
                const Text(
                  'Buah apa ini?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                ..._getQuizOptions().map((fruit) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () => _answerQuiz(fruit),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      fruit.substring(0, 1).toUpperCase() + fruit.substring(1),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                )),
              ] else ...[
                // Quiz results
                FadeTransition(
                  opacity: _animation,
                  child: Column(
                    children: [
                      Text(
                        _selectedFruit == _detectedFruit
                            ? 'Benar! Ini adalah ${_detectedFruit!}'
                            : 'Jawaban yang benar adalah ${_detectedFruit!}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _selectedFruit == _detectedFruit
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.lightGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Manfaat:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _fruitBenefits[_detectedFruit] ??
                                  'Buah ini memiliki banyak manfaat untuk kesehatan tubuh.',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _resetQuiz,
                        icon: const Icon(Icons.replay),
                        label: const Text('Coba Lagi', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Show model results as debug info at bottom (optional)
            if (_results != null && !_showQuiz) ...[
              const Divider(height: 30),
              const Text(
                'Hasil Deteksi:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...(_results!.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.key),
                    const SizedBox(width: 10),
                    Text('${(e.value * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (!_modelLoaded) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(bottom: 40, top: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: _busy ? null : _pickFromGallery,
            backgroundColor: Color(-6586899),
            child: const Icon(Icons.photo_library, size: 28),
          ),

          // Camera button
          FloatingActionButton.large(
            heroTag: 'camera',
            onPressed: _busy ? null : _initializeCamera,
            backgroundColor: Color(-5925923),
            foregroundColor: Colors.black87,
            child: const Icon(Icons.camera_alt, size: 36),
          ),

          // Placeholder to balance layout
          const FloatingActionButton(
            heroTag: 'placeholder',
            onPressed: null,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(Icons.info_outline, color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

/// Kelas untuk load model, preprocessing & inference
class Classifier {
  final Interpreter _interpreter;
  final List<String> _labels;
  final int inputHeight;
  final int inputWidth;
  final double threshold;

  Classifier._(
      this._interpreter,
      this._labels,
      this.inputHeight,
      this.inputWidth,
      this.threshold,
      );

  static Future<Classifier> create({
    int inputHeight = 258,
    int inputWidth = 320,
    double threshold = 0.5,
    int threads = 4,
  }) async {
    // Try to load the model using the correct path
    final interpreter = await Interpreter.fromAsset(
      'assets/siscer_cnn_deteksi_buah.tflite',  // Updated path
      options: InterpreterOptions()..threads = threads,
    );

    // Load labels
    final rawLabels = await rootBundle.loadString('assets/class.txt');
    final labels = rawLabels
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.trim())
        .toList();

    return Classifier._(
      interpreter,
      labels,
      inputHeight,
      inputWidth,
      threshold,
    );
  }

  Float32List _preProcess(img.Image src) {
    final resized = img.copyResize(
      src,
      width: inputWidth,
      height: inputHeight,
      interpolation: img.Interpolation.linear,
    );
    final buffer = Float32List(inputHeight * inputWidth * 3);
    var idx = 0;
    for (var y = 0; y < inputHeight; y++) {
      for (var x = 0; x < inputWidth; x++) {
        final pixel = resized.getPixel(x, y);
        buffer[idx++] = pixel.r / 255.0;
        buffer[idx++] = pixel.g / 255.0;
        buffer[idx++] = pixel.b / 255.0;
      }
    }
    return buffer;
  }

  Future<Map<String, double>> predict(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final src = img.decodeImage(bytes);
    if (src == null) throw Exception('Gagal decode image');
    final inputData = _preProcess(src);
    final outputData = Float32List(_labels.length);
    _interpreter.run(inputData.buffer, outputData.buffer);

    final results = <String, double>{};
    for (var i = 0; i < _labels.length; i++) {
      final score = outputData[i];
      if (score > threshold) results[_labels[i]] = score;
    }
    if (results.isEmpty && outputData.isNotEmpty) {
      final maxScore = outputData.reduce((a, b) => a > b ? a : b);
      final maxIndex = outputData.indexOf(maxScore);
      results[_labels[maxIndex]] = maxScore;
    }
    return results;
  }

  void close() => _interpreter.close();
}