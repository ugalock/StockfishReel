// video_player_widget.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatelessWidget {
  final VideoPlayerController controller;
  final bool isActive;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Toggle play/pause on tap
        if (controller.value.isPlaying) {
          controller.pause();
        } else {
          controller.play();
        }
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          children: [
            // The video content.
            VideoPlayer(controller),
            // Overlay a play button when the video is paused.
            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                if (!controller.value.isPlaying) {
                  return Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black45, // Fairly opaque background.
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.play_arrow,
                          size: 64.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Display the progress bar at the bottom of the video.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: const EdgeInsets.all(8.0),
                colors: const VideoProgressColors(
                  playedColor: Color.fromARGB(255, 107, 107, 107),
                  // bufferedColor: Colors.white,
                  backgroundColor: Color.fromARGB(26, 158, 158, 158),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
