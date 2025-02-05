import Foundation

enum FieldType: Int {
    case name = 0
    case username = 1
    case bio = 2
    case links = 3
    
    var title: String {
        switch self {
        case .name: return "Name"
        case .username: return "Username"
        case .bio: return "Bio"
        case .links: return "Links"
        }
    }
    
    var placeholder: String {
        switch self {
        case .name: return "Enter your name"
        case .username: return "Enter username"
        case .bio: return "Write a bio"
        case .links: return "Add links"
        }
    }
    
    var characterLimit: Int? {
        switch self {
        case .name: return 50
        case .username: return 30
        case .bio: return 150
        case .links: return nil
        }
    }
    
    var helpText: String? {
        switch self {
        case .name: return "Your name will be visible to other users"
        case .username: return "Username must be unique and contain only letters, numbers, and underscores"
        case .bio: return "Tell others about yourself"
        case .links: return "Add links to your social media profiles"
        }
    }
} 