import Foundation
import FirebaseFirestore

struct Video: Identifiable {
    // MARK: - Properties
    let id: String
    let creatorId: String
    let storagePath: String
    let caption: String?
    let title: String?
    let tags: [String]?
    
    // Counters
    var viewsCount: Int
    var likesCount: Int
    var commentsCount: Int
    var bookmarksCount: Int
    
    // Metadata
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initializers
    init(id: String,
         creatorId: String,
         storagePath: String,
         caption: String? = nil,
         title: String? = nil,
         tags: [String]? = nil,
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
            let title = data["title"] as? String,
            let caption = data["caption"] as? String,
            let storagePath = data["storage_path"] as? String,
            let createdAtTimestamp = data["created_at"] as? Timestamp
        else {
            return nil
        }
        
        self.id = document.documentID
        self.creatorId = creatorId
        self.storagePath = storagePath
        self.caption = caption
        self.title = title
        self.tags = data["tags"] as? [String]
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
            "updated_at": Timestamp(date: updatedAt)
        ]
        
        // Add optional fields if they exist
        if let caption = caption { data["caption"] = caption }
        if let title = title { data["title"] = title }
        if let tags = tags { data["tags"] = tags }
        
        return data
    }
} 