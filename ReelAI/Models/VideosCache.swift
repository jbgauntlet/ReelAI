import Foundation

/// Manages caching of video metadata and creator information
class VideosCache {
    /// Shared instance for singleton access
    static let shared = VideosCache()
    
    /// Cache of video objects indexed by video ID
    private var videos: [String: Video] = [:]
    
    /// Cache of creator information indexed by user ID
    private var creatorInfo: [String: (username: String, avatarURL: String?)] = [:]
    
    /// Private initializer for singleton pattern
    private init() {}
    
    /// Caches a video object
    /// - Parameter video: The video to cache
    func cacheVideo(_ video: Video) {
        videos[video.id] = video
    }
    
    /// Retrieves a cached video by ID
    /// - Parameter id: The video ID to look up
    /// - Returns: The cached video if found, nil otherwise
    func getVideo(id: String) -> Video? {
        return videos[id]
    }
    
    /// Caches creator information
    /// - Parameters:
    ///   - userId: The creator's user ID
    ///   - username: The creator's username
    ///   - avatarURL: Optional URL to the creator's avatar image
    func cacheCreatorInfo(userId: String, username: String, avatarURL: String?) {
        creatorInfo[userId] = (username, avatarURL)
    }
    
    /// Retrieves cached creator information
    /// - Parameter userId: The creator's user ID
    /// - Returns: Tuple containing username and optional avatar URL if found
    func getCreatorInfo(userId: String) -> (username: String, avatarURL: String?)? {
        return creatorInfo[userId]
    }
    
    /// Clears all cached data
    func clear() {
        videos.removeAll()
        creatorInfo.removeAll()
    }
} 