import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'post_details_screen.dart';
import '../../models/video_types.dart';

class MoveAnnotationsScreen extends StatefulWidget {
  final VideoData videoData;
  final String? pgnContent;
  final List<String>? moves;
  final List<int>? timestamps;
  final String? openingName;
  final double? middleGameTimestamp;
  final double? endGameTimestamp;

  const MoveAnnotationsScreen({
    super.key,
    required this.videoData,
    this.pgnContent,
    this.moves,
    this.timestamps,
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

  // Add map for classification icons
  final Map<MoveClassification, String> _classificationIcons = {
    MoveClassification.brilliant: 'assets/images/move_icons/brilliant_32x.png',
    MoveClassification.good: 'assets/images/move_icons/good_32x.png',
    MoveClassification.book: 'assets/images/move_icons/book_32x.png',
    MoveClassification.inaccuracy: 'assets/images/move_icons/inaccuracy_32x.png',
    MoveClassification.mistake: 'assets/images/move_icons/mistake_32x.png',
    MoveClassification.blunder: 'assets/images/move_icons/blunder_32x.png',
  };

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnnotations();
    _controller.addListener(_onVideoPositionChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoPositionChanged);
    _controller.pause();
    _controller.dispose();
    _annotationController.dispose();
    super.dispose();
  }

  void _onVideoPositionChanged() {
    if (mounted) {
      setState(() {
        // Update UI when video position changes
      });
    }
  }

  Future<void> _initializeVideo() async {
    _controller = widget.videoData.isRemote
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoData.remoteUrl!))
        : VideoPlayerController.file(widget.videoData.file!);
    
    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  void _initializeAnnotations() {
    if (widget.moves == null) return;

    _annotations = [];
    for (int i = 0; i < widget.moves!.length; i++) {
      final moveNumber = (i ~/ 2) + 1;
      final moveColor = i % 2 == 0 ? 'white' : 'black';
      
      double timestamp = 0;
      if (widget.timestamps != null && widget.timestamps!.length > i) {
        timestamp = widget.timestamps![i].toDouble();
      } else {
        // Calculate default timestamp based on move number and total duration
        if (_controller.value.isInitialized) {
          final totalDuration = _controller.value.duration.inMilliseconds.toDouble();
          final movePosition = i / widget.moves!.length;
          timestamp = movePosition * totalDuration;
        }
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
    _controller.seekTo(Duration(milliseconds: move.timestamp));
  }

  void _updateMoveClassification(MoveClassification? classification) {
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

  void _clearSelectedMove() {
    setState(() {
      _selectedMove = null;
      _annotationController.clear();
    });
  }

  String _getBlackMovePrefix(int moveNumber) {
    // Calculate number of digits in the move number
    int digits = moveNumber.toString().length;
    return ' ' * (digits - 1) + '...';
  }

  void _proceedToPostDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailsScreen(
          videoData: widget.videoData,
          pgnContent: widget.pgnContent,
          openingName: widget.openingName,
          middleGameTimestamp: widget.middleGameTimestamp,
          endGameTimestamp: widget.endGameTimestamp,
          moveAnnotations: _annotations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions.
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Our video container is set to 60% of screen height.
    final videoPreviewHeight = (screenHeight * 0.6).roundToDouble();

    // Calculate sizes relative to videoPreviewHeight (540 when screenHeight = 900).
    final playPauseSize = videoPreviewHeight * (60 / 540);
    final progressContainerHeight = videoPreviewHeight * (32 / 540);
    final progressContainerPadding = videoPreviewHeight * (8 / 540);
    final progressBarAreaHeight = videoPreviewHeight * (16 / 540);
    final progressIndicatorPadding = videoPreviewHeight * (6 / 540);
    final customCircleDiameter = videoPreviewHeight * (12 / 540);
    final circleBorderWidth = videoPreviewHeight * (1.5 / 540);

    // For text sizes, if your total screen height is around 900:
    final headerFontSize = screenHeight * (24 / 900);
    final gamePhaseFontSize = screenHeight * (16 / 900);
    final timestampFontSize = screenHeight * (11 / 900);
    const iconScale = 20.0;
    final iconSize = screenHeight * (iconScale / 900);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: screenWidth * 0.06,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                      ],
                    ),
                    Text(
                      'Move Annotations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: headerFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Video Preview
              if (_controller.value.isInitialized) ...[
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: videoPreviewHeight,
                    ),
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Video Player
                          VideoPlayer(_controller),
                          // Play/Pause Button
                          GestureDetector(
                            onTap: _togglePlayPause,
                            child: !_isPlaying
                                ? Container(
                                    width: playPauseSize,
                                    height: playPauseSize,
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      borderRadius: BorderRadius.circular(
                                          playPauseSize / 2),
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: playPauseSize * 0.67,
                                    ),
                                  )
                                : null,
                          ),
                          // Custom Progress Bar
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: progressContainerHeight,
                              padding: EdgeInsets.symmetric(
                                  horizontal: progressContainerPadding),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black54, Colors.transparent],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Progress bar area (with our custom circle indicator).
                                  SizedBox(
                                    height: progressBarAreaHeight,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final progressBarWidth =
                                            constraints.maxWidth;
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTapDown: (details) {
                                            double progress =
                                                details.localPosition.dx /
                                                    progressBarWidth;
                                            progress = progress.clamp(0.0, 1.0);
                                            final newPosition =
                                                _controller.value.duration *
                                                    progress;
                                            _controller.seekTo(newPosition);
                                          },
                                          onHorizontalDragUpdate: (details) {
                                            double progress =
                                                details.localPosition.dx /
                                                    progressBarWidth;
                                            progress = progress.clamp(0.0, 1.0);
                                            final newPosition =
                                                _controller.value.duration *
                                                    progress;
                                            _controller.seekTo(newPosition);
                                          },
                                          child: Stack(
                                            children: [
                                              // Built-in progress indicator with vertical padding.
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical:
                                                        progressIndicatorPadding),
                                                child: VideoProgressIndicator(
                                                  _controller,
                                                  allowScrubbing: true,
                                                  padding: EdgeInsets.zero,
                                                  colors: VideoProgressColors(
                                                    playedColor: Colors.blue,
                                                    bufferedColor:
                                                        Colors.blue.withValues(
                                                      red: 33,
                                                      green: 150,
                                                      blue: 243,
                                                      alpha: 51,
                                                    ),
                                                    backgroundColor:
                                                        Colors.white24,
                                                  ),
                                                ),
                                              ),
                                              // Custom circle indicator
                                              ValueListenableBuilder(
                                                valueListenable: _controller,
                                                builder:
                                                    (context, value, child) {
                                                  final duration = value
                                                      .duration.inMilliseconds;
                                                  final position = value
                                                      .position.inMilliseconds;
                                                  final progress = duration > 0
                                                      ? (position / duration)
                                                      : 0.0;
                                                  final left = progress *
                                                          progressBarWidth -
                                                      (customCircleDiameter /
                                                          2);
                                                  final top =
                                                      (progressBarAreaHeight -
                                                              customCircleDiameter) /
                                                          2;
                                                  return Positioned(
                                                    left: left,
                                                    top: top,
                                                    child: Container(
                                                      width:
                                                          customCircleDiameter,
                                                      height:
                                                          customCircleDiameter,
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width:
                                                              circleBorderWidth,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  // Timestamps Row
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_controller
                                            .value.position.inSeconds
                                            .toDouble()),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: timestampFontSize,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_controller
                                            .value.duration.inSeconds
                                            .toDouble()),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: timestampFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),

              // Move List and Annotations
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Move List
                    Expanded(
                      flex: 2,
                      child: ListTileTheme(
                        tileColor: Colors.transparent,
                        selectedTileColor: Colors.blue.withValues(
                            red: 33, green: 150, blue: 243, alpha: 51),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: _annotations.length,
                          itemBuilder: (context, index) {
                            final move = _annotations[index];
                            final isSelected = move == _selectedMove;
                            return Material(
                              type: MaterialType.transparency,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    screenWidth * 0.02),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.blue.withOpacity(0.2), // try withOpacity instead of withValues
                                // Remove selectedColor (or set it only for text/icon colors)
                                onTap: () => _selectMove(move),
                                title: Row(
                                  children: [
                                    SizedBox(
                                      width: 50, // fixed width for move numbers
                                      child: Text(
                                        move.moveColor == 'white'
                                            ? '${move.moveNumber}.'
                                            : _getBlackMovePrefix(
                                                move.moveNumber),
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: gamePhaseFontSize,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        move.notation,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: gamePhaseFontSize,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (move.classification != null)
                                      Image.asset(
                                        _classificationIcons[
                                            move.classification]!,
                                        width: iconSize,
                                        height: iconSize,
                                      ),
                                  ],
                                ),
                                subtitle: move.annotation != null
                                    ? Text(
                                        move.annotation!,
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: gamePhaseFontSize * 0.75,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Annotation Panel
                    if (_selectedMove != null)
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.04),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedMove!.moveColor == 'white'
                                        ? '${_selectedMove!.moveNumber}. ${_selectedMove!.notation}'
                                        : '${_selectedMove!.moveNumber}. ...${_selectedMove!.notation}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: headerFontSize * 0.75,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    onPressed: _clearSelectedMove,
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              
                              // Classification Icons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  // Clear classification option
                                  GestureDetector(
                                    onTap: () => _updateMoveClassification(null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _selectedMove!.classification == null
                                            ? const Color.fromARGB(
                                                166, 214, 211, 211)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _selectedMove!.classification == null
                                              ? Colors.blue
                                              : Colors.white24,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.not_interested,
                                        color: Colors.white,
                                        size: iconSize,
                                      ),
                                    ),
                                  ),
                                  ...MoveClassification.values
                                      .map(
                                        (c) => GestureDetector(
                                          onTap: () => _updateMoveClassification(c),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _selectedMove!.classification == c
                                                  ? const Color.fromARGB(166, 214, 211, 211)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: _selectedMove!.classification == c
                                                    ? Colors.blue
                                                    : Colors.white24,
                                              ),
                                            ),
                                            child: Image.asset(
                                              _classificationIcons[c]!,
                                              width: iconSize,
                                              height: iconSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.03),

                              // Timestamp
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Timestamp:',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: gamePhaseFontSize,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        _selectedMove!.timestamp > 0
                                            ? Duration(
                                                milliseconds: _selectedMove!.timestamp,
                                              ).toString().split('.').first
                                            : 'N/A',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: gamePhaseFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenHeight * 0.01),
                                  SizedBox(
                                    width: screenWidth * 0.25,  // Make button smaller
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _updateMoveTimestamp(
                                          _controller.value.position.inMilliseconds,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      child: Text(
                                        'Set Time',
                                        style: TextStyle(
                                          fontSize: gamePhaseFontSize * 0.8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),

                              // Annotation Text Field
                              TextField(
                                controller: _annotationController,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: gamePhaseFontSize,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Annotation',
                                  labelStyle: TextStyle(
                                    color: Colors.white70,
                                    fontSize: gamePhaseFontSize,
                                  ),
                                  border: const OutlineInputBorder(),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white24),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
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
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: ElevatedButton(
                  onPressed: _proceedToPostDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(
                        double.infinity,
                        screenHeight * (50 / 900)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: headerFontSize * 0.75,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 