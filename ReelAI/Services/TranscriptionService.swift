import Foundation
import AVFoundation
import FirebaseFunctions
import FirebaseStorage

class TranscriptionService {
    // MARK: - Properties
    private let functions = Functions.functions()
    
    // MARK: - Initialization
    init() {
        // No need for OpenAI key as we're using Cloud Functions
    }
    
    // MARK: - Public Methods
    func transcribeVideo(_ videoURL: URL, videoId: String) async throws -> String {
        // Extract audio from video
        let audioURL = try await extractAudioFromVideo(videoURL)
        defer { try? FileManager.default.removeItem(at: audioURL) }
        
        // Upload audio to Firebase Storage and get download URL
        let storageURL = try await uploadAudioToStorage(audioURL)
        
        // Call the Cloud Function with both videoUrl and videoId
        let data = [
            "videoUrl": storageURL,
            "videoId": videoId
        ] as [String: Any]
        
        let result = try await functions.httpsCallable("transcribeVideo").call(data)
        
        guard let response = result.data as? [String: Any],
              let transcription = response["text"] as? String else {
            throw TranscriptionError.apiError("Invalid response format")
        }
        
        return transcription
    }
    
    // MARK: - Private Methods
    private func extractAudioFromVideo(_ videoURL: URL) async throws -> URL {
        let asset = AVAsset(url: videoURL)
        
        // Create export session
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw TranscriptionError.audioExtractionFailed
        }
        
        // Set up export
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        
        // Export audio
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw TranscriptionError.audioExtractionFailed
        }
        
        return outputURL
    }
    
    private func uploadAudioToStorage(_ audioURL: URL) async throws -> String {
        let storage = Storage.storage()
        let audioFileName = "transcription_audio/\(UUID().uuidString).m4a"
        let audioRef = storage.reference().child(audioFileName)
        
        _ = try await audioRef.putFile(from: audioURL)
        let downloadURL = try await audioRef.downloadURL()
        return downloadURL.absoluteString
    }
}

// MARK: - Errors
enum TranscriptionError: Error {
    case audioExtractionFailed
    case apiError(String)
} 