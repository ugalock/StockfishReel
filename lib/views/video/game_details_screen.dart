import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'move_annotations_screen.dart';

class GameDetailsScreen extends StatefulWidget {
  final File videoFile;
  final String? pgnContent;
  final List<String>? moves;
  final String? openingName;

  const GameDetailsScreen({
    super.key,
    required this.videoFile,
    this.pgnContent,
    this.moves,
    this.openingName,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late VideoPlayerController _controller;
  double _middleGameTimestamp = 0;
  double _endGameTimestamp = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          // Set default timestamps at 1/3 and 2/3 of video duration
          _middleGameTimestamp = _controller.value.duration.inSeconds / 3;
          _endGameTimestamp = (_controller.value.duration.inSeconds / 3) * 2;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
      _isPlaying = _controller.value.isPlaying;
    });
  }

  void _onMiddleGameSliderChanged(double value) {
    setState(() {
      _middleGameTimestamp = value;
      if (_endGameTimestamp < value) {
        _endGameTimestamp = value;
      }
    });
    _controller.seekTo(Duration(seconds: value.toInt()));
  }

  void _onEndGameSliderChanged(double value) {
    setState(() {
      _endGameTimestamp = value;
      if (_middleGameTimestamp > value) {
        _middleGameTimestamp = value;
      }
    });
    _controller.seekTo(Duration(seconds: value.toInt()));
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Game Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Video Preview
            if (_controller.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Game Phases Timeline
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.openingName != null) ...[
                      const Text(
                        'Opening',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.openingName!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (_controller.value.isInitialized) ...[
                      // Middle Game Timestamp
                      Row(
                        children: [
                          const Text(
                            'Middle Game Start',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(_middleGameTimestamp),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _middleGameTimestamp,
                        min: 0,
                        max: _controller.value.duration.inSeconds.toDouble(),
                        onChanged: _onMiddleGameSliderChanged,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                      ),
                      const SizedBox(height: 24),

                      // End Game Timestamp
                      Row(
                        children: [
                          const Text(
                            'End Game Start',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDuration(_endGameTimestamp),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _endGameTimestamp,
                        min: 0,
                        max: _controller.value.duration.inSeconds.toDouble(),
                        onChanged: _onEndGameSliderChanged,
                        activeColor: Colors.blue,
                        inactiveColor: Colors.grey,
                      ),
                    ],

                    if (widget.moves != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Moves',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (int i = 0; i < widget.moves!.length; i += 2) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${(i ~/ 2) + 1}.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              widget.moves![i],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (i + 1 < widget.moves!.length)
                              Text(
                                widget.moves![i + 1],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => MoveAnnotationsScreen(
                        videoFile: widget.videoFile,
                        pgnContent: widget.pgnContent,
                        moves: widget.moves,
                        openingName: widget.openingName,
                        middleGameTimestamp: _middleGameTimestamp,
                        endGameTimestamp: _endGameTimestamp,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 