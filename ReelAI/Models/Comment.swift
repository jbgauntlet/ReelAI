import UIKit
import FirebaseFirestore

struct Comment {
    let id: String
    let videoId: String
    let userId: String
    let text: String
    let createdAt: Date
    
    init?(from document: QueryDocumentSnapshot) {
        guard let videoId = document.data()["video_id"] as? String,
              let userId = document.data()["user_id"] as? String,
              let text = document.data()["text"] as? String,
              let timestamp = document.data()["created_at"] as? Timestamp else {
            return nil
        }
        
        self.id = document.documentID
        self.videoId = videoId
        self.userId = userId
        self.text = text
        self.createdAt = timestamp.dateValue()
    }
    
    // Add initializer for local comment creation
    init(id: String, videoId: String, userId: String, text: String, createdAt: Date) {
        self.id = id
        self.videoId = videoId
        self.userId = userId
        self.text = text
        self.createdAt = createdAt
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .weekOfYear], from: self, to: now)
        
        if let weeks = components.weekOfYear, weeks >= 1 {
            return "\(weeks)w"
        }
        if let days = components.day, days >= 1 {
            return "\(days)d"
        }
        if let hours = components.hour, hours >= 1 {
            return "\(hours)h"
        }
        if let minutes = components.minute, minutes >= 1 {
            return "\(minutes)m"
        }
        if let seconds = components.second, seconds >= 3 {
            return "\(seconds)s"
        }
        return "now"
    }
}
