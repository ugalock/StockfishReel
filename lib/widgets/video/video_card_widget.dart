// video_card_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:logging/logging.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../../models/video.dart';
import '../../services/database_service.dart';
import 'video_player_widget.dart';
import 'video_actions_widget.dart';
import 'video_info_widget.dart';

class VideoCardWidget extends StatefulWidget {
  final Video video;
  final bool isActive;

  const VideoCardWidget({
    super.key,
    required this.video,
    required this.isActive,
  });

  @override
  State<VideoCardWidget> createState() => _VideoCardWidgetState();
}

class _VideoCardWidgetState extends State<VideoCardWidget> {
  static final _log = Logger('VideoCardWidget');
  late VideoPlayerController _controller;
  final DatabaseService _databaseService = DatabaseService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only call play/pause if the controller is initialized.
    if (!_isInitialized) {
      _log.info('Video controller not initialized');
      return;
    }
    if (widget.isActive) {
      _controller.play();
      _incrementView();
    } else {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    // Get a reference to the file
    final firebase_storage.Reference videoRef = firebase_storage
        .FirebaseStorage.instance
        .ref()
        .child(widget.video.videoUrl);

    // Retrieve the download URL
    final String downloadUrl = await videoRef.getDownloadURL();

    // Now, use the HTTP(s) URL with your video player
    _controller = VideoPlayerController.networkUrl(Uri.parse(downloadUrl));
    try {
      await _controller.initialize();
      if (widget.isActive) {
        _controller.setLooping(true);
        await _controller.play();
        _incrementView();
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _log.severe('Error initializing video: ${widget.video.id}', e);
    }
  }

  Future<void> _incrementView() async {
    try {
      await _databaseService.incrementVideoView(widget.video.id);
    } catch (e) {
      _log.warning('Error incrementing view for video: ${widget.video.id}', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Player (with progress bar and play button overlay)
        if (_isInitialized)
          VideoPlayerWidget(
            controller: _controller,
            isActive: widget.isActive,
          )
        else
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Gradient overlay for better text visibility
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black45,
                  ],
                  stops: [0.15, 0.3, 0.8, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Video Info (description, username, etc.)
        Positioned(
          left: 16,
          right: 96, // Leave space for action buttons
          bottom: 16,
          child: VideoInfoWidget(video: widget.video),
        ),

        // Action Buttons (like, comment, share)
        Positioned(
          right: 8,
          bottom: 16,
          child: VideoActionsWidget(
            video: widget.video,
            controller: _controller,
          ),
        ),
      ],
    );
  }
}
