import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

interface CreateUserData {
  userId: string;
  username: string;
  email: string;
  displayName?: string;
}

export const createUser = functions.https.onCall(async (request: functions.https.CallableRequest<CreateUserData>) => {
  const { userId, username, email, displayName } = request.data;

  // Validate input
  if (!userId || !username || !email) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }

  // Remove @ prefix if present for storage
  const cleanUsername = username.startsWith('@') ? username.substring(1) : username;

  const db = admin.firestore();
  const usernameRef = admin.firestore().collection('usernames').doc(cleanUsername);
  const userRef = admin.firestore().collection('users').doc(userId);
  
  try {
    // Use transaction to ensure atomicity
    await db.runTransaction(async (transaction) => {
      // Check if username already exists
      const usernameDoc = await transaction.get(usernameRef);

      if (usernameDoc.exists) {
        throw new functions.https.HttpsError(
          'already-exists',
          'Username is already taken'
        );
      }

      // Set user document
      transaction.set(userRef, {
        userId,
        username: cleanUsername,
        displayName: displayName || cleanUsername,
        email,
        profilePictureUrl: '',
        bio: '',
        followersCount: 0,
        followingCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Set username document
      transaction.set(usernameRef, {
        username: cleanUsername,
        userId,
      });
    });

    return { success: true };
  } catch (error) {
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    functions.logger.error('Error creating user:', error);
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while creating the user'
    );
  }
}); 