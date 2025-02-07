import UIKit
import AVFoundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - Video Cache Manager
/**
 * VideoCache is a singleton class responsible for managing video asset caching.
 * It provides both memory and disk caching capabilities for AVURLAssets to improve
 * video loading performance and reduce network usage.
 */
class VideoCache {
    static let shared = VideoCache()
    private let cache = NSCache<NSString, AVURLAsset>()  // Cache AVURLAsset instead of AVPlayerItem
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 500 * 1024 * 1024  // 500MB
    
    /// Private initializer for singleton pattern
    private init() {
        // Set up cache directory in user's domain
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, 
                                      withIntermediateDirectories: true)
        
        // Configure cache limits
        cache.countLimit = 3  // Maximum number of items in memory cache
        cache.totalCostLimit = 250 * 1024 * 1024  // 250MB memory cache limit
        
        // Clean up old cache files on initialization
        cleanOldCacheFiles()
    }
    

    
    /// Cleans up old cache files to maintain size limit
    func cleanOldCacheFiles() {
        do {
            // Get all files in cache directory with their properties
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, 
                                                          includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            // Sort files by creation date (oldest first)
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1! < date2!
            }
            
            // Calculate total size and remove old files if exceeding limit
            var totalSize: Int64 = 0
            for file in sortedFiles {
                let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                totalSize += Int64(size)
                
                // Remove old files if exceeding max cache size
                if totalSize > maxCacheSize {
                    try? fileManager.removeItem(at: file)
                    print("🗑️ Removed old cache file: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("❌ Error cleaning cache: \(error)")
        }
    }
    
    /// Clears all cached assets from memory and disk
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, 
                                      withIntermediateDirectories: true)
    }
    
    /// Returns an AVPlayerItem for the given URL, using cached asset if available
    /// - Parameter url: The URL of the video
    /// - Returns: An AVPlayerItem configured with the video asset
    func playerItem(for url: URL) -> AVPlayerItem {
        let cacheKey = NSString(string: url.absoluteString)
        
        // Get or create asset
        let asset: AVURLAsset
        if let cachedAsset = cache.object(forKey: cacheKey) {
            print("📦 Found video asset in memory cache")
            asset = cachedAsset
        } else {
            print("🔄 Creating new video asset")
            // Create new asset with optimized loading options
            asset = AVURLAsset(url: url, options: [
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
                "AVURLAssetHTTPHeaderFieldsKey": ["Accept": "video/mp4"]
            ])
            cache.setObject(asset, forKey: cacheKey)
        }
        
        // Create new player item from asset
        return AVPlayerItem(asset: asset)
    }
    
    /// Caches an asset in memory for quick access
    /// - Parameters:
    ///   - asset: The AVURLAsset to cache
    ///   - key: The key to store the asset under
    func cacheAsset(_ asset: AVURLAsset, forKey key: String) {
        cache.setObject(asset, forKey: NSString(string: key))
    }
}

// MARK: - FullScreenVideoCell
/**
 * FullScreenVideoCell is a custom UICollectionViewCell that displays a full-screen video
 * with playback controls and interactive elements like likes, comments, and bookmarks.
 */
class FullScreenVideoCell: UICollectionViewCell {
    // Cell identifier for registration and dequeuing
    static let identifier = "FullScreenVideoCell"
    
    // Unique identifier for logging and debugging
    private var cellId = UUID().uuidString
    
    // MARK: - UI Components
    
    /// Main view for displaying video content
    private let playerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Activity indicator shown during video loading
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Action Bar UI Components
    
    /// Container view for action buttons (like, comment, share)
    private let actionBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    /// Button displaying creator's avatar/profile picture
    private let creatorAvatarButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        button.imageView?.contentMode = .scaleAspectFill
        button.contentMode = .scaleAspectFill
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    /// Button for liking/unliking the video
    private let likeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        button.setImage(UIImage(systemName: "heart.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let commentButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        button.setImage(UIImage(systemName: "bubble.right.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let bookmarkButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        button.setImage(UIImage(systemName: "bookmark.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.right.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let likeCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let commentCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bookmarkCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Info Panel UI Components
    private let infoPanelView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let captionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let tagsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    weak var delegate: FullScreenVideoCellDelegate?
    var currentVideo: Video?
    
    // MARK: - Setup Methods
    
    /// Initializes and sets up the cell's UI components
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("📱 VideoCell initialized with ID: \(cellId)")
        setupUI()
        setupActionBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Sets up the main UI components and constraints
    private func setupUI() {
        // Configure content view to fill the cell
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add and configure main components
        contentView.addSubview(playerView)
        contentView.addSubview(loadingIndicator)
        setupInfoPanel()
        
        // Set up constraints
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    /// Sets up the info panel containing video title, caption, and tags
    private func setupInfoPanel() {
        contentView.addSubview(infoPanelView)
        
        // Add info panel components
        infoPanelView.addSubview(titleLabel)
        infoPanelView.addSubview(captionLabel)
        infoPanelView.addSubview(tagsLabel)
        
        // Configure info panel constraints
        NSLayoutConstraint.activate([
            infoPanelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoPanelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            infoPanelView.widthAnchor.constraint(equalToConstant: 300),
            infoPanelView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: infoPanelView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: infoPanelView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: infoPanelView.trailingAnchor),
            
            captionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            captionLabel.leadingAnchor.constraint(equalTo: infoPanelView.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: infoPanelView.trailingAnchor),
            
            tagsLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 8),
            tagsLabel.leadingAnchor.constraint(equalTo: infoPanelView.leadingAnchor),
            tagsLabel.trailingAnchor.constraint(equalTo: infoPanelView.trailingAnchor)
        ])
    }
    
    /// Sets up the action bar containing interaction buttons
    private func setupActionBar() {
        contentView.addSubview(actionBarView)
        
        // Add action buttons
        actionBarView.addSubview(creatorAvatarButton)
        actionBarView.addSubview(likeButton)
        actionBarView.addSubview(commentButton)
        actionBarView.addSubview(bookmarkButton)
        actionBarView.addSubview(shareButton)
        
        // Add count labels
        actionBarView.addSubview(likeCountLabel)
        actionBarView.addSubview(commentCountLabel)
        actionBarView.addSubview(bookmarkCountLabel)
        
        // Configure action bar constraints
        NSLayoutConstraint.activate([
            actionBarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            actionBarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            actionBarView.widthAnchor.constraint(equalToConstant: 80),
            actionBarView.heightAnchor.constraint(equalToConstant: 400),
            
            creatorAvatarButton.topAnchor.constraint(equalTo: actionBarView.topAnchor),
            creatorAvatarButton.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            creatorAvatarButton.widthAnchor.constraint(equalToConstant: 50),
            creatorAvatarButton.heightAnchor.constraint(equalToConstant: 50),
            
            likeButton.topAnchor.constraint(equalTo: creatorAvatarButton.bottomAnchor, constant: 20),
            likeButton.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            
            likeCountLabel.topAnchor.constraint(equalTo: likeButton.bottomAnchor, constant: 4),
            likeCountLabel.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            
            commentButton.topAnchor.constraint(equalTo: likeCountLabel.bottomAnchor, constant: 20),
            commentButton.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            
            commentCountLabel.topAnchor.constraint(equalTo: commentButton.bottomAnchor, constant: 4),
            commentCountLabel.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            
            bookmarkButton.topAnchor.constraint(equalTo: commentCountLabel.bottomAnchor, constant: 20),
            bookmarkButton.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            
            bookmarkCountLabel.topAnchor.constraint(equalTo: bookmarkButton.bottomAnchor, constant: 4),
            bookmarkCountLabel.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor),
            
            shareButton.topAnchor.constraint(equalTo: bookmarkCountLabel.bottomAnchor, constant: 20),
            shareButton.centerXAnchor.constraint(equalTo: actionBarView.centerXAnchor)
        ])
        
        // Configure button actions
        creatorAvatarButton.addTarget(self, action: #selector(creatorAvatarTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }
    
    // MARK: - Video Configuration Methods
    
    /// Configures the cell with a video model
    /// - Parameter video: The video model to display
    func configure(with video: Video) {
        currentVideo = video
        
        // Configure video player if URL is valid
        guard let videoURL = URL(string: video.storagePath) else { return }
        configureVideo(with: videoURL)
        
        // Update UI components
        updateActionBar(with: video)
        
        // Update info panel content
        titleLabel.text = video.title
        captionLabel.text = video.caption
        // Format and display tags if available
        if let tags = video.tags {
            tagsLabel.text = tags.map { "#\($0)" }.joined(separator: " ")
        } else {
            tagsLabel.text = ""
        }
    }
    
    /// Formats a number for display (e.g., 1000 -> 1K)
    /// - Parameter count: The number to format
    /// - Returns: Formatted string representation
    private func formatCount(_ count: Int) -> String {
        switch count {
        case 0..<1000:
            return "\(count)"
        case 1000..<1_000_000:
            let k = Double(count) / 1000.0
            return String(format: "%.1fK", k)
        default:
            let m = Double(count) / 1_000_000.0
            return String(format: "%.1fM", m)
        }
    }
    
    /// Updates the action bar UI components with video data
    /// - Parameter video: The video model containing the data
    private func updateActionBar(with video: Video) {
        // Fetch and update interaction states and counts
        fetchLikeStatus(for: video)
        fetchLikesCount(for: video)
        fetchCommentsCount(for: video)
        fetchBookmarkStatus(for: video)
        fetchBookmarksCount(for: video)
        fetchCreatorAvatar(for: video)
    }
    
    /// Configures the video player with the provided URL
    /// - Parameter url: The URL of the video to play
    private func configureVideo(with url: URL) {
        print("🎬 Configuring cell \(cellId) with video URL: \(url.lastPathComponent)")
        loadingIndicator.startAnimating()
        
        // Get cached player item
        let playerItem = VideoCache.shared.playerItem(for: url)
        
        // Create and configure player
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        
        // Configure player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = playerView.bounds
        self.playerLayer = playerLayer
        
        // Update layer hierarchy
        playerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        playerView.layer.addSublayer(playerLayer)
        
        // Ensure proper layout
        layoutIfNeeded()
        
        // Add observers for playback events
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(playerItemDidReachEnd),
                                             name: .AVPlayerItemDidPlayToEndTime,
                                             object: playerItem)
        
        playerItem.addObserver(self,
                             forKeyPath: "status",
                             options: [.new, .old],
                             context: nil)
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to set audio session category: \(error)")
        }
        
        loadingIndicator.stopAnimating()
        print("🎥 Player setup complete for cell \(cellId)")
    }
    
    // MARK: - Lifecycle Methods
    
    /// Updates layout when cell bounds change
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update frames only if they've changed
        if contentView.frame != bounds {
            contentView.frame = bounds
        }
        
        if playerView.frame != contentView.bounds {
            playerView.frame = contentView.bounds
        }
        
        if playerLayer?.frame != playerView.bounds {
            playerLayer?.frame = playerView.bounds
            print("🎞️ Updated player layer frame to: \(playerView.bounds)")
        }
    }
    
    /// Handles player status changes
    override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "status",
           let item = object as? AVPlayerItem {
            switch item.status {
            case .readyToPlay:
                print("✅ Player ready to play in cell \(cellId)")
            case .failed:
                print("❌ Player failed in cell \(cellId): \(String(describing: item.error))")
            case .unknown:
                print("❓ Player status unknown in cell \(cellId)")
            @unknown default:
                break
            }
        }
    }
    
    /// Handles video playback completion
    @objc private func playerItemDidReachEnd() {
        print("🔄 Video reached end in cell \(cellId), looping...")
        restart()  // Use restart instead of seeking and playing separately
    }
    
    /// Restarts video from beginning and plays
    func restart() {
        print("🔄 Restarting video in cell \(cellId)")
        player?.seek(to: .zero)
        player?.play()
    }
    
    /// Starts video playback
    func play() {
        print("▶️ Playing video in cell \(cellId)")
        player?.play()
    }
    
    /// Pauses video playback
    func pause() {
        print("⏸️ Pausing video in cell \(cellId)")
        player?.pause()
    }
    
    /// Prepares the cell for reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        print("♻️ Preparing cell \(cellId) for reuse")
        
        // Clean up video playback resources
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        // Remove observers
        NotificationCenter.default.removeObserver(self)
        
        // Clear current video
        currentVideo = nil
        
        // Clean up UI
        creatorAvatarButton.subviews.forEach { $0.removeFromSuperview() }
    }
    
    /// Cleanup when cell is deallocated
    deinit {
        print("🗑️ VideoCell \(cellId) being deallocated")
    }
    
    // MARK: - Firebase Interaction Methods
    
    /// Fetches and updates the like status for a video
    /// - Parameter video: The video to check like status for
    private func fetchLikeStatus(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
        
        likeRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // Update like button appearance based on like status
            if snapshot?.exists == true {
                self.animateLikeButton(isLiked: true)
            } else {
                self.animateLikeButton(isLiked: false)
            }
        }
    }
    
    /// Animates the like button state change
    /// - Parameter isLiked: Whether the video is liked
    func animateLikeButton(isLiked: Bool) {
        // Scale down animation
        UIView.animate(withDuration: 0.15, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            // Scale up and color change animation
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.likeButton.transform = CGAffineTransform.identity
                self.likeButton.tintColor = isLiked ? .systemRed : .white
            }
        }
    }
    
    /// Fetches and updates the likes count for a video
    /// - Parameter video: The video to fetch likes count for
    func fetchLikesCount(for video: Video) {
        let db = Firestore.firestore()
        db.collection("video_likes")
            .whereField("video_id", isEqualTo: video.id)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching likes: \(error)")
                    return
                }
                
                // Update UI with likes count
                let likesCount = snapshot?.documents.count ?? 0
                self.likeCountLabel.text = "\(likesCount)"
                
                // Update video document if count has changed
                if likesCount != video.likesCount {
                    db.collection("videos").document(video.id).updateData([
                        "likes_count": likesCount
                    ])
                }
            }
    }
    
    /// Fetches and updates the bookmark status for a video
    /// - Parameter video: The video to check bookmark status for
    func fetchBookmarkStatus(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let bookmarkRef = db.collection("video_bookmarks").document("\(video.id)_\(currentUserId)")
        
        bookmarkRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // Update bookmark button appearance based on bookmark status
            if snapshot?.exists == true {
                self.animateBookmarkButton(isBookmarked: true)
            } else {
                self.animateBookmarkButton(isBookmarked: false)
            }
        }
    }
    
    /// Animates the bookmark button state change
    /// - Parameter isBookmarked: Whether the video is bookmarked
    func animateBookmarkButton(isBookmarked: Bool) {
        // Scale down animation
        UIView.animate(withDuration: 0.15, animations: {
            self.bookmarkButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            // Scale up and color change animation
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.bookmarkButton.transform = CGAffineTransform.identity
                self.bookmarkButton.tintColor = isBookmarked ? .systemYellow : .white
            }
        }
    }
    
    /// Fetches and updates the bookmarks count for a video
    /// - Parameter video: The video to fetch bookmarks count for
    func fetchBookmarksCount(for video: Video) {
        let db = Firestore.firestore()
        db.collection("video_bookmarks")
            .whereField("video_id", isEqualTo: video.id)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching bookmarks: \(error)")
                    return
                }
                
                // Update UI with bookmarks count
                let bookmarksCount = snapshot?.documents.count ?? 0
                self.bookmarkCountLabel.text = "\(bookmarksCount)"
                
                // Update video document if count has changed
                if bookmarksCount != video.bookmarksCount {
                    db.collection("videos").document(video.id).updateData([
                        "bookmarks_count": bookmarksCount
                    ])
                }
            }
    }
    
    /// Fetches and displays the creator's avatar
    /// - Parameter video: The video whose creator's avatar to fetch
    private func fetchCreatorAvatar(for video: Video) {
        let db = Firestore.firestore()
        
        // Fetch creator's user data
        db.collection("users").document(video.creatorId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let username = data["username"] as? String else {
                return
            }
            
            if let avatarUrl = data["avatar"] as? String,
               let url = URL(string: avatarUrl) {
                // Fetch avatar image
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let error = error {
                        print("Error loading avatar: \(error.localizedDescription)")
                        // Fall back to default avatar on error
                        DispatchQueue.main.async {
                            self?.setupDefaultAvatar(with: username)
                        }
                        return
                    }
                    
                    if let data = data,
                       let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            // Update avatar button with fetched image
                            self?.updateAvatarWithImage(image)
                        }
                    } else {
                        // Fall back to default avatar if image data is invalid
                        DispatchQueue.main.async {
                            self?.setupDefaultAvatar(with: username)
                        }
                    }
                }.resume()
            } else {
                // No avatar URL, use default avatar
                self.setupDefaultAvatar(with: username)
            }
        }
    }
    
    /// Updates the avatar button with an image
    /// - Parameter image: The image to display
    private func updateAvatarWithImage(_ image: UIImage) {
        // Clear existing content
        creatorAvatarButton.subviews.forEach { $0.removeFromSuperview() }
        creatorAvatarButton.backgroundColor = .clear
        
        // Create and configure image view
        let imageView = UIImageView(frame: creatorAvatarButton.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.image = image
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add image view to button
        creatorAvatarButton.addSubview(imageView)
    }
    
    /// Sets up a default avatar with the user's first initial
    /// - Parameter username: The username to use for the avatar
    private func setupDefaultAvatar(with username: String) {
        // Clear existing content
        creatorAvatarButton.setImage(nil, for: .normal)
        creatorAvatarButton.subviews.forEach { $0.removeFromSuperview() }
        
        // Create label with first initial
        let firstLetter = String(username.prefix(1)).uppercased()
        let label = UILabel()
        label.text = firstLetter
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .medium)
        
        // Generate consistent background color based on username
        let hash = abs(username.hashValue)
        let hue = CGFloat(hash % 360) / 360.0
        creatorAvatarButton.backgroundColor = UIColor(hue: hue, saturation: 0.8, brightness: 0.8, alpha: 1.0)
        
        // Add and constrain the label
        creatorAvatarButton.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: creatorAvatarButton.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: creatorAvatarButton.centerYAnchor)
        ])
    }
    
    // MARK: - Action Methods
    
    /// Handles tap on creator's avatar
    @objc private func creatorAvatarTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapCreatorAvatar(for: video)
    }
    
    /// Handles tap on like button
    @objc private func likeTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapLike(for: video)
    }
    
    /// Handles tap on comment button
    @objc private func commentTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapComment(for: video)
    }
    
    /// Handles tap on bookmark button
    @objc private func bookmarkTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapBookmark(for: video)
    }
    
    /// Handles tap on share button
    @objc private func shareTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapShare(for: video)
    }
    
    /// Fetches and updates the comments count for a video
    private func fetchCommentsCount(for video: Video) {
        let db = Firestore.firestore()
        db.collection("video_comments")
            .whereField("video_id", isEqualTo: video.id)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                let count = snapshot?.documents.count ?? 0
                DispatchQueue.main.async {
                    self.commentCountLabel.text = "\(count)"
                }
            }
    }
}

// MARK: - FullScreenVideoCellDelegate Protocol
/// Protocol defining the interface for handling user interactions with video cells
protocol FullScreenVideoCellDelegate: AnyObject {
    /// Called when the creator's avatar is tapped
    func didTapCreatorAvatar(for video: Video)
    /// Called when the like button is tapped
    func didTapLike(for video: Video)
    /// Called when the comment button is tapped
    func didTapComment(for video: Video)
    /// Called when the bookmark button is tapped
    func didTapBookmark(for video: Video)
    /// Called when the share button is tapped
    func didTapShare(for video: Video)
}

// MARK: - VideoLoadingWindow Implementation
/// Manages the window of videos that should be kept loaded in memory
struct VideoLoadingWindow {
    /// Number of videos to keep loaded (current + adjacent)
    static let windowSize = 5
    
    /// Current center index of the window
    let centerIndex: Int
    
    /// Range of indices that should be kept loaded
    var indexRange: Range<Int> {
        let start = max(0, centerIndex - VideoLoadingWindow.windowSize/2)
        let end = centerIndex + VideoLoadingWindow.windowSize/2
        return start..<end
    }
    
    /// Determines if a video at the given index should be kept loaded
    /// - Parameters:
    ///   - index: The index to check
    ///   - totalCount: Total number of videos
    /// - Returns: Whether the video should be kept loaded
    func shouldKeepLoaded(index: Int, totalCount: Int) -> Bool {
        guard index >= 0 && index < totalCount else { return false }
        return abs(index - centerIndex) <= VideoLoadingWindow.windowSize/2
    }
}

// MARK: - VideoScrollContentViewController Implementation
class VideoScrollContentViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - Properties
    
    /// Array of videos to display
    private var videos: [Video] = []
    
    /// Currently playing video cell
    private var currentlyPlayingCell: FullScreenVideoCell?
    
    /// Cache for prefetched video assets
    private var prefetchedAssets: [String: AVURLAsset] = [:]
    
    /// Current loading window for memory optimization
    private var loadingWindow: VideoLoadingWindow?
    
    /// Timestamp of last cleanup operation
    private var lastCleanupTime: Date = Date()
    
    /// Interval between cleanup operations
    private var cleanupInterval: TimeInterval = 2.0
    
    // MARK: - Pagination Properties
    
    /// Listener for real-time video updates
    private var videosListener: ListenerRegistration?
    
    /// Last document fetched for pagination
    private var lastDocument: DocumentSnapshot?
    
    /// Number of videos to fetch per batch
    private let batchSize = 3
    
    /// Flag indicating if more videos are being loaded
    private var isLoadingMore = false
    
    /// Flag indicating if there are more videos to load
    private var hasMoreVideos = true
    
    // MARK: - Memory Management Properties
    
    /// Timer for logging memory usage
    private var memoryUsageLogger: Timer?
    
    /// Maximum memory threshold (300MB)
    private let maxMemoryThreshold: UInt64 = 300 * 1024 * 1024
    
    // MARK: - UI Components
    
    /// Collection view for displaying videos
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.backgroundColor = .black
        cv.showsVerticalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .never
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 VideoScrollContentViewController loaded")
        
        // Hide navigation bar to get full screen
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Extend layout under safe areas
        edgesForExtendedLayout = .all
        
        setupMemoryMonitoring()
        setupUI()
        setupCollectionView()
        fetchVideos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Configure visible cells
        if let visibleIndexPath = collectionView.indexPathsForVisibleItems.first {
            print("\n🔄 View appearing, configuring visible cell at index \(visibleIndexPath.item)")
            configureVideoCell(at: visibleIndexPath)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add collection view with full screen constraints
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor) // Reset to full height
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.register(FullScreenVideoCell.self, forCellWithReuseIdentifier: FullScreenVideoCell.identifier)
        print("🎯 CollectionView setup complete")
    }
    
    private func fetchVideos(isInitialFetch: Bool = true) {
        guard !isLoadingMore && (isInitialFetch || hasMoreVideos) else { return }
        
        isLoadingMore = true
        print("\n🔍 ====== FETCHING VIDEOS ======")
        print("🔍 Starting to fetch videos from Firestore")
        
        let db = Firestore.firestore()
        var query = db.collection("videos")
            .order(by: "created_at", descending: true)
            .limit(to: batchSize)
        
        // If not initial fetch, start after the last document
        if !isInitialFetch, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        // Remove previous listener if this is an initial fetch
        if isInitialFetch {
            videosListener?.remove()
            videos.removeAll()
            collectionView.reloadData()
        }
        
        // Add real-time listener
        videosListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching videos: \(error.localizedDescription)")
                self.isLoadingMore = false
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("⚠️ No more videos found")
                self.hasMoreVideos = false
                self.isLoadingMore = false
                return
            }
            
            // Update last document for pagination
            self.lastDocument = documents.last
            
            // Process the new videos
            let newVideos = documents.compactMap { document -> Video? in
                guard let video = Video(from: document) else {
                    print("⚠️ Invalid document data for id: \(document.documentID)")
                    return nil
                }
                return video
            }
            
            // Update the videos array
            if isInitialFetch {
                self.videos = newVideos
            } else {
                // Append only new videos that aren't already in the array
                let existingIds = Set(self.videos.map { $0.id })
                let uniqueNewVideos = newVideos.filter { !existingIds.contains($0.id) }
                self.videos.append(contentsOf: uniqueNewVideos)
            }
            
            print("\n🎯 Total videos: \(self.videos.count)")
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.isLoadingMore = false
            }
        }
    }
    
    private func prefetchAdjacentVideos(for currentIndex: Int) {
        print("\n🔄 Prefetching adjacent videos for index: \(currentIndex)")
        
        // Define indices to prefetch (previous and next)
        let indicesToPrefetch = [
            max(0, currentIndex - 1),
            min(videos.count - 1, currentIndex + 1)
        ]
        
        for index in indicesToPrefetch where index != currentIndex {
            guard index >= 0 && index < videos.count else { continue }
            
            let video = videos[index]
            guard let videoURL = URL(string: video.storagePath) else {
                print("❌ Invalid URL for video at index \(index)")
                continue
            }
            
            // Check if already prefetched
            if prefetchedAssets[video.id] != nil {
                print("✅ Video \(video.id) already prefetched")
                continue
            }
            
            print("🔄 Starting prefetch for video \(video.id) at index \(index)")
            
            // Create asset with video loading options
            let asset = AVURLAsset(url: videoURL, options: [
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
                "AVURLAssetPreferPreciseDurationAndTimingKey": true
            ])
            
            // Load key asset properties asynchronously
            let keys = ["playable", "duration"]
            asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
                guard let self = self else { return }
                
                // Check for successful load
                var error: NSError?
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                if status == .loaded {
                    print("✅ Successfully prefetched video \(video.id)")
                    self.prefetchedAssets[video.id] = asset
                    
                    // Store in VideoCache
                    VideoCache.shared.cacheAsset(asset, forKey: videoURL.absoluteString)
                } else {
                    print("❌ Failed to prefetch video \(video.id): \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func cancelPrefetch(for indices: [Int]) {
        indices.forEach { index in
            guard index >= 0 && index < videos.count else { return }
            let video = videos[index]
            prefetchedAssets.removeValue(forKey: video.id)
        }
    }
    
    private func configureVideoCell(at indexPath: IndexPath) {
        guard indexPath.item < videos.count else { return }
        
        let video = videos[indexPath.item]
        guard let videoURL = URL(string: video.storagePath) else {
            print("❌ Invalid video URL for video: \(video.id)")
            return
        }
        
        print("\n🎬 Configuring video cell at index \(indexPath.item)")
        
        if let existingCell = collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell {
            print("✅ Found existing cell, configuring directly")
            existingCell.configure(with: video)
            
            let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
            let cellRect = collectionView.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
            if visibleRect.intersects(cellRect) {
                print("▶️ Cell is visible, playing video")
                currentlyPlayingCell?.pause()
                existingCell.restart()  // Use restart for initial playback
                currentlyPlayingCell = existingCell
                
                // Prefetch adjacent videos
                prefetchAdjacentVideos(for: indexPath.item)
            }
        } else {
            print("⏳ Cell not available yet, will configure in cellForItemAt")
        }
    }
    
    // MARK: - UICollectionView Data Source & Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("📊 Number of videos: \(videos.count)")
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Return full screen size for each cell
        return CGSize(
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("\n🔄 Creating/reusing cell at index: \(indexPath.item)")
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullScreenVideoCell.identifier, for: indexPath) as? FullScreenVideoCell else {
            print("❌ Failed to dequeue FullScreenVideoCell")
            return UICollectionViewCell()
        }
        
        let video = videos[indexPath.item]
        cell.delegate = self
        cell.configure(with: video)
        
        // Check if cell should be playing
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let cellRect = collectionView.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
        if visibleRect.intersects(cellRect) {
            print("▶️ New cell is visible, playing video")
            currentlyPlayingCell?.pause()
            cell.restart()  // Use restart for initial playback
            currentlyPlayingCell = cell
        }
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        // Update playing cell when scrolling stops
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint),
           let cell = collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell {
            print("📱 Switching to video at index: \(indexPath.item)")
            currentlyPlayingCell?.pause()
            cell.restart()  // Use restart when switching to a new video
            currentlyPlayingCell = cell
            
            // Update loading window and perform cleanup
            updateLoadingWindow()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if we need to load more videos
        let threshold: CGFloat = 100.0 // Load more when within 100 points of the bottom
        let distance = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.height)
        
        if distance < threshold && !isLoadingMore && hasMoreVideos {
            fetchVideos(isInitialFetch: false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the first video plays when the view appears
        if currentlyPlayingCell == nil,
           let firstVisibleIndexPath = collectionView.indexPathsForVisibleItems.first,
           let firstCell = collectionView.cellForItem(at: firstVisibleIndexPath) as? FullScreenVideoCell {
            print("\n▶️ Playing first visible video at index \(firstVisibleIndexPath.item)")
            currentlyPlayingCell?.pause()
            firstCell.restart()  // Use restart for initial playback
            currentlyPlayingCell = firstCell
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Pause video when leaving view
        currentlyPlayingCell?.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Clear memory cache on memory warning
        VideoCache.shared.clearCache()
    }
    
    private func setupMemoryMonitoring() {
        memoryUsageLogger = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkMemoryUsage()
        }
    }
    
    private func checkMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            print("📊 Memory Usage: \(String(format: "%.2f", usedMB))MB")
            
            if info.resident_size > maxMemoryThreshold {
                print("⚠️ Memory usage exceeded threshold, forcing cleanup")
                performAggressiveCleanup()
            }
        }
    }
    
    private func performAggressiveCleanup() {
        // Clear distant prefetched assets
        guard let currentIndex = getCurrentIndex() else { return }
        let window = VideoLoadingWindow(centerIndex: currentIndex)
        
        // Remove assets outside window
        let assetsToRemove = prefetchedAssets.filter { videoId, _ in
            guard let index = videos.firstIndex(where: { $0.id == videoId }) else { return true }
            return !window.shouldKeepLoaded(index: index, totalCount: videos.count)
        }
        
        assetsToRemove.forEach { videoId, _ in
            prefetchedAssets.removeValue(forKey: videoId)
        }
        
        // Clear video cache for distant videos
        VideoCache.shared.cleanOldCacheFiles()
        
        print("🧹 Cleaned up \(assetsToRemove.count) distant assets")
    }
    
    private func getCurrentIndex() -> Int? {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        return collectionView.indexPathForItem(at: visiblePoint)?.item
    }
    
    private func updateLoadingWindow() {
        guard let currentIndex = getCurrentIndex() else { return }
        loadingWindow = VideoLoadingWindow(centerIndex: currentIndex)
        
        // Check if we need to perform cleanup
        let now = Date()
        if now.timeIntervalSince(lastCleanupTime) >= cleanupInterval {
            deloadDistantVideos()
            lastCleanupTime = now
        }
    }
    
    private func deloadDistantVideos() {
        guard let window = loadingWindow else { return }
        
        // Remove distant assets from prefetch cache
        let assetsToRemove = prefetchedAssets.filter { videoId, _ in
            guard let index = videos.firstIndex(where: { $0.id == videoId }) else { return true }
            return !window.shouldKeepLoaded(index: index, totalCount: videos.count)
        }
        
        assetsToRemove.forEach { videoId, _ in
            prefetchedAssets.removeValue(forKey: videoId)
            print("🗑️ Deloaded video asset: \(videoId)")
        }
        
        // Force cleanup of distant cells
        for cell in collectionView.visibleCells {
            guard let videoCell = cell as? FullScreenVideoCell,
                  let video = videoCell.currentVideo,
                  let index = videos.firstIndex(where: { $0.id == video.id }),
                  !window.shouldKeepLoaded(index: index, totalCount: videos.count) else {
                continue
            }
            
            videoCell.prepareForReuse()
            print("🧹 Cleaned up distant cell for video: \(video.id)")
        }
    }
    
    deinit {
        videosListener?.remove()
        memoryUsageLogger?.invalidate()
        memoryUsageLogger = nil
    }
}

// MARK: - Helper Extensions
/**
 * Extension providing safe array access to prevent index out of bounds errors
 */
extension Array {
    func safe(_ index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - FullScreenVideoCell Delegate Implementation
/**
 * Extension implementing delegate methods for handling user interactions with video cells
 */
extension VideoScrollContentViewController: FullScreenVideoCellDelegate {
    
    /// Handles tapping on the creator's avatar
    /// - Parameter video: The video whose creator was tapped
    func didTapCreatorAvatar(for video: Video) {
        // Create and present creator's profile view controller
        let profileVC = PublicProfileViewController()
        profileVC.userId = video.creatorId
        profileVC.modalPresentationStyle = .fullScreen
        profileVC.transitioningDelegate = profileVC
        present(profileVC, animated: true)
    }
    
    /// Handles tapping the like button
    /// - Parameter video: The video to like/unlike
    func didTapLike(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
        
        // Find the cell for this video
        if let visibleCell = findVisibleCell(for: video) {
            likeRef.getDocument { [weak self] snapshot, error in
                guard let exists = snapshot?.exists else { return }
                
                if exists {
                    // Unlike video
                    visibleCell.animateLikeButton(isLiked: false)
                    likeRef.delete { error in
                        if error == nil {
                            visibleCell.fetchLikesCount(for: video)
                        } else {
                            // Revert animation on error
                            visibleCell.animateLikeButton(isLiked: true)
                        }
                    }
                } else {
                    // Like video
                    visibleCell.animateLikeButton(isLiked: true)
                    likeRef.setData([
                        "video_id": video.id,
                        "user_id": currentUserId,
                        "created_at": FieldValue.serverTimestamp()
                    ]) { error in
                        if error == nil {
                            visibleCell.fetchLikesCount(for: video)
                        } else {
                            // Revert animation on error
                            visibleCell.animateLikeButton(isLiked: false)
                        }
                    }
                }
            }
        }
    }
    
    /// Finds the visible cell for a given video
    /// - Parameter video: The video to find the cell for
    /// - Returns: The FullScreenVideoCell if found, nil otherwise
    private func findVisibleCell(for video: Video) -> FullScreenVideoCell? {
        for cell in collectionView.visibleCells {
            if let videoCell = cell as? FullScreenVideoCell,
               videoCell.currentVideo?.id == video.id {
                return videoCell
            }
        }
        return nil
    }
    
    /// Handles tapping the comment button
    /// - Parameter video: The video to show comments for
    func didTapComment(for video: Video) {
        // Create and configure comments view controller
        let commentsVC = CommentsViewController()
        commentsVC.videoId = video.id
        commentsVC.modalPresentationStyle = .overFullScreen
        
        // Configure comment count update handlers
        commentsVC.onCommentAdded = { [weak self] in
            // Optimistically update comment count
            if let cell = self?.findVisibleCell(for: video) {
                let currentCount = Int(cell.commentCountLabel.text ?? "0") ?? 0
                cell.commentCountLabel.text = "\(currentCount + 1)"
            }
        }
        
        commentsVC.onCommentDeleted = { [weak self] in
            // Optimistically update comment count
            if let cell = self?.findVisibleCell(for: video) {
                let currentCount = Int(cell.commentCountLabel.text ?? "0") ?? 0
                cell.commentCountLabel.text = "\(max(0, currentCount - 1))"
            }
        }
        
        present(commentsVC, animated: false)
    }
    
    /// Handles tapping the bookmark button
    /// - Parameter video: The video to bookmark/unbookmark
    func didTapBookmark(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let bookmarkRef = db.collection("video_bookmarks").document("\(video.id)_\(currentUserId)")
        
        // Find the cell for this video
        if let visibleCell = findVisibleCell(for: video) {
            bookmarkRef.getDocument { [weak self] snapshot, error in
                guard let exists = snapshot?.exists else { return }
                
                if exists {
                    // Remove bookmark
                    visibleCell.animateBookmarkButton(isBookmarked: false)
                    bookmarkRef.delete { error in
                        if error == nil {
                            visibleCell.fetchBookmarksCount(for: video)
                        } else {
                            // Revert animation on error
                            visibleCell.animateBookmarkButton(isBookmarked: true)
                        }
                    }
                } else {
                    // Add bookmark
                    visibleCell.animateBookmarkButton(isBookmarked: true)
                    bookmarkRef.setData([
                        "video_id": video.id,
                        "user_id": currentUserId,
                        "created_at": FieldValue.serverTimestamp()
                    ]) { error in
                        if error == nil {
                            visibleCell.fetchBookmarksCount(for: video)
                        } else {
                            // Revert animation on error
                            visibleCell.animateBookmarkButton(isBookmarked: false)
                        }
                    }
                }
            }
        }
    }
    
    /// Handles tapping the share button
    /// - Parameter video: The video to share
    func didTapShare(for video: Video) {
        // Create and present share sheet
        let items = [URL(string: video.storagePath)].compactMap { $0 }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
}

// MARK: - UICollectionView Prefetching
extension VideoScrollContentViewController: UICollectionViewDataSourcePrefetching {
    
    /// Prefetches items at the specified index paths
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let window = loadingWindow else { return }
        
        // Filter index paths to only those within the loading window
        let indexPathsInWindow = indexPaths.filter {
            window.shouldKeepLoaded(index: $0.item, totalCount: videos.count)
        }
        
        print("\n🔄 Prefetching items within window: \(indexPathsInWindow.map { $0.item })")
        
        // Prefetch each video in the window
        for indexPath in indexPathsInWindow {
            guard indexPath.item < videos.count else { continue }
            let video = videos[indexPath.item]
            
            guard let videoURL = URL(string: video.storagePath) else { continue }
            
            // Skip if already prefetched
            if prefetchedAssets[video.id] != nil { continue }
            
            // Create and load asset
            let asset = AVURLAsset(url: videoURL, options: [
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
                "AVURLAssetPreferPreciseDurationAndTimingKey": true
            ])
            
            let keys = ["playable", "duration"]
            asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
                guard let self = self else { return }
                
                var error: NSError?
                let status = asset.statusOfValue(forKey: "playable", error: &error)
                
                if status == .loaded {
                    self.prefetchedAssets[video.id] = asset
                    VideoCache.shared.cacheAsset(asset, forKey: videoURL.absoluteString)
                }
            }
        }
    }
    
    /// Cancels prefetching for items at the specified index paths
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("\n❌ Cancelling prefetch for indices: \(indexPaths.map { $0.item })")
        cancelPrefetch(for: indexPaths.map { $0.item })
    }
}
