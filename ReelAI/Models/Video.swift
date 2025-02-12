import Foundation
import FirebaseFirestore

/// Metadata for video interactions and creator info
struct VideoMetadata {
    let creatorUsername: String
    let creatorAvatarURL: String?
    var likesCount: Int
    var bookmarksCount: Int
    var commentsCount: Int
    var isLikedByCurrentUser: Bool
    var isBookmarkedByCurrentUser: Bool
}

class Video: Identifiable {
    // MARK: - Properties
    let id: String
    let creatorId: String
    let storagePath: String
    let caption: String?
    let title: String?
    let tags: [String]?
    
    // Transcription
    var transcription: String?
    var transcriptionStatus: TranscriptionStatus
    var transcriptionError: String?
    var doTranscribe: Bool
    
    // Pattern
    var pattern: String?
    var parseStatus: ParseStatus?
    var parseError: String?
    var patternJson: [String: Any]?
    
    // Counters
    var viewsCount: Int
    private(set) var likesCount: Int
    private(set) var commentsCount: Int
    private(set) var bookmarksCount: Int
    
    // Metadata
    let createdAt: Date
    var updatedAt: Date
    
    // User interaction state
    private var metadata: VideoMetadata?
    
    // MARK: - Computed Properties
    var creatorUsername: String { metadata?.creatorUsername ?? "" }
    var creatorAvatarURL: String? { metadata?.creatorAvatarURL }
    var isLikedByCurrentUser: Bool { metadata?.isLikedByCurrentUser ?? false }
    var isBookmarkedByCurrentUser: Bool { metadata?.isBookmarkedByCurrentUser ?? false }
    
    // MARK: - Initializers
    init(id: String,
         creatorId: String,
         storagePath: String,
         caption: String? = nil,
         title: String? = nil,
         tags: [String]? = nil,
         transcription: String? = nil,
         transcriptionStatus: TranscriptionStatus = .pending,
         transcriptionError: String? = nil,
         doTranscribe: Bool = false,
         pattern: String? = nil,
         parseStatus: ParseStatus? = nil,
         parseError: String? = nil,
         patternJson: [String: Any]? = nil,
         viewsCount: Int = 0,
         likesCount: Int = 0,
         commentsCount: Int = 0,
         bookmarksCount: Int = 0,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.creatorId = creatorId
        self.storagePath = storagePath
        self.caption = caption
        self.title = title
        self.tags = tags
        self.transcription = transcription
        self.transcriptionStatus = transcriptionStatus
        self.transcriptionError = transcriptionError
        self.doTranscribe = doTranscribe
        self.pattern = pattern
        self.parseStatus = parseStatus
        self.parseError = parseError
        self.patternJson = patternJson
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.bookmarksCount = bookmarksCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Initialize from Firestore document
    init?(from document: DocumentSnapshot) {
        guard
            let data = document.data(),
            let creatorId = data["creator_id"] as? String,
            let storagePath = data["storage_path"] as? String,
            let createdAtTimestamp = data["created_at"] as? Timestamp
        else {
            return nil
        }
        
        self.id = document.documentID
        self.creatorId = creatorId
        self.storagePath = storagePath
        self.caption = data["caption"] as? String
        self.title = data["title"] as? String
        self.tags = data["tags"] as? [String]
        self.transcription = data["transcriptionText"] as? String
        self.transcriptionStatus = TranscriptionStatus(rawValue: data["transcriptionStatus"] as? String ?? "") ?? .pending
        self.transcriptionError = data["transcription_error"] as? String
        self.doTranscribe = data["do_transcribe"] as? Bool ?? false
        self.pattern = data["pattern"] as? String
        self.parseStatus = ParseStatus(rawValue: data["parse_status"] as? String ?? "")
        self.parseError = data["parse_error"] as? String
        self.patternJson = data["pattern_json"] as? [String: Any]
        self.createdAt = createdAtTimestamp.dateValue()
        self.viewsCount = (data["views_count"] as? Int) ?? 0
        self.likesCount = (data["likes_count"] as? Int) ?? 0
        self.commentsCount = (data["comments_count"] as? Int) ?? 0
        self.bookmarksCount = (data["bookmarks_count"] as? Int) ?? 0
        
        if let timestamp = data["updated_at"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
    
    // MARK: - Metadata Management
    
    /// Updates the video's metadata with creator info and interaction states
    /// - Parameter metadata: The new metadata to apply
    func updateMetadata(_ metadata: VideoMetadata) {
        self.metadata = metadata
        self.likesCount = metadata.likesCount
        self.bookmarksCount = metadata.bookmarksCount
        self.commentsCount = metadata.commentsCount
    }
    
    /// Updates the like status and count
    /// - Parameter isLiked: The new like state
    func updateLikeStatus(isLiked: Bool) {
        guard var currentMetadata = metadata else { return }
        currentMetadata.isLikedByCurrentUser = isLiked
        currentMetadata.likesCount += isLiked ? 1 : -1
        self.likesCount = currentMetadata.likesCount
        self.metadata = currentMetadata
    }
    
    /// Updates the bookmark status and count
    /// - Parameter isBookmarked: The new bookmark state
    func updateBookmarkStatus(isBookmarked: Bool) {
        guard var currentMetadata = metadata else { return }
        currentMetadata.isBookmarkedByCurrentUser = isBookmarked
        currentMetadata.bookmarksCount += isBookmarked ? 1 : -1
        self.bookmarksCount = currentMetadata.bookmarksCount
        self.metadata = currentMetadata
    }
    
    /// Updates the comment count
    /// - Parameter delta: The change in comment count (positive or negative)
    func updateCommentCount(delta: Int) {
        guard var currentMetadata = metadata else { return }
        currentMetadata.commentsCount += delta
        self.commentsCount = currentMetadata.commentsCount
        self.metadata = currentMetadata
    }
    
    // MARK: - Transcription Management
    func updateTranscription(_ transcription: String) {
        self.transcription = transcription
        self.transcriptionStatus = .completed
    }
    
    func setTranscriptionFailed() {
        self.transcriptionStatus = .failed
    }
    
    // MARK: - Firestore Data
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "creator_id": creatorId,
            "storage_path": storagePath,
            "views_count": viewsCount,
            "likes_count": likesCount,
            "comments_count": commentsCount,
            "bookmarks_count": bookmarksCount,
            "created_at": Timestamp(date: createdAt),
            "updated_at": Timestamp(date: updatedAt),
            "transcriptionStatus": transcriptionStatus.rawValue,
            "do_transcribe": doTranscribe
        ]
        
        // Add optional fields if they exist
        if let caption = caption { data["caption"] = caption }
        if let title = title { data["title"] = title }
        if let tags = tags { data["tags"] = tags }
        if let transcription = transcription { data["transcriptionText"] = transcription }
        if let transcriptionError = transcriptionError { data["transcription_error"] = transcriptionError }
        if let pattern = pattern { data["pattern"] = pattern }
        if let parseStatus = parseStatus { data["parse_status"] = parseStatus.rawValue }
        if let parseError = parseError { data["parse_error"] = parseError }
        if let patternJson = patternJson { data["pattern_json"] = patternJson }
        
        return data
    }
}

// MARK: - TranscriptionStatus
enum TranscriptionStatus: String {
    case pending
    case processing
    case completed
    case failed
}

// MARK: - ParseStatus
enum ParseStatus: String {
    case pending
    case completed
    case failed
} 