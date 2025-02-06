import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'post_details_screen.dart';
import '../../models/video_types.dart';

class MoveAnnotationsScreen extends StatefulWidget {
  final File videoFile;
  final String? pgnContent;
  final List<String>? moves;
  final String? openingName;
  final double middleGameTimestamp;
  final double endGameTimestamp;

  const MoveAnnotationsScreen({
    super.key,
    required this.videoFile,
    this.pgnContent,
    this.moves,
    this.openingName,
    required this.middleGameTimestamp,
    required this.endGameTimestamp,
  });

  @override
  State<MoveAnnotationsScreen> createState() => _MoveAnnotationsScreenState();
}

class _MoveAnnotationsScreenState extends State<MoveAnnotationsScreen> {
  late VideoPlayerController _controller;
  List<MoveAnnotation> _annotations = [];
  bool _isPlaying = false;
  final TextEditingController _annotationController = TextEditingController();
  MoveAnnotation? _selectedMove;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnnotations();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  void _initializeAnnotations() {
    if (widget.moves == null) return;

    _annotations = [];
    for (int i = 0; i < widget.moves!.length; i++) {
      final moveNumber = (i ~/ 2) + 1;
      final moveColor = i % 2 == 0 ? 'white' : 'black';
      
      // Calculate default timestamp based on move number and game phases
      double timestamp;
      if (moveNumber < widget.moves!.length ~/ 3) {
        timestamp = (moveNumber / (widget.moves!.length ~/ 3)) * widget.middleGameTimestamp;
      } else if (moveNumber < (widget.moves!.length * 2) ~/ 3) {
        timestamp = widget.middleGameTimestamp +
            ((moveNumber - (widget.moves!.length ~/ 3)) /
                (widget.moves!.length ~/ 3)) *
                (widget.endGameTimestamp - widget.middleGameTimestamp);
      } else {
        timestamp = widget.endGameTimestamp +
            ((moveNumber - ((widget.moves!.length * 2) ~/ 3)) /
                (widget.moves!.length ~/ 3)) *
                (_controller.value.duration.inSeconds - widget.endGameTimestamp);
      }

      _annotations.add(
        MoveAnnotation(
          moveNumber: moveNumber,
          moveColor: moveColor,
          notation: widget.moves![i],
          timestamp: timestamp.toInt(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _annotationController.dispose();
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

  void _selectMove(MoveAnnotation move) {
    setState(() {
      _selectedMove = move;
      _annotationController.text = move.annotation ?? '';
    });
    _controller.seekTo(Duration(seconds: move.timestamp));
  }

  void _updateMoveClassification(MoveClassification classification) {
    if (_selectedMove == null) return;
    setState(() {
      _selectedMove!.classification = classification;
    });
  }

  void _updateMoveTimestamp(int timestamp) {
    if (_selectedMove == null) return;
    setState(() {
      _selectedMove!.timestamp = timestamp;
    });
  }

  void _updateMoveAnnotation(String annotation) {
    if (_selectedMove == null) return;
    setState(() {
      _selectedMove!.annotation = annotation;
    });
  }

  Color _getClassificationColor(MoveClassification classification) {
    switch (classification) {
      case MoveClassification.brilliant:
        return Colors.blue;
      case MoveClassification.good:
        return Colors.green;
      case MoveClassification.inaccuracy:
        return Colors.yellow;
      case MoveClassification.mistake:
        return Colors.orange;
      case MoveClassification.blunder:
        return Colors.red;
      case MoveClassification.normal:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
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
                      'Move Annotations',
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

            // Move List and Annotations
            Expanded(
              child: Row(
                children: [
                  // Move List
                  Expanded(
                    flex: 2,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _annotations.length,
                      itemBuilder: (context, index) {
                        final move = _annotations[index];
                        final isSelected = move == _selectedMove;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withOpacity(0.2),
                          onTap: () => _selectMove(move),
                          title: Row(
                            children: [
                              if (move.moveColor == 'white')
                                Text(
                                  '${move.moveNumber}.',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                move.notation,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getClassificationColor(
                                    move.classification,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: move.annotation != null
                              ? Text(
                                  move.annotation!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),

                  // Annotation Panel
                  if (_selectedMove != null)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          border: Border(
                            left: BorderSide(
                              color: Colors.grey[800]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Move ${_selectedMove!.moveNumber} (${_selectedMove!.moveColor})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Classification Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: MoveClassification.values
                                  .map(
                                    (c) => ChoiceChip(
                                      label: Text(
                                        c.name,
                                        style: TextStyle(
                                          color: _selectedMove!.classification == c
                                              ? Colors.white
                                              : Colors.white70,
                                        ),
                                      ),
                                      selected: _selectedMove!.classification == c,
                                      selectedColor:
                                          _getClassificationColor(c),
                                      onSelected: (selected) {
                                        if (selected) {
                                          _updateMoveClassification(c);
                                        }
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 24),

                            // Timestamp
                            Row(
                              children: [
                                const Text(
                                  'Timestamp:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  Duration(
                                    seconds: _selectedMove!.timestamp,
                                  ).toString().split('.').first,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _selectedMove!.timestamp.toDouble(),
                              min: 0,
                              max: _controller.value.duration.inSeconds.toDouble(),
                              onChanged: (value) =>
                                  _updateMoveTimestamp(value.toInt()),
                            ),
                            const SizedBox(height: 24),

                            // Annotation Text Field
                            TextField(
                              controller: _annotationController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Annotation',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              onChanged: _updateMoveAnnotation,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PostDetailsScreen(
                        videoFile: widget.videoFile,
                        pgnContent: widget.pgnContent,
                        openingName: widget.openingName,
                        middleGameTimestamp: widget.middleGameTimestamp,
                        endGameTimestamp: widget.endGameTimestamp,
                        moveAnnotations: _annotations,
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