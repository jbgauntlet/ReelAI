import Foundation
import FirebaseFirestore

struct Notification: Identifiable {
    let id: String
    let userId: String
    let type: String
    let content: String
    let relatedId: String?
    let createdAt: Date
    let read: Bool
    
    init(id: String, userId: String, type: String, content: String, relatedId: String?, createdAt: Date, read: Bool) {
        self.id = id
        self.userId = userId
        self.type = type
        self.content = content
        self.relatedId = relatedId
        self.createdAt = createdAt
        self.read = read
    }
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let userId = data["user_id"] as? String,
              let type = data["type"] as? String,
              let content = data["content"] as? String,
              let createdAtTimestamp = data["created_at"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.type = type
        self.content = content
        self.relatedId = data["related_id"] as? String
        self.createdAt = createdAtTimestamp.dateValue()
        self.read = data["read"] as? Bool ?? false
    }
} 