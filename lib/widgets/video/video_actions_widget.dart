import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:video_player/video_player.dart';
import '../../models/video.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class VideoActionsWidget extends StatefulWidget {
  final Video video;
  final VideoPlayerController? controller;

  const VideoActionsWidget({
    super.key,
    required this.video,
    this.controller,
  });

  @override
  State<VideoActionsWidget> createState() => _VideoActionsWidgetState();
}

class _VideoActionsWidgetState extends State<VideoActionsWidget> {
  static final _log = Logger('VideoActionsWidget');
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  bool _showingGameInfo = false;

  // Map for classification icons
  final Map<String, String> _classificationIcons = {
    'brilliant': 'assets/images/move_icons/brilliant_32x.png',
    'good': 'assets/images/move_icons/good_32x.png',
    'book': 'assets/images/move_icons/book_32x.png',
    'inaccuracy': 'assets/images/move_icons/inaccuracy_32x.png',
    'mistake': 'assets/images/move_icons/mistake_32x.png',
    'blunder': 'assets/images/move_icons/blunder_32x.png',
  };

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  Future<void> _checkIfLiked() async {
    final user = _authService.currentUser;
    if (user == null) {
      _log.fine('Cannot check like status: no authenticated user');
      return;
    }

    try {
      final isLiked = await _databaseService.isVideoLikedByUser(
        widget.video.id,
        user.uid,
      );
      setState(() {
        _isLiked = isLiked;
      });
      _log.fine(
          'Successfully checked like status for video: ${widget.video.id}');
    } catch (e) {
      _log.warning(
          'Failed to check like status for video: ${widget.video.id}', e);
    }
  }

  Future<void> _handleLike() async {
    final user = _authService.currentUser;
    if (user == null) {
      _log.info('Like attempted without user authentication');
      return;
    }

    try {
      await _databaseService.toggleLike(widget.video.id, user.uid);
      setState(() {
        _isLiked = !_isLiked;
      });
      _log.fine(
          'Successfully ${_isLiked ? 'liked' : 'unliked'} video: ${widget.video.id}');
    } catch (e) {
      _log.warning(
          'Failed to toggle like for video: ${widget.video.id}, user: ${user.uid}',
          e);
    }
  }

  void _showComments() {
    _log.fine('Opening comments for video: ${widget.video.id}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: 0, // TODO: Implement comments
                  itemBuilder: (context, index) {
                    return const ListTile(
                      title: Text(
                        'Comment placeholder',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleShare() {
    _log.fine('Share initiated for video: ${widget.video.id}');
    // TODO: Implement share functionality
  }

  void _toggleGameInfo() {
    _log.fine('Toggling game info for video: ${widget.video.id}');
    setState(() {
      _showingGameInfo = !_showingGameInfo;
    });
  }

  // Helper method to build a move cell.
  // If a move has a valid timestamp, it becomes tappable and seeks the video.
  Widget _buildMoveCell(dynamic move, {String? prefix}) {
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prefix != null)
          Text(prefix,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text(move.notation,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: move.timestamp != null &&
        move.timestamp > 0 ? FontWeight.bold : FontWeight.normal)),
        if (move.classification != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Image.asset(
              _classificationIcons[move.classification]!,
              width: 12,
              height: 12,
            ),
          ),
      ],
    );

    if (move.timestamp != null &&
        move.timestamp > 0 &&
        widget.controller != null &&
        widget.controller!.value.isInitialized) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await widget.controller!.seekTo(Duration(seconds: move.timestamp));
          widget.controller!.play();
        },
        child: content,
      );
    }
    return content;
  }

  Widget _buildGameInfoOverlay() {
    final segments = widget.video.videoSegments;
    final moves = widget.video.moves;

    return Stack(
      children: [
        Container(
          width: 140,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (segments.middlegame > 0) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        _log.fine(
                            'Tapped Middle game, seeking to ${segments.middlegame}');
                        if (widget.controller != null &&
                            widget.controller!.value.isInitialized) {
                          await widget.controller!
                              .seekTo(Duration(seconds: segments.middlegame));
                          widget.controller!.play();
                        }
                      },
                      child: const Text(
                        'Middle game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (segments.endgame > 0) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        _log.fine(
                            'Tapped End game, seeking to ${segments.endgame}');
                        if (widget.controller != null &&
                            widget.controller!.value.isInitialized) {
                          await widget.controller!
                              .seekTo(Duration(seconds: segments.endgame));
                          // await Future.delayed(const Duration(milliseconds: 100));
                          widget.controller!.play();
                        }
                      },
                      child: const Text(
                        'End game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (moves != null)
                    for (int i = 0; i < moves.length; i += 2) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // White move cell with fixed width (includes move number)
                            // ignore: sized_box_for_whitespace
                            Container(
                              width: 60,
                              child: _buildMoveCell(moves[i], prefix: '${(i ~/ 2) + 1}. '),
                            ),
                            const SizedBox(width: 16),
                            // Black move cell, if exists
                            if (i + 1 < moves.length)
                              Expanded(child: _buildMoveCell(moves[i + 1])),
                          ],
                        ),
                      ),
                      if (i < moves.length - 2) const SizedBox(height: 4),
                    ],
                ],
              ),
            ),
          ),
        ),
        // Close (X) in the top right corner of the overlay.
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _toggleGameInfo,
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showingGameInfo)
          _buildGameInfoOverlay()
        else ...[
          // Profile Picture
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          // Like Button
          _ActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            label: 'Like',
            color: _isLiked ? Colors.red : Colors.white,
            onTap: _handleLike,
          ),
          const SizedBox(height: 20),
          // Comment Button
          _ActionButton(
            icon: Icons.comment,
            label: 'Comment',
            onTap: _showComments,
          ),
          const SizedBox(height: 20),
          // Share Button
          _ActionButton(
            icon: Icons.share,
            label: 'Share',
            onTap: _handleShare,
          ),
          const SizedBox(height: 20),
          // Info Button
          _ActionButton(
            icon: Icons.info_outline,
            label: 'Info',
            onTap: _toggleGameInfo,
          ),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
