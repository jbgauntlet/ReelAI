import FirebaseFirestore

class Conversation {
    let id: String
    let participants: [String]
    let lastMessage: String?
    let lastMessageTimestamp: Date
    let unreadCount: Int
    var otherUserInfo: User?
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let participants = data["participants"] as? [String],
              let timestamp = (data["last_message_timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.participants = participants
        self.lastMessage = data["last_message"] as? String
        self.lastMessageTimestamp = timestamp
        self.unreadCount = (data["unread_count"] as? Int) ?? 0
    }
} 