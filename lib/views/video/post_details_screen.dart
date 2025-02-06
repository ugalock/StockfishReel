import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../models/video_types.dart';
import '../main_layout/main_layout_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final File videoFile;
  final String? pgnContent;
  final String? openingName;
  final double middleGameTimestamp;
  final double endGameTimestamp;
  final List<MoveAnnotation> moveAnnotations;

  const PostDetailsScreen({
    super.key,
    required this.videoFile,
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
  bool _isUploading = false;
  String? _error;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Pre-fill hashtags with opening name if available
    if (widget.openingName != null) {
      _hashtagsController.text = '#${widget.openingName!.replaceAll(' ', '')}';
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _captionController.dispose();
    _hashtagsController.dispose();
    super.dispose();
  }

  List<String> _parseHashtags(String input) {
    final hashtags = input.split(' ')
        .where((word) => word.startsWith('#'))
        .map((tag) => tag.toLowerCase())
        .toList();
    
    // Add default hashtags
    if (!hashtags.contains('#chess')) {
      hashtags.add('#chess');
    }
    if (!hashtags.contains('#stockfishreel')) {
      hashtags.add('#stockfishreel');
    }
    
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

      // Generate unique ID for the video
      final videoId = const Uuid().v4();
      
      // Upload video file to Firebase Storage
      final videoRef = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child(user.uid)
          .child('$videoId.mp4');
      
      await videoRef.putFile(widget.videoFile);
      final videoUrl = await videoRef.getDownloadURL();

      // Generate thumbnail (you might want to implement a proper thumbnail generation)
      final thumbnailUrl = videoUrl; // For now, using video URL as thumbnail

      // Create video document in Firestore
      final videoDoc = {
        'id': videoId,
        'uploaderId': user.uid,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'description': _captionController.text,
        'hashtags': _parseHashtags(_hashtagsController.text),
        'chessOpenings': widget.openingName != null ? [widget.openingName!] : [],
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'viewCount': 0,
        'gameMetadata': {
          'playerELO': 0, // You might want to add these fields to the form
          'opponentELO': 0,
          'site': 'StockfishReel',
          'datePlayed': DateTime.now().toIso8601String(),
          'result': '',
          'pgn': widget.pgnContent ?? '',
        },
        'videoSegments': {
          'opening': 0,
          'middlegame': widget.middleGameTimestamp.toInt(),
          'endgame': widget.endGameTimestamp.toInt(),
        },
        'moves': widget.moveAnnotations.map((move) => move.toJson()).toList(),
      };

      await FirebaseFirestore.instance
          .collection('videos')
          .doc(videoId)
          .set(videoDoc);

      if (mounted) {
        // Navigate back to main feed
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainLayoutScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error uploading video: ${e.toString()}';
        _isUploading = false;
      });
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
                      'New Post',
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Preview
                    if (_controller.value.isInitialized)
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    const SizedBox(height: 24),

                    // Caption
                    TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Caption',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Hashtags
                    TextField(
                      controller: _hashtagsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Hashtags',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: '#chess #opening #tactics',
                        hintStyle: TextStyle(color: Colors.white30),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Separate hashtags with spaces',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Game Details Preview
                    if (widget.openingName != null) ...[
                      const Text(
                        'Game Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Opening: ${widget.openingName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phases: Opening (0:00) → Middle Game (${Duration(seconds: widget.middleGameTimestamp.toInt()).toString().split('.').first}) → End Game (${Duration(seconds: widget.endGameTimestamp.toInt()).toString().split('.').first})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Moves: ${widget.moveAnnotations.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Post Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Post',
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