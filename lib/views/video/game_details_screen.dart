import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'move_annotations_screen.dart';
import '../../models/video_types.dart';

class GameDetailsScreen extends StatefulWidget {
  final VideoData videoData;
  final String? pgnContent;
  final List<String>? moves;
  final List<int>? timestamps;
  final String? openingName;

  const GameDetailsScreen({
    super.key,
    required this.videoData,
    this.pgnContent,
    this.moves,
    this.timestamps,
    this.openingName,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late VideoPlayerController _controller;
  double? _middleGameTimestamp;
  double? _endGameTimestamp;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = widget.videoData.isRemote
        ? VideoPlayerController.networkUrl(Uri.parse(widget.videoData.remoteUrl!))
        : VideoPlayerController.file(widget.videoData.file!);
    
    try {
      await _controller.initialize();
      _controller.addListener(_onVideoPositionChanged);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoPositionChanged);
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
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

  void _onVideoPositionChanged() {
    if (mounted) {
      setState(() {
        // Update UI when video position changes
      });
    }
  }

  void _setMiddleGameTimestamp() {
    setState(() {
      _middleGameTimestamp = _controller.value.position.inSeconds.toDouble();
    });
  }

  void _setEndGameTimestamp() {
    setState(() {
      _endGameTimestamp = _controller.value.position.inSeconds.toDouble();
    });
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _proceedToMoveAnnotations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MoveAnnotationsScreen(
          videoData: widget.videoData,
          pgnContent: widget.pgnContent,
          moves: widget.moves,
          timestamps: widget.timestamps,
          openingName: widget.openingName,
          middleGameTimestamp: _middleGameTimestamp,
          endGameTimestamp: _endGameTimestamp,
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
    final videoPreviewHeight =
        (MediaQuery.of(context).size.height * 0.6).roundToDouble(); // ~540 on your device.

    // Calculate sizes relative to videoPreviewHeight (540).
    final playPauseSize =
        videoPreviewHeight * (60 / 540); // 60 when videoPreviewHeight = 540
    final progressContainerHeight = videoPreviewHeight * (32 / 540); // 32
    final progressContainerPadding =
        videoPreviewHeight * (8 / 540); // 8 (left/right padding)
    final progressBarAreaHeight = videoPreviewHeight *
        (16 / 540); // 16 (height for the SizedBox wrapping progress bar)
    final progressIndicatorPadding = videoPreviewHeight *
        (6 / 540); // 6 (vertical padding inside progress bar area)
    final customCircleDiameter = videoPreviewHeight * (12 / 540); // 12
    final circleBorderWidth = videoPreviewHeight * (1.5 / 540); // 1.5

    // For text sizes, if your total screen height is around 900 (since 0.6 of 900 is 540):
    final headerFontSize = screenHeight * (24 / 900); // 24
    final gamePhaseFontSize = screenHeight * (16 / 900); // 16
    final timestampFontSize = screenHeight * (11 / 900); // 11

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Game Details',
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
                Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              // Game Phases Timeline
              Padding(
                padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.03,
                    screenHeight * 0.01,
                    screenWidth * 0.03,
                    screenHeight * 0.015),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_controller.value.isInitialized) ...[
                      // Game Phase Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Middle Game Start:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: gamePhaseFontSize,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                      _middleGameTimestamp != null 
                                          ? _formatDuration(_middleGameTimestamp!)
                                          : 'N/A',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: gamePhaseFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                ElevatedButton(
                                  onPressed: _setMiddleGameTimestamp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: Size(
                                        double.infinity,
                                        screenHeight *
                                            (40 /
                                                900)), // 40 when screenHeight is 900
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.02),
                                    ),
                                  ),
                                  child: Text(
                                    'Set Current Time',
                                    style:
                                        TextStyle(fontSize: gamePhaseFontSize, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'End Game Start:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: gamePhaseFontSize,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                      _endGameTimestamp != null 
                                          ? _formatDuration(_endGameTimestamp!)
                                          : 'N/A',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: gamePhaseFontSize,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                ElevatedButton(
                                  onPressed: _setEndGameTimestamp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: Size(double.infinity,
                                        screenHeight * (40 / 900)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          screenWidth * 0.02),
                                    ),
                                  ),
                                  child: Text(
                                    'Set Current Time',
                                    style:
                                        TextStyle(fontSize: gamePhaseFontSize, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (widget.moves != null) ...[
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        widget.openingName != null &&
                                widget.openingName != "Unknown Opening"
                            ? widget.openingName!
                            : 'Moves',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: headerFontSize * 0.75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      for (int i = 0; i < widget.moves!.length; i += 2) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.1,
                              child: Text(
                                '${(i ~/ 2) + 1}.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: gamePhaseFontSize,
                                ),
                              ),
                            ),
                            Text(
                              widget.moves![i],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: gamePhaseFontSize,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            if (i + 1 < widget.moves!.length)
                              Text(
                                widget.moves![i + 1],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: gamePhaseFontSize,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),
                      ],
                    ],
                  ],
                ),
              ),
              // Next Button
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: ElevatedButton(
                  onPressed: _proceedToMoveAnnotations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(
                        double.infinity,
                        screenHeight *
                            (50 / 900)), // 50 when screenHeight is 900
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
}
