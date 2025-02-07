import FirebaseFirestore

struct Message {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
    
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let senderId = data["sender_id"] as? String,
              let text = data["text"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.senderId = senderId
        self.text = text
        self.timestamp = timestamp
    }
} 