import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const PixelPlayerApp());
}

class PixelPlayerApp extends StatelessWidget {
  const PixelPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFFD4E677);

    return MaterialApp(
      title: 'Pixel Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141416),
        colorSchemeSeed: seedColor,
      ),
      home: const PlayerScreen(),
    );
  }
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final AudioPlayer _player;
  String _trackTitle = "SoundHelix Demo";
  String _trackArtist = "Material 3 Expressive";

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setUrl("https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3");

    _player.positionStream.listen((pos) {
      setState(() => _currentPosition = pos);
    });

    _player.durationStream.listen((dur) {
      setState(() => _totalDuration = dur ?? Duration.zero);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      await _player.setFilePath(file.path!);
      setState(() {
        _trackTitle = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
        _trackArtist = "Локальный файл";
      });
      _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFFDCE775);

    final double progress = _totalDuration.inMilliseconds > 0
        ? (_currentPosition.inMilliseconds / _totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Pixel Play",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open_rounded),
            tooltip: "Открыть файл",
            onPressed: _pickAudioFile,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(),
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 96,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trackTitle,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _trackArtist,
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null && _totalDuration.inMilliseconds > 0) {
                    final localX = details.localPosition.dx.clamp(0.0, box.size.width - 56);
                    final percent = (localX / (box.size.width - 56)).clamp(0.0, 1.0);
                    _player.seek(Duration(milliseconds: (percent * _totalDuration.inMilliseconds).toInt()));
                  }
                },
                child: SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: SquigglyWavePainter(
                      progress: progress,
                      activeColor: accentColor,
                      inactiveColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_currentPosition), style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  Text(_formatDuration(_totalDuration), style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () => _player.seek(Duration.zero),
                  ),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 38,
                          color: Colors.black,
                          icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          onPressed: () {
                            isPlaying ? _player.pause() : _player.play();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () {},
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}

class SquigglyWavePainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  SquigglyWavePainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final playedWidth = size.width * progress;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final wavePath = Path()..moveTo(0, midY);
    const wavelength = 18.0;
    const amplitude = 3.5;

    for (double x = 0; x <= playedWidth; x += 1) {
      final y = midY + math.sin(x / wavelength * 2 * math.pi) * amplitude;
      wavePath.lineTo(x, y);
    }
    canvas.drawPath(wavePath, activePaint);

    canvas.drawCircle(
      Offset(playedWidth, midY + math.sin(playedWidth / wavelength * 2 * math.pi) * amplitude),
      5.0,
      Paint()..color = activeColor,
    );

    if (playedWidth < size.width) {
      canvas.drawLine(
        Offset(playedWidth + 6, midY),
        Offset(size.width, midY),
        inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SquigglyWavePainter oldDelegate) => oldDelegate.progress != progress;
}
