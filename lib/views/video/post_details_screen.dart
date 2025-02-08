import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../services/auth_service.dart';
import '../../models/video_types.dart';
import '../main_layout/main_layout_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final VideoData videoData;
  final String? pgnContent;
  final String? openingName;
  final double? middleGameTimestamp;
  final double? endGameTimestamp;
  final List<MoveAnnotation> moveAnnotations;

  const PostDetailsScreen({
    super.key,
    required this.videoData,
    this.pgnContent,
    this.openingName,
    required this.middleGameTimestamp,
    required this.endGameTimestamp,
    required this.moveAnnotations,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _hashtagsController = TextEditingController();
  bool _isPlaying = false;
  bool _isUploading = false;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    // Pre-fill hashtags with opening name if available.
    if (widget.openingName != null) {
      _hashtagsController.text = '#${widget.openingName!.replaceAll(' ', '')}';
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
  void dispose() {
    _controller.pause();
    _controller.dispose();
    _captionController.dispose();
    _hashtagsController.dispose();
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

  List<String> _parseHashtags(String input) {
    final hashtags = input
        .split(' ')
        .where((word) => word.startsWith('#'))
        .map((tag) => tag.toLowerCase())
        .toList();

    // Add default hashtags if not present.
    if (!hashtags.contains('#chess')) hashtags.add('#chess');
    if (!hashtags.contains('#stockfishreel')) hashtags.add('#stockfishreel');

    return hashtags;
  }

  Future<void> _uploadVideo() async {
    if (_captionController.text.isEmpty) {
      setState(() {
        _error = 'Please add a caption';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Generate a unique ID for the video
      final videoId = const Uuid().v4();
      String videoUrl = widget.videoData.storageUrl ?? '';

      // TODO: Add thumbnail, parse ELOs, site, datePlayed, result from pgnContent
      // Create the video document in Firestore with initial status.
      final videoDoc = {
        'id': videoId,
        'uploaderId': user.uid,
        'videoUrl': videoUrl,
        'thumbnailUrl': videoUrl,
        'description': _captionController.text,
        'hashtags': _parseHashtags(_hashtagsController.text),
        'chessOpenings':
            widget.openingName != null ? [widget.openingName!] : [],
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'viewCount': 0,
        'gameMetadata': {
          'playerELO': 0,
          'opponentELO': 0,
          'site': 'chess.com',
          'datePlayed': DateTime.now().toIso8601String(),
          'result': '',
          'pgn': widget.pgnContent ?? '',
        },
        'videoSegments': {
          'opening': 0,
          'middlegame': widget.middleGameTimestamp?.toInt() ?? 0,
          'endgame': widget.endGameTimestamp?.toInt() ?? 0,
        },
        'moves': widget.moveAnnotations.map((move) => move.toJson()).toList(),
        'status': widget.videoData.isRemote ? 'completed' : 'uploading',
      };

      final docRef =
          FirebaseFirestore.instance.collection('videos').doc(videoId);
      await docRef.set(videoDoc);

      if (widget.videoData.isRemote) {
        // If the video is already remote, we don't need to upload it again
        _proceedToMainLayout();
        return;
      }

      // Upload the video file to a temporary location.
      final tempVideoRef =
          FirebaseStorage.instance.ref().child('tmp').child('$videoId.mp4');
      await tempVideoRef.putFile(widget.videoData.file!);

      // Update the document status to "processing".
      await docRef.update({'status': 'processing'});

      // Capture the NavigatorState before the async gap.
      if (!mounted) return;
      final navigator = Navigator.of(context);

      // Now call showDialog. (We use the current context for building the dialog,
      // but we pass the already captured navigator to the dialog.)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => UploadStatusDialog(
          videoDocRef: docRef,
          navigator: navigator,
        ),
      );

      if (mounted) {
        _proceedToMainLayout();
      }
    } catch (e) {
      setState(() {
        _error = 'Error uploading video: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  void _proceedToMainLayout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainLayoutScreen(),
      ),
      (route) => false,
    );
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final videoPreviewHeight = (screenHeight * 0.6).roundToDouble();
    final playPauseSize = videoPreviewHeight * (60 / 540);
    final progressContainerHeight = videoPreviewHeight * (32 / 540);
    final progressContainerPadding = videoPreviewHeight * (8 / 540);
    final progressBarAreaHeight = videoPreviewHeight * (16 / 540);
    final progressIndicatorPadding = videoPreviewHeight * (6 / 540);
    final customCircleDiameter = videoPreviewHeight * (12 / 540);
    final circleBorderWidth = videoPreviewHeight * (1.5 / 540);
    final headerFontSize = screenHeight * (24 / 900);
    final gamePhaseFontSize = screenHeight * (16 / 900);
    final timestampFontSize = screenHeight * (11 / 900);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
                    'New Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Preview
                    if (_controller.value.isInitialized)
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
                                VideoPlayer(_controller),
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
                                // Custom progress bar
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
                                        colors: [
                                          Colors.black54,
                                          Colors.transparent
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          height: progressBarAreaHeight,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final progressBarWidth =
                                                  constraints.maxWidth;
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTapDown: (details) {
                                                  double progress =
                                                      details.localPosition.dx /
                                                          progressBarWidth;
                                                  progress =
                                                      progress.clamp(0.0, 1.0);
                                                  final newPosition =
                                                      _controller
                                                              .value.duration *
                                                          progress;
                                                  _controller
                                                      .seekTo(newPosition);
                                                },
                                                onHorizontalDragUpdate:
                                                    (details) {
                                                  double progress =
                                                      details.localPosition.dx /
                                                          progressBarWidth;
                                                  progress =
                                                      progress.clamp(0.0, 1.0);
                                                  final newPosition =
                                                      _controller
                                                              .value.duration *
                                                          progress;
                                                  _controller
                                                      .seekTo(newPosition);
                                                },
                                                child: Stack(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(
                                                          vertical:
                                                              progressIndicatorPadding),
                                                      child:
                                                          VideoProgressIndicator(
                                                        _controller,
                                                        allowScrubbing: true,
                                                        padding:
                                                            EdgeInsets.zero,
                                                        colors:
                                                            VideoProgressColors(
                                                          playedColor:
                                                              Colors.blue,
                                                          bufferedColor: Colors
                                                              .blue
                                                              .withValues(
                                                                  red: 33,
                                                                  green: 150,
                                                                  blue: 243,
                                                                  alpha: 51),
                                                          backgroundColor:
                                                              Colors.white24,
                                                        ),
                                                      ),
                                                    ),
                                                    ValueListenableBuilder(
                                                      valueListenable:
                                                          _controller,
                                                      builder: (context, value,
                                                          child) {
                                                        final duration = value
                                                            .duration
                                                            .inMilliseconds;
                                                        final position = value
                                                            .position
                                                            .inMilliseconds;
                                                        final progress =
                                                            duration > 0
                                                                ? (position /
                                                                    duration)
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
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.blue,
                                                              shape: BoxShape
                                                                  .circle,
                                                              border:
                                                                  Border.all(
                                                                color: Colors
                                                                    .white,
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
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    // Caption TextField
                    TextField(
                      controller: _captionController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: gamePhaseFontSize,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Caption',
                        labelStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: gamePhaseFontSize,
                        ),
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(
                          color: Colors.white30,
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
                      maxLines: 3,
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // Hashtags TextField
                    TextField(
                      controller: _hashtagsController,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: gamePhaseFontSize,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Hashtags',
                        labelStyle: TextStyle(
                          color: Colors.white70,
                          fontSize: gamePhaseFontSize,
                        ),
                        hintText: '#chess #opening #tactics',
                        hintStyle: TextStyle(
                          color: Colors.white30,
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
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'Separate hashtags with spaces',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: timestampFontSize,
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: gamePhaseFontSize,
                        ),
                      ),
                    ],
                    // Game Details Preview
                    if (widget.openingName != null) ...[
                      SizedBox(height: screenHeight * 0.03),
                      Text(
                        'Game Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: headerFontSize * 0.75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Opening: ${widget.openingName}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: gamePhaseFontSize,
                        ),
                      ),
                      if (widget.middleGameTimestamp != null) ...[
                        SizedBox(height: screenHeight * 0.01),
                        GestureDetector(
                          onTap: () {
                            _controller.seekTo(Duration(
                                seconds: widget.middleGameTimestamp!.toInt()));
                          },
                          child: Row(
                            children: [
                              Text(
                                'Middle Game: ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: gamePhaseFontSize,
                                ),
                              ),
                              Text(
                                _formatDuration(widget.middleGameTimestamp!),
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: gamePhaseFontSize,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (widget.endGameTimestamp != null) ...[
                        SizedBox(height: screenHeight * 0.01),
                        GestureDetector(
                          onTap: () {
                            _controller.seekTo(Duration(
                                seconds: widget.endGameTimestamp!.toInt()));
                          },
                          child: Row(
                            children: [
                              Text(
                                'End Game: ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: gamePhaseFontSize,
                                ),
                              ),
                              Text(
                                _formatDuration(widget.endGameTimestamp!),
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: gamePhaseFontSize,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Moves: ${widget.moveAnnotations.length}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: gamePhaseFontSize,
                        ),
                      ),
                    ],
                    // Post Button
                    SizedBox(height: screenHeight * 0.05),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: Size(double.infinity, screenHeight * 0.06),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      child: _isUploading
                          ? SizedBox(
                              height: screenHeight * 0.03,
                              width: screenHeight * 0.03,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Post',
                              style: TextStyle(
                                fontSize: gamePhaseFontSize * 1.125,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A modal widget that shows the upload/transcoding status in real time.
/// Instead of using the BuildContext after an async gap, we use a pre-captured NavigatorState.
class UploadStatusDialog extends StatefulWidget {
  final DocumentReference videoDocRef;
  final NavigatorState navigator;
  const UploadStatusDialog({
    super.key,
    required this.videoDocRef,
    required this.navigator,
  });

  @override
  State<UploadStatusDialog> createState() => _UploadStatusDialogState();
}

class _UploadStatusDialogState extends State<UploadStatusDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Processing Video'),
      content: StreamBuilder<DocumentSnapshot>(
        stream: widget.videoDocRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('An error occurred.');
          }
          if (!snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Uploading...',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'uploading';

          if (status == 'uploading') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Uploading video...',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          } else if (status == 'processing') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Processing video...',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          } else if (status == 'completed') {
            // Capture the navigator before the async gap.
            final nav = widget.navigator;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              if (nav.canPop()) nav.pop();
            });
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text(
                  'Video uploaded successfully!',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          } else if (status == 'error') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error processing video',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

Future<void> showErrorDialog(BuildContext context, String text) async {
  return showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('AN ERROR OCCURRED'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
