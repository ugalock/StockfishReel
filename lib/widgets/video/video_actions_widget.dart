import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../models/video.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class VideoActionsWidget extends StatefulWidget {
  final Video video;

  const VideoActionsWidget({
    super.key,
    required this.video,
  });

  @override
  State<VideoActionsWidget> createState() => _VideoActionsWidgetState();
}

class _VideoActionsWidgetState extends State<VideoActionsWidget> {
  static final _log = Logger('VideoActionsWidget');
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;

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
      _log.fine('Successfully checked like status for video: ${widget.video.id}');
    } catch (e) {
      _log.warning(
        'Failed to check like status for video: ${widget.video.id}',
        e,
      );
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
        'Successfully ${_isLiked ? 'liked' : 'unliked'} video: ${widget.video.id}',
      );
    } catch (e) {
      _log.warning(
        'Failed to toggle like for video: ${widget.video.id}, user: ${user.uid}',
        e,
      );
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
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comments',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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

  void _showGameInfo() {
    _log.fine('Showing game info for video: ${widget.video.id}');
    // TODO: Show game metadata
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile Picture
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const CircleAvatar(
            // TODO: Add user profile picture
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),

        // Like Button
        _ActionButton(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          label: 'Like', // widget.video.likesCount.toString(),
          color: _isLiked ? Colors.red : Colors.white,
          onTap: _handleLike,
        ),
        const SizedBox(height: 20),

        // Comment Button
        _ActionButton(
          icon: Icons.comment,
          label: 'Comment', // widget.video.commentsCount.toString(),
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

        // Game Info Button
        _ActionButton(
          icon: Icons.info_outline,
          label: 'Info',
          onTap: _showGameInfo,
        ),
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