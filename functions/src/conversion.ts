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
}

export const convertPgnToGifHttp = firebase_functions.https.onCall(async (request: firebase_functions.https.CallableRequest<PgnToGifData>) => {
    // Expecting a JSON body with at least 'userId' and 'pgnContent' fields.
    const { userId, pgnContent, fileName, flipped } = request.data;
    try {
        if (!pgnContent || typeof pgnContent !== 'string') {
            throw new firebase_functions.https.HttpsError('invalid-argument', 'Missing or invalid "pgnContent" in request body.');
        }
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
                userId: userId,
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
    // Only process GIF files.
    if (!filePath || !contentType || !contentType.startsWith('image/gif')) {
        console.log('File is not a GIF, skipping conversion.');
        return;
    }

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
                .videoCodec('libaom-av1')
                .outputOptions([
                    '-crf 30',
                    '-b:v 0',
                    '-cpu-used 4'
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
        const destination = filePath.replace(/\.gif$/i, '.mp4').replace('gifs/', 'videos/');
        console.log(`Uploading MP4 to ${destination}`);

        // Upload the MP4 file to the bucket.
        await bucket.upload(outputTempFile.path, {
            destination,
            metadata: {
                contentType: 'video/mp4',
                userId: userId,
            },
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