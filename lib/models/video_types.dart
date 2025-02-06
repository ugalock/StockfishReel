// Common types and enums for video creation flow
enum VideoSource {
  camera,
  gallery,
}

enum MoveClassification {
  brilliant,
  good,
  inaccuracy,
  mistake,
  blunder,
  normal,
}

class MoveAnnotation {
  final int moveNumber;
  final String moveColor;
  final String notation;
  MoveClassification classification;
  String? annotation;
  int timestamp;

  MoveAnnotation({
    required this.moveNumber,
    required this.moveColor,
    required this.notation,
    this.classification = MoveClassification.normal,
    this.annotation,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'moveNumber': moveNumber,
      'moveColor': moveColor,
      'notation': notation,
      'classification': classification.name,
      'timestamp': timestamp,
      'annotation': annotation,
    };
  }
} 