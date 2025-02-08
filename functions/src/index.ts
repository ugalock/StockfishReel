/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// import {onRequest} from "firebase-functions/v2/https";
// import * as logger from "firebase-functions/logger";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
import * as admin from 'firebase-admin';

// Initialize the default Firebase app.
admin.initializeApp();

import { createUser } from "./auth";
import { convertPgnToGifHttp, convertGifToMp4, transcodeVideo } from "./conversion";

export { createUser, convertPgnToGifHttp, convertGifToMp4, transcodeVideo };