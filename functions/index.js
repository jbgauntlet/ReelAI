/**
 * Import function triggers from their respective submodules:
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {getStorage} = require("firebase-admin/storage");
const admin = require("firebase-admin");
const {OpenAI} = require("openai");
const fs = require("fs");
const path = require("path");
const os = require("os");

// Initialize admin if not already initialized
if (!admin.apps.length) {
    admin.initializeApp();
}

// Constants
const MAX_RETRIES = 3;

exports.transcribeVideo = onObjectFinalized({
    memory: "1024MiB",
    timeoutSeconds: 540,
    bucket: "reelai-b5b1d.firebasestorage.app",
    filterPattern: "videos/*/*.mp4", // Videos in subfolders
    secrets: ["OPENAI_API_KEY"],
}, async (event) => {
    let videoId;
    let videoDoc;
    
    try {
        const filePath = event.data.name;

        // Extract videoId from the path (it's the filename without .mp4)
        const pathParts = filePath.split("/");
        if (pathParts.length !== 3) {
            console.error("Invalid file path structure:", filePath);
            return;
        }

        videoId = pathParts[2].replace(".mp4", "");

        // Get video document
        videoDoc = await admin.firestore()
            .collection("videos")
            .doc(videoId)
            .get();

        if (!videoDoc.exists) {
            throw new Error("Video document not found");
        }

        const videoData = videoDoc.data();
        if (!videoData) {
            throw new Error("Video data not found");
        }

        // Check if we've exceeded retry attempts
        if (videoData.transcriptionAttempts >= MAX_RETRIES) {
            throw new Error("Maximum transcription attempts exceeded");
        }

        // Update status to processing
        await videoDoc.ref.update({
            transcriptionStatus: "processing",
            transcriptionLastAttempt: admin.firestore.FieldValue.serverTimestamp(),
            transcriptionAttempts: (videoData.transcriptionAttempts || 0) + 1,
        });

        // Get the video file reference
        const storage = getStorage();
        const bucket = storage.bucket(event.data.bucket);
        const file = bucket.file(filePath);

        // Create a temporary file path
        const tempFilePath = path.join(os.tmpdir(), path.basename(filePath));
        console.log(`Downloading video ${videoId} to:`, tempFilePath);

        // Download the file
        await file.download({destination: tempFilePath});
        console.log(`Successfully downloaded video ${videoId}`);

        // Initialize OpenAI
        const openai = new OpenAI({
            apiKey: process.env.OPENAI_API_KEY,
        });

        try {
            // Request transcription
            console.log("Sending to OpenAI for transcription...");
            const transcription = await openai.audio.transcriptions.create({
                file: fs.createReadStream(tempFilePath),
                model: "whisper-1",
                response_format: "verbose_json",
                timestamp_granularities: ["word"]
            });

            // Store the transcription in Firebase
            await videoDoc.ref.update({
                transcriptionStatus: "completed",
                transcriptionText: transcription.text || "",
                transcriptionWords: transcription.words || [],
                transcriptionError: null,
            });

            console.log(`Successfully transcribed video ${videoId}`);
            return {
                success: true,
                transcriptionText: transcription.text,
                transcriptionWords: transcription.words,
            };
        } finally {
            // Clean up temp file
            fs.unlinkSync(tempFilePath);
            console.log(`Cleaned up temporary file for video ${videoId}`);
        }
    } catch (error) {
        console.error("Transcription error:", error);

        // Update document with error if we have a videoId and videoDoc
        if (typeof videoId !== "undefined" && typeof videoDoc !== "undefined") {
            await videoDoc.ref.update({
                transcriptionStatus: "error",
                transcriptionError: error instanceof Error ? error.message : "Unknown error",
            });
        }

        throw new Error(error instanceof Error ? error.message : "Unknown error");
    }
});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//     logger.info("Hello logs!", {structuredData: true});
//     response.send("Hello from Firebase!");
// });
