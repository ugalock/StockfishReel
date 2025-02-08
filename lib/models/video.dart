class Video {
  final String id;
  final String uploaderId;
  final String videoUrl;
  final String thumbnailUrl;
  final String description;
  final List<String> hashtags;
  final List<String> chessOpenings;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final int viewCount;
  final GameMetadata gameMetadata;
  final VideoSegments videoSegments;
  final List<AnimationData>? animationData;
  final List<MoveData>? moves;

  const Video({
    required this.id,
    required this.uploaderId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.description,
    required this.hashtags,
    required this.chessOpenings,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.viewCount,
    required this.gameMetadata,
    required this.videoSegments,
    required this.animationData,
    required this.moves,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      uploaderId: json['uploaderId'] as String,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      description: json['description'] as String,
      hashtags: List<String>.from(json['hashtags']),
      chessOpenings: List<String>.from(json['chessOpenings']),
      createdAt: json['createdAt'].toDate(),
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      viewCount: json['viewCount'] as int,
      gameMetadata: GameMetadata.fromJson(json['gameMetadata'] as Map<String, dynamic>),
      videoSegments: VideoSegments.fromJson(json['videoSegments'] as Map<String, dynamic>),
      animationData: json['animationData'] != null
          ? (json['animationData'] as List)
              .map((e) => AnimationData.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      moves: json['moves'] != null
          ? (json['moves'] as List)
              .map((e) => MoveData.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

class GameMetadata {
  final int? playerELO;
  final int? opponentELO;
  final String? site;
  final DateTime? datePlayed;
  final String? result;
  final String? pgn;

  const GameMetadata({
    required this.playerELO,
    required this.opponentELO,
    required this.site,
    required this.datePlayed,
    required this.result,
    required this.pgn,
  });

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    return GameMetadata(
      playerELO: json['playerELO'] as int?,
      opponentELO: json['opponentELO'] as int?,
      site: json['site'] as String?,
      datePlayed: json['datePlayed'] != null ? DateTime.parse(json['datePlayed'] as String) : null,
      result: json['result'] as String?,
      pgn: json['pgn'] as String?,
    );
  }
}

class VideoSegments {
  final int opening;
  final int middlegame;
  final int endgame;

  const VideoSegments({
    required this.opening,
    required this.middlegame,
    required this.endgame,
  });

  factory VideoSegments.fromJson(Map<String, dynamic> json) {
    return VideoSegments(
      opening: json['opening'] as int,
      middlegame: json['middlegame'] as int,
      endgame: json['endgame'] as int,
    );
  }
}

class AnimationData {
  final int moveNumber;
  final String moveColor;
  final String classification;
  final String animationType;
  final int timestamp;

  const AnimationData({
    required this.moveNumber,
    required this.moveColor,
    required this.classification,
    required this.animationType,
    required this.timestamp,
  });

  factory AnimationData.fromJson(Map<String, dynamic> json) {
    return AnimationData(
      moveNumber: json['moveNumber'] as int,
      moveColor: json['moveColor'] as String,
      classification: json['classification'] as String,
      animationType: json['animationType'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

class MoveData {
  final int moveNumber;
  final String moveColor;
  final String notation;
  final String? classification;
  final int timestamp;
  final String? annotation;

  const MoveData({
    required this.moveNumber,
    required this.moveColor,
    required this.notation,
    required this.classification,
    required this.timestamp,
    required this.annotation,
  });

  factory MoveData.fromJson(Map<String, dynamic> json) {
    return MoveData(
      moveNumber: json['moveNumber'] as int,
      moveColor: json['moveColor'] as String,
      notation: json['notation'] as String,
      classification: json['classification'] as String?,
      timestamp: json['timestamp'] as int,
      annotation: json['annotation'] as String?,
    );
  }
} 