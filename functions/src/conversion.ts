import * as functions from 'firebase-functions/v1/storage';
import * as firebase_functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as tmp from 'tmp-promise';
import ffmpeg from 'fluent-ffmpeg';
import { Storage } from '@google-cloud/storage';
import { ChessGif, parseMoves } from 'pgn2gif';

const storage = new Storage();

interface PgnToGifData {
    userId: string;
    pgnContent: string;
    fileName?: string;
    flipped?: boolean;
    uuid: string;
}

export const convertPgnToGifHttp = firebase_functions.https.onCall(async (request: firebase_functions.https.CallableRequest<PgnToGifData>) => {
    // Expecting a JSON body with at least 'userId' and 'pgnContent' fields.
    const { userId, pgnContent, fileName, flipped, uuid } = request.data;
    try {
        if (!pgnContent || typeof pgnContent !== 'string') {
            throw new firebase_functions.https.HttpsError('invalid-argument', 'Missing or invalid "pgnContent" in request body.');
        }

        const statusRef = admin.firestore().collection('gif_statuses').where('uuid', '==', uuid).limit(1);
        const querySnapshot = await statusRef.get();
        if (querySnapshot.empty) {
            throw new firebase_functions.https.HttpsError('not-found', 'Video not found.');
        }

        await querySnapshot.docs[0].ref.update({
            status: 'received',
        });

        // Use the provided fileName or generate one based on the current timestamp.
        const outputFileName = fileName && typeof fileName === 'string' ? fileName : `pgn2gif_${Date.now()}`;

        const moves = parseMoves(pgnContent);
        const chessGif = new ChessGif();
        chessGif.resetCache();
        chessGif.loadMoves(moves);
        await chessGif.createGif(0, moves.length, flipped);
        const url = chessGif.asBase64Gif();
        const data = await url.arrayBuffer();
        const gifBuffer = Buffer.from(data);

        // Get a reference to the default Firebase Storage bucket.
        const bucket = admin.storage().bucket();
        const destinationPath = `gifs/${outputFileName}.gif`;

        // Save the GIF buffer to Firebase Storage with the proper content type.
        await bucket.file(destinationPath).save(gifBuffer, {
            metadata: {
                contentType: 'image/gif',
                metadata: {
                    userId: userId,
                    uuid: uuid,
                },
            },
        });
        console.log(`GIF successfully uploaded to ${destinationPath}`);
        return { success: true };
    } catch (error) {
        console.error('Error converting PGN to GIF and uploading:', error);
        throw new firebase_functions.https.HttpsError('internal', 'Error converting PGN to GIF and uploading.');
    }
});

export const convertGifToMp4 = functions.object().onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    const userId = object.metadata?.userId;
    const uuid = object.metadata?.uuid;

    // Only process GIF files.
    if (!filePath || !contentType || !contentType.startsWith('image/gif')) {
        console.log('File is not a GIF, skipping conversion.');
        return;
    }

    if (!userId || !uuid) {
        console.log('User ID or UUID is missing, skipping conversion.');
        return;
    }

    const statusRef = admin.firestore().collection('gif_statuses').where('uuid', '==', uuid).limit(1);
    const querySnapshot = await statusRef.get();
    if (querySnapshot.empty) {
        console.log('Video not found, skipping conversion.');
        return;
    }
    await querySnapshot.docs[0].ref.update({
        status: 'converting',
    });
    

    // Reference to the bucket where the file was uploaded.
    const bucket = storage.bucket(object.bucket);

    // Create temporary files for input GIF and output MP4.
    const inputTempFile = await tmp.file({ prefix: 'input-', postfix: '.gif' });
    const outputTempFile = await tmp.file({ prefix: 'output-', postfix: '.mp4' });

    try {
        // Download the GIF file to the temporary location.
        await bucket.file(filePath).download({ destination: inputTempFile.path });
        console.log(`Downloaded GIF to ${inputTempFile.path}`);

        // Run FFmpeg to convert the GIF to MP4.
        await new Promise<void>((resolve, reject) => {
            ffmpeg(inputTempFile.path)
                // Use flags to improve mobile compatibility:
                // -movflags faststart moves the metadata to the beginning.
                // -pix_fmt yuv420p ensures wide compatibility.
                .outputOptions([
                    '-movflags faststart',
                    '-pix_fmt yuv420p',
                ])
                .videoFilters("pad=iw:ceil(iw*16/9):0:(oh-ih)/2:color=black,setsar=1,scale='if(gt(iw,720),720,iw)':'if(gt(ih,1280),1280,ih)'")
                .videoCodec('libx265')
                .outputOptions([
                    '-crf 10',
                    '-b:v 0',
                    '-vtag hvc1'
                ])
                .output(outputTempFile.path)
                .on('end', () => {
                    console.log('FFmpeg conversion finished');
                    resolve();
                })
                .on('error', (err: Error) => {
                    console.error('Error during FFmpeg conversion:', err);
                    reject(err);
                })
                .run();
        });

        // Define the destination path for the MP4 file.
        const destination = filePath.replace(/\.gif$/i, '.mp4').replace('gifs/', `videos/`);
        console.log(`Uploading MP4 to ${destination}`);

        // Upload the MP4 file to the bucket.
        await bucket.upload(outputTempFile.path, {
            destination,
            metadata: {
                contentType: 'video/mp4',
                metadata: {
                    userId: userId,
                },
            },
        });
        await querySnapshot.docs[0].ref.update({
            status: 'completed',
        });
        console.log('MP4 uploaded successfully.');
    } catch (error) {
        console.error('Error in conversion process:', error);
        throw error;
    } finally {
        // Clean up temporary files.
        try {
            await inputTempFile.cleanup();
            await outputTempFile.cleanup();
        } catch (cleanupError) {
            console.error('Error cleaning up temporary files:', cleanupError);
        }
    }
});

export const transcodeVideo = functions.object().onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    const generatePgn = object.metadata?.generatePgn ?? false;

    if (!filePath || !filePath.startsWith('tmp/')) {
        // console.log('File is not in the tmp directory, skipping conversion.');
        return;
    }

    // Only process MP4 files.
    if (!contentType || !contentType.startsWith('video/mp4')) {
        console.log('File is not a MP4, skipping conversion.');
        return;
    }

    const fileName = filePath.split('/').pop(); // 'uuid.mp4'
    const uuid = fileName?.replace('.mp4', '');
    if (!uuid) {
        console.log('File name is not a valid UUID, skipping conversion.');
        return;
    }

    let userId: string | null = null;
    let videoRef, querySnapshot, videoDoc;
    let pgnStatusRef, pgnStatusQuerySnapshot, pgnStatusDoc;
    if (!generatePgn) {
        videoRef = admin.firestore().collection('videos').where('id', '==', uuid).limit(1);
        querySnapshot = await videoRef.get();
        if (querySnapshot.empty) {
            console.log('Video not found, skipping conversion.');
            return;
        }
    
        videoDoc = querySnapshot.docs[0];
        userId = videoDoc.data().uploaderId;
    } else {
        pgnStatusRef = admin.firestore().collection('pgn_statuses').where('uuid', '==', uuid).limit(1);
        pgnStatusQuerySnapshot = await pgnStatusRef.get();
        if (pgnStatusQuerySnapshot.empty) {
            console.log('PGN status not found, skipping conversion.');
            return;
        }
        pgnStatusDoc = pgnStatusQuerySnapshot.docs[0];
        await pgnStatusDoc!.ref.update({
            status: 'processing',
        });
        userId = object.metadata?.userId!;
    }

    // Reference to the bucket where the file was uploaded.
    const bucket = storage.bucket(object.bucket);

    // Create temporary files for input GIF and output MP4.
    const inputTempFile = await tmp.file({ prefix: 'input-', postfix: '.mp4' });
    const outputTempFile = await tmp.file({ prefix: 'output-', postfix: '.mp4' });

    try {
        // Download the GIF file to the temporary location.
        await bucket.file(filePath).download({ destination: inputTempFile.path });
        console.log(`Downloaded MP4 to ${inputTempFile.path}`);

        // Run FFmpeg to convert the GIF to MP4.
        await new Promise<void>((resolve, reject) => {
            ffmpeg(inputTempFile.path)
                // Use flags to improve mobile compatibility:
                // -movflags faststart moves the metadata to the beginning.
                // -pix_fmt yuv420p ensures wide compatibility.
                .outputOptions([
                    '-movflags faststart',
                    '-pix_fmt yuv420p',
                ])
                .videoFilters("pad=iw:ceil(iw*16/9):0:(oh-ih)/2:color=black,setsar=1,scale='if(gt(iw,720),720,iw)':'if(gt(ih,1280),1280,ih)'")
                .videoCodec('libx265')
                .outputOptions([
                    '-crf 10',
                    '-b:v 0',
                    '-vtag hvc1'
                ])
                .output(outputTempFile.path)
                .on('end', () => {
                    console.log('FFmpeg conversion finished');
                    resolve();
                })
                .on('error', (err: Error) => {
                    console.error('Error during FFmpeg conversion:', err);
                    reject(err);
                })
                .run();
        });

        // Define the destination path for the MP4 file.
        const destination = filePath.replace('tmp/', `videos/`);
        console.log(`Uploading MP4 to ${destination}`);

        // Upload the MP4 file to the bucket.
        await bucket.upload(outputTempFile.path, {
            destination,
            metadata: {
                contentType: 'video/mp4',
                metadata: {
                    userId: userId,
                },
            },
        });
        console.log('MP4 uploaded successfully.');

        if (!generatePgn) {
            // Update the video document with the new video URL.
            await videoDoc!.ref.update({
                videoUrl: destination,
                thumbnailUrl: destination,
                status: 'completed',
            });
        } else {
            // Send HTTP request to Cloud Run Service to generate PGN
            const publicUrl = `https://storage.googleapis.com/${object.bucket}/videos/${uuid}.mp4`
            const response = await fetch('https://video2pgn-596188845031.us-central1.run.app/process_video', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ url: publicUrl }),
            });

            if (!response.ok) {
                throw new Error(`Request failed with status ${response.status}: ${response.statusText}`);
            }
            const data = await response.json();
            await pgnStatusDoc!.ref.update({
                pgnContent: data.pgn,
                timestamps: data.timestamps,
                status: 'completed',
            });
        }
    } catch (error) {
        console.error('Error in conversion process:', error);
        if (!generatePgn) {
            await videoDoc!.ref.update({
                status: 'error',
                error: `Error transcoding video: ${error}`,
            });
        } else {
            await pgnStatusDoc!.ref.update({
                status: 'error',
                error: `Error generating PGN: ${error}`,
            });
        }
        throw error;
    } finally {
        // Clean up temporary files.
        try {
            await inputTempFile.cleanup();
            await outputTempFile.cleanup();
        } catch (cleanupError) {
            console.error('Error cleaning up temporary files:', cleanupError);
        }
    }
});