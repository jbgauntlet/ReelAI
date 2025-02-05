import UIKit
import AVFoundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// Video Cache Manager
class VideoCache {
    static let shared = VideoCache()
    private let cache = NSCache<NSString, AVURLAsset>()  // Cache AVURLAsset instead of AVPlayerItem
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int = 500 * 1024 * 1024  // 500MB
    
    private init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, 
                                      withIntermediateDirectories: true)
        
        cache.countLimit = 10
        cache.totalCostLimit = 250 * 1024 * 1024
        
        cleanOldCacheFiles()
    }
    
    func playerItem(for url: URL) -> AVPlayerItem {
        let cacheKey = NSString(string: url.absoluteString)
        
        // Get or create asset
        let asset: AVURLAsset
        if let cachedAsset = cache.object(forKey: cacheKey) {
            print("📦 Found video asset in memory cache")
            asset = cachedAsset
        } else {
            print("🔄 Creating new video asset")
            asset = AVURLAsset(url: url, options: [
                "AVURLAssetOutOfBandMIMETypeKey": "video/mp4",
                "AVURLAssetHTTPHeaderFieldsKey": ["Accept": "video/mp4"]
            ])
            cache.setObject(asset, forKey: cacheKey)
        }
        
        // Always create a new player item
        return AVPlayerItem(asset: asset)
    }
    
    func cleanOldCacheFiles() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, 
                                                          includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            
            // Sort by creation date
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                return date1! < date2!
            }
            
            // Calculate total size
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
    
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, 
                                      withIntermediateDirectories: true)
    }
    
    func cacheAsset(_ asset: AVURLAsset, forKey key: String) {
        cache.setObject(asset, forKey: NSString(string: key))
    }
}

class FullScreenVideoCell: UICollectionViewCell {
    static let identifier = "FullScreenVideoCell"
    private var cellId = UUID().uuidString // For logging purposes
    
    private let playerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Action Bar UI Components
    private let actionBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print("📱 VideoCell initialized with ID: \(cellId)")
        setupUI()
        setupActionBar()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Make sure the cell's content view fills the cell
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        contentView.addSubview(playerView)
        contentView.addSubview(loadingIndicator)
        setupInfoPanel()
        
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    private func setupInfoPanel() {
        contentView.addSubview(infoPanelView)
        
        infoPanelView.addSubview(titleLabel)
        infoPanelView.addSubview(captionLabel)
        infoPanelView.addSubview(tagsLabel)
        
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
    
    private func setupActionBar() {
        contentView.addSubview(actionBarView)
        
        actionBarView.addSubview(creatorAvatarButton)
        actionBarView.addSubview(likeButton)
        actionBarView.addSubview(commentButton)
        actionBarView.addSubview(bookmarkButton)
        actionBarView.addSubview(shareButton)
        
        actionBarView.addSubview(likeCountLabel)
        actionBarView.addSubview(commentCountLabel)
        actionBarView.addSubview(bookmarkCountLabel)
        
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
        
        // Add targets for buttons
        creatorAvatarButton.addTarget(self, action: #selector(creatorAvatarTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
        bookmarkButton.addTarget(self, action: #selector(bookmarkTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    }
    
    func configure(with video: Video) {
        currentVideo = video
        
        // Configure video player
        guard let videoURL = URL(string: video.storagePath) else { return }
        configureVideo(with: videoURL)
        
        // Update action bar
        updateActionBar(with: video)
        
        // Update info panel
        titleLabel.text = video.title
        captionLabel.text = video.caption
        // Safely handle tags
        if let tags = video.tags {
            tagsLabel.text = tags.map { "#\($0)" }.joined(separator: " ")
        } else {
            tagsLabel.text = ""
        }
    }
    
    private func configureVideo(with url: URL) {
        print("🎬 Configuring cell \(cellId) with video URL: \(url.lastPathComponent)")
        loadingIndicator.startAnimating()
        
        // Get cached player item
        let playerItem = VideoCache.shared.playerItem(for: url)
        
        // Create player with the cached item
        let player = AVPlayer(playerItem: playerItem)
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        
        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = playerView.bounds
        self.playerLayer = playerLayer
        
        // Remove any existing player layers
        playerView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        playerView.layer.addSublayer(playerLayer)
        
        // Add observers
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Only update frames if they've actually changed
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
    
    @objc private func playerItemDidReachEnd() {
        print("🔄 Video reached end in cell \(cellId), looping...")
        player?.seek(to: .zero)
        player?.play()
    }
    
    func play() {
        print("▶️ Playing video in cell \(cellId)")
        player?.seek(to: .zero)
        player?.play()
    }
    
    func pause() {
        print("⏸️ Pausing video in cell \(cellId)")
        player?.pause()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("♻️ Preparing cell \(cellId) for reuse")
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        NotificationCenter.default.removeObserver(self)
        
        // Clear current video
        currentVideo = nil
        
        // Remove avatar label if it exists
        creatorAvatarButton.subviews.forEach { $0.removeFromSuperview() }
    }
    
    deinit {
        print("🗑️ VideoCell \(cellId) being deallocated")
    }
    
    private func updateActionBar(with video: Video) {
        // Get creator's avatar
        let db = Firestore.firestore()
        
        // Fetch like status and count
        fetchLikeStatus(for: video)
        fetchLikesCount(for: video)
        fetchBookmarkStatus(for: video)
        fetchBookmarksCount(for: video)
        
        commentCountLabel.text = "\(video.commentsCount)"
        bookmarkCountLabel.text = "\(video.bookmarksCount)"
        
        db.collection("users").document(video.creatorId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let username = data["username"] as? String else {
                return
            }
            
            if let avatarUrl = data["avatar"] as? String,
               let url = URL(string: avatarUrl) {
                // Create a URLSession data task to fetch the image
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
                            // Clear any existing content
                            self?.creatorAvatarButton.subviews.forEach { $0.removeFromSuperview() }
                            self?.creatorAvatarButton.backgroundColor = .clear
                            
                            // Create a new UIImageView with the correct size and configuration
                            let imageView = UIImageView(frame: self?.creatorAvatarButton.bounds ?? .zero)
                            imageView.contentMode = .scaleAspectFill
                            imageView.clipsToBounds = true
                            imageView.image = image
                            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                            
                            // Add the image view to the button
                            self?.creatorAvatarButton.addSubview(imageView)
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
    
    func fetchLikeStatus(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
        
        likeRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // Animate like button appearance based on whether the user has liked
            if snapshot?.exists == true {
                self.animateLikeButton(isLiked: true)
            } else {
                self.animateLikeButton(isLiked: false)
            }
        }
    }
    
    func animateLikeButton(isLiked: Bool) {
        // First, scale down quickly
        UIView.animate(withDuration: 0.15, animations: {
            self.likeButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            // Then, scale up and change color
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.likeButton.transform = CGAffineTransform.identity
                self.likeButton.tintColor = isLiked ? .systemRed : .white
            }
        }
    }
    
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
                
                let likesCount = snapshot?.documents.count ?? 0
                self.likeCountLabel.text = "\(likesCount)"
                
                // Update the video document with the current count if it's different
                if likesCount != video.likesCount {
                    db.collection("videos").document(video.id).updateData([
                        "likes_count": likesCount
                    ])
                }
            }
    }
    
    func fetchBookmarkStatus(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let bookmarkRef = db.collection("video_bookmarks").document("\(video.id)_\(currentUserId)")
        
        bookmarkRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            // Animate bookmark button appearance based on whether the user has bookmarked
            if snapshot?.exists == true {
                self.animateBookmarkButton(isBookmarked: true)
            } else {
                self.animateBookmarkButton(isBookmarked: false)
            }
        }
    }
    
    func animateBookmarkButton(isBookmarked: Bool) {
        // First, scale down quickly
        UIView.animate(withDuration: 0.15, animations: {
            self.bookmarkButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            // Then, scale up and change color
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
                self.bookmarkButton.transform = CGAffineTransform.identity
                self.bookmarkButton.tintColor = isBookmarked ? .systemYellow : .white
            }
        }
    }
    
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
                
                let bookmarksCount = snapshot?.documents.count ?? 0
                self.bookmarkCountLabel.text = "\(bookmarksCount)"
                
                // Update the video document with the current count if it's different
                if bookmarksCount != video.bookmarksCount {
                    db.collection("videos").document(video.id).updateData([
                        "bookmarks_count": bookmarksCount
                    ])
                }
            }
    }
    
    private func setupDefaultAvatar(with username: String) {
        // Clear any existing content
        creatorAvatarButton.setImage(nil, for: .normal)
        creatorAvatarButton.subviews.forEach { $0.removeFromSuperview() }
        
        // Create default avatar with first letter
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
    @objc private func creatorAvatarTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapCreatorAvatar(for: video)
    }
    
    @objc private func likeTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapLike(for: video)
    }
    
    @objc private func commentTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapComment(for: video)
    }
    
    @objc private func bookmarkTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapBookmark(for: video)
    }
    
    @objc private func shareTapped() {
        guard let video = currentVideo else { return }
        delegate?.didTapShare(for: video)
    }
}

// MARK: - FullScreenVideoCellDelegate
protocol FullScreenVideoCellDelegate: AnyObject {
    func didTapCreatorAvatar(for video: Video)
    func didTapLike(for video: Video)
    func didTapComment(for video: Video)
    func didTapBookmark(for video: Video)
    func didTapShare(for video: Video)
}

// Add after the VideoCache class
struct VideoLoadingWindow {
    static let windowSize = 5 // Keep current + 2 videos in each direction
    let centerIndex: Int
    
    var indexRange: Range<Int> {
        let start = max(0, centerIndex - VideoLoadingWindow.windowSize/2)
        let end = centerIndex + VideoLoadingWindow.windowSize/2
        return start..<end
    }
    
    func shouldKeepLoaded(index: Int, totalCount: Int) -> Bool {
        guard index >= 0 && index < totalCount else { return false }
        return abs(index - centerIndex) <= VideoLoadingWindow.windowSize/2
    }
}

class VideoScrollContentViewController: UIViewController {
    private var videos: [Video] = []
    private var currentlyPlayingCell: FullScreenVideoCell?
    private var prefetchedAssets: [String: AVURLAsset] = [:]
    private var loadingWindow: VideoLoadingWindow?
    private var lastCleanupTime: Date = Date()
    private var cleanupInterval: TimeInterval = 2.0
    
    // Pagination and real-time updates
    private var videosListener: ListenerRegistration?
    private var lastDocument: DocumentSnapshot?
    private let batchSize = 10
    private var isLoadingMore = false
    private var hasMoreVideos = true
    
    // Add memory usage tracking
    private var memoryUsageLogger: Timer?
    private let maxMemoryThreshold: UInt64 = 300 * 1024 * 1024 // 300MB threshold
    
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
                existingCell.play()
                currentlyPlayingCell = existingCell
                
                // Prefetch adjacent videos
                prefetchAdjacentVideos(for: indexPath.item)
            }
        } else {
            print("⏳ Cell not available yet, will configure in cellForItemAt")
        }
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
        
        // Check if this should be the playing cell
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let cellRect = collectionView.layoutAttributesForItem(at: indexPath)?.frame ?? .zero
        if visibleRect.intersects(cellRect) {
            print("▶️ New cell is visible, playing video")
            currentlyPlayingCell?.pause()
            cell.play()
            currentlyPlayingCell = cell
        }
        
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the first video plays when the view appears
        if currentlyPlayingCell == nil,
           let firstVisibleIndexPath = collectionView.indexPathsForVisibleItems.first,
           let firstCell = collectionView.cellForItem(at: firstVisibleIndexPath) as? FullScreenVideoCell {
            print("\n▶️ Playing first visible video at index \(firstVisibleIndexPath.item)")
            currentlyPlayingCell?.pause()
            firstCell.play()
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

// Helper extension for safe array access
extension Array {
    func safe(_ index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension VideoScrollContentViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("📊 Number of videos: \(videos.count)")
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate size based on collection view bounds, accounting for tab bar
        return CGSize(
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint),
           let cell = collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell {
            print("📱 Switching to video at index: \(indexPath.item)")
            currentlyPlayingCell?.pause()
            cell.play()
            currentlyPlayingCell = cell
            
            // Update loading window and perform cleanup
            updateLoadingWindow()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 100.0 // Load more when within 100 points of the bottom
        let distance = scrollView.contentSize.height - (scrollView.contentOffset.y + scrollView.bounds.height)
        
        if distance < threshold && !isLoadingMore && hasMoreVideos {
            fetchVideos(isInitialFetch: false)
        }
    }
}

extension VideoScrollContentViewController: FullScreenVideoCellDelegate {
    func didTapCreatorAvatar(for video: Video) {
        // Navigate to creator's profile
        let profileVC = PublicProfileViewController()
        profileVC.userId = video.creatorId
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func didTapLike(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
        
        // Find the cell for this video
        if let visibleCell = findVisibleCell(for: video) {
            likeRef.getDocument { [weak self] snapshot, error in
                guard let exists = snapshot?.exists else { return }
                
                if exists {
                    // Unlike - Animate immediately for user feedback
                    visibleCell.animateLikeButton(isLiked: false)
                    // Then update backend
                    likeRef.delete { error in
                        if error == nil {
                            visibleCell.fetchLikesCount(for: video)
                        } else {
                            // Revert animation if there was an error
                            visibleCell.animateLikeButton(isLiked: true)
                        }
                    }
                } else {
                    // Like - Animate immediately for user feedback
                    visibleCell.animateLikeButton(isLiked: true)
                    // Then update backend
                    likeRef.setData([
                        "video_id": video.id,
                        "user_id": currentUserId,
                        "created_at": FieldValue.serverTimestamp()
                    ]) { error in
                        if error == nil {
                            visibleCell.fetchLikesCount(for: video)
                        } else {
                            // Revert animation if there was an error
                            visibleCell.animateLikeButton(isLiked: false)
                        }
                    }
                }
            }
        }
    }
    
    private func findVisibleCell(for video: Video) -> FullScreenVideoCell? {
        for cell in collectionView.visibleCells {
            if let videoCell = cell as? FullScreenVideoCell,
               videoCell.currentVideo?.id == video.id {
                return videoCell
            }
        }
        return nil
    }
    
    func didTapComment(for video: Video) {
        let commentsVC = CommentsViewController()
        commentsVC.videoId = video.id
        commentsVC.modalPresentationStyle = .overFullScreen
        
        // Set up comment count update handlers
        commentsVC.onCommentAdded = { [weak self] in
            // Optimistically update the comment count in the UI
            if let cell = self?.findVisibleCell(for: video) {
                let currentCount = Int(cell.commentCountLabel.text ?? "0") ?? 0
                cell.commentCountLabel.text = "\(currentCount + 1)"
            }
        }
        
        commentsVC.onCommentDeleted = { [weak self] in
            // Optimistically update the comment count in the UI
            if let cell = self?.findVisibleCell(for: video) {
                let currentCount = Int(cell.commentCountLabel.text ?? "0") ?? 0
                cell.commentCountLabel.text = "\(max(0, currentCount - 1))"
            }
        }
        
        present(commentsVC, animated: false)
    }
    
    func didTapBookmark(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let bookmarkRef = db.collection("video_bookmarks").document("\(video.id)_\(currentUserId)")
        
        // Find the cell for this video
        if let visibleCell = findVisibleCell(for: video) {
            bookmarkRef.getDocument { [weak self] snapshot, error in
                guard let exists = snapshot?.exists else { return }
                
                if exists {
                    // Remove bookmark - Animate immediately for user feedback
                    visibleCell.animateBookmarkButton(isBookmarked: false)
                    // Then update backend
                    bookmarkRef.delete { error in
                        if error == nil {
                            visibleCell.fetchBookmarksCount(for: video)
                        } else {
                            // Revert animation if there was an error
                            visibleCell.animateBookmarkButton(isBookmarked: true)
                        }
                    }
                } else {
                    // Add bookmark - Animate immediately for user feedback
                    visibleCell.animateBookmarkButton(isBookmarked: true)
                    // Then update backend
                    bookmarkRef.setData([
                        "video_id": video.id,
                        "user_id": currentUserId,
                        "created_at": FieldValue.serverTimestamp()
                    ]) { error in
                        if error == nil {
                            visibleCell.fetchBookmarksCount(for: video)
                        } else {
                            // Revert animation if there was an error
                            visibleCell.animateBookmarkButton(isBookmarked: false)
                        }
                    }
                }
            }
        }
        bookmarkRef.getDocument { [weak self] snapshot, error in
            guard let exists = snapshot?.exists else { return }
            
            if exists {
                // Remove bookmark
                bookmarkRef.delete()
            } else {
                // Add bookmark
                bookmarkRef.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "created_at": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    func didTapShare(for video: Video) {
        // Create activity view controller for sharing
        let items = [URL(string: video.storagePath)].compactMap { $0 }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching
extension VideoScrollContentViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let window = loadingWindow else { return }
        
        let indexPathsInWindow = indexPaths.filter {
            window.shouldKeepLoaded(index: $0.item, totalCount: videos.count)
        }
        
        print("\n🔄 Prefetching items within window: \(indexPathsInWindow.map { $0.item })")
        
        for indexPath in indexPathsInWindow {
            guard indexPath.item < videos.count else { continue }
            let video = videos[indexPath.item]
            
            guard let videoURL = URL(string: video.storagePath) else { continue }
            
            // Check if already prefetched
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
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("\n❌ Cancelling prefetch for indices: \(indexPaths.map { $0.item })")
        cancelPrefetch(for: indexPaths.map { $0.item })
    }
}
