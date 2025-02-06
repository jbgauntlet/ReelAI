//
//  User.swift
//
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct User: Hashable {
    // Basic Info
    var uid: String                // Firebase User ID (required)
    var name: String?             // Display name
    var username: String?         // Unique username
    var email: String?            // Email
    var bio: String?             // User bio
    var avatar: String?          // Avatar URL
    var links: [String]?         // Array of links
    
    // Counters
    var followersCount: Int?
    var followingCount: Int?
    var likesCount: Int?
    var videosCount: Int?
    var friendsCount: Int?
    var commentsCount: Int?
    
    // Metadata
    var createdAt: Date?
    var updatedAt: Date?
    var isEmailVerified: Bool
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)  // Only use uid for hashing since it's unique
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid  // Compare only uids for equality
    }
    
    // Initialize from Firebase User
    init(from firebaseUser: FirebaseAuth.User? = nil) {
        if let firebaseUser = firebaseUser {
            self.uid = firebaseUser.uid
            self.email = firebaseUser.email
            self.name = firebaseUser.displayName
            self.isEmailVerified = firebaseUser.isEmailVerified
            self.createdAt = firebaseUser.metadata.creationDate
            self.updatedAt = firebaseUser.metadata.lastSignInDate
        } else {
            // Default initialization
            self.uid = ""
            self.isEmailVerified = false
        }
    }
    
    // Empty initializer
    init() {
        self.uid = ""
        self.isEmailVerified = false
    }
    
    // Initialize from keychain data
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.name = displayName
        self.isEmailVerified = false  // Default to false when restoring from keychain
    }
    
    // Initialize from Firestore data
    init?(from data: [String: Any], uid: String) {
        self.uid = uid
        self.name = data["name"] as? String
        self.username = data["username"] as? String
        self.email = data["email"] as? String
        self.bio = data["bio"] as? String
        self.avatar = data["avatar"] as? String
        self.links = data["links"] as? [String]
        
        self.followersCount = data["followers_count"] as? Int
        self.followingCount = data["following_count"] as? Int
        self.likesCount = data["likes_count"] as? Int
        self.videosCount = data["videos_count"] as? Int
        self.friendsCount = data["friends_count"] as? Int
        self.commentsCount = data["comments_count"] as? Int
        
        if let timestamp = data["created_at"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        }
        if let timestamp = data["updated_at"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        }
        
        self.isEmailVerified = false  // This comes from Firebase Auth, not Firestore
    }
}
