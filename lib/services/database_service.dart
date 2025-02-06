import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/video.dart';

class DatabaseService {
  static final _log = Logger('DatabaseService');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Video>> getVideos({int limit = 10}) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Video.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
    } catch (e) {
      _log.severe('Error fetching videos', e);
      rethrow;
    }
  }

  Future<void> incrementVideoView(String videoId) async {
    try {
      await _firestore.collection('videos').doc(videoId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      _log.warning('Error incrementing view count for video: $videoId', e);
      rethrow;
    }
  }

  Future<void> toggleLike(String videoId, String userId) async {
    try {
      final docRef = _firestore.collection('videos').doc(videoId);
      final likeRef = docRef.collection('likes').doc(userId);

      final likeDoc = await likeRef.get();
      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await docRef.update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        await docRef.update({
          'likesCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      _log.warning('Error toggling like for video: $videoId, user: $userId', e);
      rethrow;
    }
  }

  Future<bool> isVideoLikedByUser(String videoId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('likes')
          .doc(userId)
          .get();
      
      return likeDoc.exists;
    } catch (e) {
      _log.warning('Error checking like status for video: $videoId, user: $userId', e);
      rethrow;
    }
  }

  Future<void> addComment(String videoId, String userId, String text) async {
    try {
      final docRef = _firestore.collection('videos').doc(videoId);
      final commentRef = docRef.collection('comments');

      await commentRef.add({
        'commenterId': userId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
      });

      await docRef.update({
        'commentsCount': FieldValue.increment(1),
      });
    } catch (e) {
      _log.warning('Error adding comment to video: $videoId, user: $userId', e);
      rethrow;
    }
  }

  Future<String> getUsernameById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        _log.warning('User document not found for ID: $userId');
        return 'Unknown User';
      }
      
      final userData = userDoc.data();
      final username = userData?['username'] as String? ?? 'Unknown User';
      return username == 'Unknown User' ? username : '@$username';
    } catch (e) {
      _log.warning('Error fetching username for user: $userId', e);
      return 'Unknown User';
    }
  }
} 