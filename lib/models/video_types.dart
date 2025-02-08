import 'dart:io';

// Common types and enums for video creation flow
enum VideoSource {
  camera,
  gallery,
  remote,
}

enum MoveClassification {
  brilliant,
  good,
  book,
  inaccuracy,
  mistake,
  blunder,
}

/// Represents either a local video file or a remote video URL
class VideoData {
  final File? file;
  final String? remoteUrl;
  final String? storageUrl;
  final VideoSource source;

  const VideoData._({
    this.file,
    this.remoteUrl,
    this.storageUrl,
    required this.source,
  }) : assert(
          (file != null && remoteUrl == null) || (file == null && remoteUrl != null),
          'Either file or remoteUrl must be provided, but not both',
        );

  /// Create a VideoData instance from a local file
  factory VideoData.fromFile(File file, VideoSource source) {
    assert(source != VideoSource.remote, 'Cannot use remote source with a local file');
    return VideoData._(file: file, source: source);
  }

  /// Create a VideoData instance from a remote URL
  factory VideoData.fromUrl(String url, String storageUrl) {
    return VideoData._(remoteUrl: url, storageUrl: storageUrl, source: VideoSource.remote);
  }

  /// Whether this video is from a remote source
  bool get isRemote => source == VideoSource.remote;
}

class MoveAnnotation {
  final int moveNumber;
  final String moveColor;
  final String notation;
  int timestamp;
  MoveClassification? classification;
  String? annotation;

  MoveAnnotation({
    required this.moveNumber,
    required this.moveColor,
    required this.notation,
    required this.timestamp,
    this.classification,
    this.annotation,
  });

  Map<String, dynamic> toJson() => {
        'moveNumber': moveNumber,
        'moveColor': moveColor,
        'notation': notation,
        'timestamp': timestamp,
        'classification': classification?.toString().split('.').last,
        'annotation': annotation,
      };
} 