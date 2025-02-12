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
const VALID_PATTERNS = ["workout", "recipe", "tutorial"];

// Pattern-specific prompts
const PATTERN_PROMPTS = {
    workout: `You are a workout analyzer. Given a transcript of a workout video, create a structured JSON with the following format:
{
    "type": "workout",
    "exercises": [
        {
            "name": string,
            "sets": number,
            "reps": number,
            "weight": string,
            "duration": string,
            "intensity": string,
            "rest_duration": string
        }
    ]
}


If the transcript doesn't contain a proper workout instruction, return: { "error": "Not a valid workout" }
Don't make any exercises up and stay true as best as possible to the transcription.
If something is explicity mentioned don't change it. 
When possible use any additional context to fill in gaps.
The output should be a properly formatted json object with these attributes.
Don't include attributes that are not needed. For example if sets and reps are present and no duration is mentioned then don't come up with a random duration.
All fields are not required.

Transcript:
`,
    recipe: `You are a recipe analyzer. Given a transcript of a cooking video, create a structured JSON with the following format:
{
    "type": "recipe",
    "name": string,
    "ingredients": [
        {
            "item": string,
            "amount": string,
            "unit": string
        }
    ],
    "steps": string[],
    "prepTime": string,
    "cookTime": string,
    "servings": number
}

If the transcript doesn't contain a proper recipe instruction, return: { "error": "Not a valid recipe" }
Don't make any recipes up and stay true as best as possible to the transcription.
If something is explicity mentioned don't change it. 
When possible use any additional context to fill in gaps.
The output should be a properly formatted json object with these attributes.
Don't include attributes that are not needed. For example if item and amount are present and no unit is mentioned then don't come up with a random unit.
All fields are not required.

Transcript:
`,
    tutorial: `You are a tutorial analyzer. Given a transcript of a tutorial video, create a structured JSON with the following format:
{
    "type": "tutorial",
    "subject": string,
    "steps": [
        {
            "title": string,
            "description": string,
            "duration": string
        }
    ]
}

If the transcript doesn't contain a proper tutorial instruction, return: { "error": "Not a valid tutorial" }
Don't make any steps up and stay true as best as possible to the transcription.
If something is explicity mentioned don't change it. 
When possible use any additional context to fill in gaps.
The output should be a properly formatted json object with these attributes.
Don't include attributes that are not needed. For example if title and description are present and no duration is mentioned then don't come up with a random duration.
All fields are not required.

Transcript:
`
};

/**
 * Parses a transcription using a specific pattern template through GPT.
 * @param {string} pattern - The pattern type to use (workout, recipe, or tutorial).
 * @param {string} transcriptionText - The text to analyze.
 * @return {Promise<Object>} The parsed JSON result or error object.
 */
async function parseTranscriptionPattern(pattern, transcriptionText) {
    const openai = new OpenAI({
        apiKey: process.env.OPENAI_API_KEY,
    });

    const prompt = PATTERN_PROMPTS[pattern] + transcriptionText;

    const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo-1106",
        messages: [
            {
                role: "system",
                content: "You are a specialized content parser that converts video transcripts into structured data. Be precise and strict about following the required JSON format.",
            },
            {
                role: "user",
                content: prompt,
            },
        ],
        response_format: {type: "json_object"},
        temperature: 0.3
    });

    return JSON.parse(completion.choices[0].message.content);
}

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

        // Check if transcription is requested
        if (!videoData.do_transcribe) {
            console.log(`Transcription not requested for video ${videoId}`);
            return;
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
            const updateData = {
                transcriptionStatus: "completed",
                transcriptionText: transcription.text || "",
                transcriptionWords: transcription.words || [],
                transcriptionError: null,
            };

            // If a valid pattern is specified, process it
            if (videoData.pattern && VALID_PATTERNS.includes(videoData.pattern)) {
                console.log(`Processing pattern ${videoData.pattern} for video ${videoId}`);
                try {
                    const patternJson = await parseTranscriptionPattern(
                        videoData.pattern,
                        transcription.text
                    );

                    if (patternJson.error) {
                        updateData.parse_status = "failed";
                        updateData.parse_error = patternJson.error;
                    } else {
                        updateData.parse_status = "completed";
                        updateData.pattern_json = patternJson;
                    }
                } catch (parseError) {
                    console.error(`Pattern parsing error for video ${videoId}:`, parseError);
                    updateData.parse_status = "failed";
                    updateData.parse_error = parseError.message;
                }
            }

            await videoDoc.ref.update(updateData);

            console.log(`Successfully processed video ${videoId}`);
            return {
                success: true,
                transcriptionText: transcription.text,
                transcriptionWords: transcription.words,
                pattern_json: updateData.pattern_json
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
