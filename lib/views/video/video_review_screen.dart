import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'add_pgn_screen.dart';
import '../../models/video_types.dart';

class VideoReviewScreen extends StatefulWidget {
  final VideoData videoData;
  final String? initialPgnContent;
  final List<int>? timestamps;

  const VideoReviewScreen({
    super.key,
    required this.videoData,
    this.initialPgnContent,
    this.timestamps,
  });

  @override
  State<VideoReviewScreen> createState() => _VideoReviewScreenState();
}

class _VideoReviewScreenState extends State<VideoReviewScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _shouldGeneratePgn = false;
  bool _isProcessing = false;
  String? _error;

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
      await _controller.setLooping(true);
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

  Future<void> _handleNext() async {
    if (!_shouldGeneratePgn) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddPGNScreen(
            videoData: widget.videoData,
            initialPgnContent: widget.initialPgnContent,
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
        _error = null;
      });

      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Generate a unique ID for the PGN generation
      final uuid = const Uuid().v4();

      // Create initial status document
      final pgnStatusRef = FirebaseFirestore.instance.collection('pgn_statuses').doc(uuid);
      await pgnStatusRef.set({
        'uuid': uuid,
        'status': 'pending',
      });

      // Upload video to temporary storage
      final tempVideoRef = FirebaseStorage.instance.ref().child('tmp').child('$uuid.mp4');
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'generatePgn': '1',
          'userId': userId,
        },
      );
      
      if (widget.videoData.isRemote) {
        // If video is remote, we need to download and reupload it
        final response = await http.get(Uri.parse(widget.videoData.remoteUrl!));
        await tempVideoRef.putData(response.bodyBytes, metadata);
      } else {
        await tempVideoRef.putFile(widget.videoData.file!, metadata);
      }

      // Capture NavigatorState before async gap
      if (!mounted) return;
      final navigator = Navigator.of(context);

      // Show status dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PgnStatusDialog(
          pgnStatusRef: pgnStatusRef,
          navigator: navigator,
        ),
      );

      // Check final status
      final doc = await pgnStatusRef.get();
      final data = doc.data() as Map<String, dynamic>;
      
      if (data['status'] == 'completed' && data['pgnContent'] != null) {
        // Get the new video URL from Firebase Storage
        final videoRef = FirebaseStorage.instance.ref().child('videos/$uuid.mp4');
        final downloadUrl = await videoRef.getDownloadURL();
        
        // Create new VideoData with the processed video URL
        final processedVideoData = VideoData.fromUrl(downloadUrl, 'videos/$uuid.mp4');
        
        // Properly convert List<dynamic> to List<int>
        List<int>? timestampsList;
        if (data['timestamps'] != null) {
          timestampsList = (data['timestamps'] as List).map((item) => item as int).toList();
        }
        
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddPGNScreen(
                videoData: processedVideoData,
                initialPgnContent: data['pgnContent'],
                timestamps: timestampsList,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error processing video: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Preview
            if (_controller.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'Preview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 40), // For symmetry
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Generate PGN from Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Switch(
                            value: _shouldGeneratePgn,
                            onChanged: (value) {
                              setState(() {
                                _shouldGeneratePgn = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Play/Pause Button Overlay
            if (_controller.value.isInitialized)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: !_isPlaying ? Icon(
                        Icons.play_arrow,
                        size: 64.0,
                        color: Colors.white,
                      ) : null,
                    ),
                  ),
                ),
              ),

            // Bottom Bar with Next Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.value.isInitialized)
                      VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    ElevatedButton(
                      onPressed: _isProcessing ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                    ),
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

/// A modal widget that polls the status of the PGN generation in real time.
class PgnStatusDialog extends StatefulWidget {
  final DocumentReference pgnStatusRef;
  final NavigatorState navigator;

  const PgnStatusDialog({
    super.key,
    required this.pgnStatusRef,
    required this.navigator,
  });

  @override
  State<PgnStatusDialog> createState() => _PgnStatusDialogState();
}

class _PgnStatusDialogState extends State<PgnStatusDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Processing Video', textAlign: TextAlign.center),
      content: StreamBuilder<DocumentSnapshot>(
        stream: widget.pgnStatusRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'An error occurred.',
              textAlign: TextAlign.center,
            );
          }

          if (!snapshot.hasData) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing...'),
              ],
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';

          if (status == 'pending' || status == 'processing') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing video and generating PGN...'),
              ],
            );
          } else if (status == 'completed') {
            // Capture the navigator before the async gap
            final nav = widget.navigator;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              if (nav.canPop()) nav.pop();
            });
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('PGN generation complete!'),
              ],
            );
          } else if (status == 'error') {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Error generating PGN from video.'),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
} 