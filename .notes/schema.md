1. Users Collection
Path: /users/{userId} // userId will also refer to Firebase Auth UID
Structure:
{
  "userId": "stockfish_master_userId",
  "username": "stockfish_master",
  "displayName": "Stockfish Master",
  "profilePictureUrl": "https://example.com/profilePic.jpg",
  "bio": "Chess streamer & analyst",
  "email": "user@example.com",
  "followersCount": 1250,
  "followingCount": 300,
  "createdAt": "2025-01-15T10:00:00Z"
}
2. Followers Subcollection (Under Users)
Path: /users/{userId}/followers/{followerId}
Structure:
{
  "followerId": "someOtherUserId",
  "followedAt": "2025-02-01T15:30:00Z"
}
3. Following Subcollection (Under Users)
Path: /users/{userId}/following/{followingId}
Structure:
{
  "followingId": "anotherUserId",
  "followedAt": "2025-02-01T15:32:00Z"
}
4. Usernames Collection
Path: /usernames/{username}
Structure:
{
  "username": "stockfish_master",
  "userId": "stockfish_master_userId"
}
5. Videos Collection
Path: /videos/{videoId}
Structure:
{
  "uploaderId": "stockfish_master_userId",
  "videoUrl": "https://firebasestorage.googleapis.com/...",
  "thumbnailUrl": "https://firebasestorage.googleapis.com/...",
  "description": "Check out my latest analysis of the Sicilian Defense!",
  "hashtags": ["#chess", "#SicilianDefense"],
  "chessOpenings": ["Sicilian Defense", "Najdorf Variation"],
  "createdAt": "2025-02-02T12:00:00Z",
  "likesCount": 340,
  "commentsCount": 45,
  "viewCount": 1200,
  
  "gameMetadata": {
    "playerELO": 2400,
    "opponentELO": 2350,
    "site": "chess.com",
    "datePlayed": "2025-02-01T19:45:00Z",
    "result": "1-0",
    "pgn": "[Event \"Online Chess\"]\n[Site \"chess.com\"]\n[Date \"2025.02.01\"]\n...etc..."
  },
  
  "videoSegments": {
    "opening": 5,
    "middlegame": 45,
    "endgame": 120
  },
  
  "animationData": [
    {
      "moveNumber": 4,
      "moveColor": "white",
      "classification": "brilliant",
      "animationType": "highlight",
      "timestamp": 30
    },
    {
      "moveNumber": 12,
      "moveColor": "black",
      "classification": "blunder",
      "animationType": "shake",
      "timestamp": 80
    }
  ],
  
  "moves": [
    {
      "moveNumber": 1,
      "moveColor": "white",
      "notation": "e4",
      "classification": "normal",
      "timestamp": 6,
      "annotation": "Opening move to control the center"
    },
    {
      "moveNumber": 1,
      "moveColor": "black",
      "notation": "c5",
      "classification": "normal",
      "timestamp": 8,
      "annotation": "Sicilian Defense response"
    }
  ]
}
6. Comments Subcollection (Under Videos)
Path: /videos/{videoId}/comments/{commentId}
Structure:
{
  "commenterId": "user123",
  "text": "Amazing analysis!",
  "createdAt": "2025-02-02T12:05:00Z",
  "likesCount": 5
}
7. Likes Subcollection (Under Videos)
Path: /videos/{videoId}/likes/{userId}
Structure:
{
  "userId": "user123",
  "likedAt": "2025-02-02T12:03:00Z"
}

