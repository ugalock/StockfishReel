import 'package:flutter/material.dart';
import '../../models/video.dart';
import '../../services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class VideoInfoWidget extends StatefulWidget {
  final Video video;

  const VideoInfoWidget({
    super.key,
    required this.video,
  });

  @override
  State<VideoInfoWidget> createState() => _VideoInfoWidgetState();
}

class _VideoInfoWidgetState extends State<VideoInfoWidget> {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _username = 'Loading...';
  int _likesCount = 0;
  int _commentsCount = 0;
  StreamSubscription<DocumentSnapshot>? _videoSubscription;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _initializeCounters();
    _subscribeToVideoUpdates();
  }

  @override
  void dispose() {
    _videoSubscription?.cancel();
    super.dispose();
  }

  void _initializeCounters() {
    setState(() {
      _likesCount = widget.video.likesCount;
      _commentsCount = widget.video.commentsCount;
    });
  }

  void _subscribeToVideoUpdates() {
    final videoRef = _firestore.collection('videos').doc(widget.video.id);
    _videoSubscription = videoRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) return;
        
        final data = snapshot.data();
        if (data == null) return;
        
        setState(() {
          _likesCount = (data['likesCount'] as num?)?.toInt() ?? _likesCount;
          _commentsCount = (data['commentsCount'] as num?)?.toInt() ?? _commentsCount;
        });
      },
      onError: (error) {
        debugPrint('Error listening to video updates: $error');
      },
    );
  }

  Future<void> _loadUsername() async {
    final username = await _databaseService.getUsernameById(widget.video.uploaderId);
    if (mounted) {
      setState(() {
        _username = username;
      });
    }
  }

  String _buildDescriptionWithHashtags() {
    final description = widget.video.description;
    final hashtags = widget.video.hashtags;
    if (hashtags.isEmpty) return description;

    return '$description ${hashtags.map((tag) => '**$tag**').join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Username and game result
        Row(
          children: [
            Text(
              _username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.video.gameMetadata.result ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Description with hashtags
        Text.rich(
          TextSpan(
            children: _buildDescriptionWithHashtags()
                .split(' ')
                .map((word) {
                  if (word.startsWith('**#')) {
                    final hashtag = word.substring(2, word.length - 2);
                    return TextSpan(
                      text: '$hashtag ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return TextSpan(
                    text: '$word ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  );
                })
                .toList(),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Chess opening tags
        if (widget.video.chessOpenings.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.video.chessOpenings.map((opening) {
              return Text(
                opening,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),

        // Game metadata (ELO ratings) and interaction counts
        Row(
          children: [
            Text(
              'Player: ${widget.video.gameMetadata.playerELO != null && widget.video.gameMetadata.playerELO != 0 ? widget.video.gameMetadata.playerELO : '?'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Opponent: ${widget.video.gameMetadata.opponentELO != null && widget.video.gameMetadata.opponentELO != 0 ? widget.video.gameMetadata.opponentELO : '?'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$_likesCount likes • $_commentsCount comments',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 