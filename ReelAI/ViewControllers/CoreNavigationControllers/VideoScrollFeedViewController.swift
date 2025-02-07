//
//  ProfileVideoScrollFeedViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/4/25.
//

import UIKit
import AVFoundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

class VideoScrollFeedViewController: UIViewController {
    // MARK: - Properties
    private var videos: [Video]
    private var startingIndex: Int
    private var currentlyPlayingCell: FullScreenVideoCell?
    private var prefetchedAssets: [String: AVURLAsset] = [:]
    private var loadingWindow: VideoLoadingWindow?
    private var lastCleanupTime: Date = Date()
    private let cleanupInterval: TimeInterval = 2.0
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.backgroundColor = .black
        cv.showsVerticalScrollIndicator = false
        cv.contentInsetAdjustmentBehavior = .never
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Initialization
    init(videos: [Video], startingIndex: Int) {
        self.videos = videos
        self.startingIndex = startingIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        
        // Scroll to starting video
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let indexPath = IndexPath(item: self.startingIndex, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            self.configureVideoCell(at: indexPath)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
        if let visibleIndexPath = collectionView.indexPathsForVisibleItems.first {
            configureVideoCell(at: visibleIndexPath)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        currentlyPlayingCell?.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure the first video plays when the view appears
        if currentlyPlayingCell == nil,
           let firstVisibleIndexPath = collectionView.indexPathsForVisibleItems.first,
           let firstCell = collectionView.cellForItem(at: firstVisibleIndexPath) as? FullScreenVideoCell {
            print("\n▶️ Playing first visible video at index \(firstVisibleIndexPath.item)")
            currentlyPlayingCell?.pause()
            firstCell.restart()
            currentlyPlayingCell = firstCell
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Add close button
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
        collectionView.register(FullScreenVideoCell.self, forCellWithReuseIdentifier: FullScreenVideoCell.identifier)
    }
    
    @objc private func handleClose() {
        dismiss(animated: true)
    }
    
    // MARK: - Video Management
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
                existingCell.restart()
                currentlyPlayingCell = existingCell
                
                // Track video view
                trackVideoView(video)
                
                // Prefetch adjacent videos
                prefetchAdjacentVideos(for: indexPath.item)
            }
        } else {
            print("⏳ Cell not available yet, will configure in cellForItemAt")
        }
    }
    
    private func prefetchAdjacentVideos(for currentIndex: Int) {
        print("\n🔄 Prefetching adjacent videos for index: \(currentIndex)")
        
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
            
            if prefetchedAssets[video.id] != nil {
                print("✅ Video \(video.id) already prefetched")
                continue
            }
            
            print("🔄 Starting prefetch for video \(video.id) at index \(index)")
            
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
                    print("✅ Successfully prefetched video \(video.id)")
                    self.prefetchedAssets[video.id] = asset
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
    
    private func updateLoadingWindow() {
        guard let currentIndex = getCurrentIndex() else { return }
        loadingWindow = VideoLoadingWindow(centerIndex: currentIndex)
        
        let now = Date()
        if now.timeIntervalSince(lastCleanupTime) >= cleanupInterval {
            deloadDistantVideos()
            lastCleanupTime = now
        }
    }
    
    private func getCurrentIndex() -> Int? {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        return collectionView.indexPathForItem(at: visiblePoint)?.item
    }
    
    private func deloadDistantVideos() {
        guard let window = loadingWindow else { return }
        
        let assetsToRemove = prefetchedAssets.filter { videoId, _ in
            guard let index = videos.firstIndex(where: { $0.id == videoId }) else { return true }
            return !window.shouldKeepLoaded(index: index, totalCount: videos.count)
        }
        
        assetsToRemove.forEach { videoId, _ in
            prefetchedAssets.removeValue(forKey: videoId)
            print("🗑️ Deloaded video asset: \(videoId)")
        }
        
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
    
    private func trackVideoView(_ video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ Cannot track video view: No current user")
            return
        }
        
        print("\n📊 Starting to track view for video: \(video.id)")
        print("👤 Current user: \(currentUserId)")
        
        let db = Firestore.firestore()
        let videoRef = db.collection("videos").document(video.id)
        let viewRef = db.collection("video_views").document("\(video.id)_\(currentUserId)")
        
        print("🔍 Checking for existing view record at path: video_views/\(video.id)_\(currentUserId)")
        
        viewRef.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error checking view history: \(error.localizedDescription)")
                return
            }
            
            print("📝 View record exists: \(snapshot?.exists == true)")
            
            let batch = db.batch()
            print("🔄 Creating batch operation")
            
            print("➕ Adding views_count increment to batch")
            batch.setData([
                "views_count": FieldValue.increment(Int64(1))
            ], forDocument: videoRef, merge: true)
            
            let now = FieldValue.serverTimestamp()
            
            if snapshot?.exists != true {
                print("📌 First view - creating new view record")
                batch.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "first_viewed": now,
                    "last_viewed": now,
                    "created_at": now
                ], forDocument: viewRef)
            } else {
                print("🔄 Existing view - updating last_viewed timestamp")
                batch.updateData([
                    "last_viewed": now
                ], forDocument: viewRef)
            }
            
            print("💾 Committing batch operation")
            batch.commit { error in
                if let error = error {
                    print("❌ Error tracking video view: \(error.localizedDescription)")
                    print("Error details: \(error)")
                } else {
                    print("✅ Successfully tracked video view")
                    print("   - Video: \(video.id)")
                    print("   - User: \(currentUserId)")
                    print("   - Operation: \(snapshot?.exists == true ? "Updated existing record" : "Created new record")")
                }
            }
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension VideoScrollFeedViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullScreenVideoCell.identifier, for: indexPath) as? FullScreenVideoCell else {
            return UICollectionViewCell()
        }
        cell.delegate = self
        cell.configure(with: videos[indexPath.item])
        
        // Auto-play if this is the starting index
        if indexPath.item == startingIndex {
            currentlyPlayingCell?.pause()
            cell.play()
            currentlyPlayingCell = cell
            
            // Track video view
            trackVideoView(videos[indexPath.item])
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let indexPath = collectionView.indexPathForItem(at: visiblePoint) {
            configureVideoCell(at: indexPath)
            updateLoadingWindow()
        }
    }
}

// MARK: - UICollectionView Prefetching
extension VideoScrollFeedViewController: UICollectionViewDataSourcePrefetching {
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
            
            if prefetchedAssets[video.id] != nil { continue }
            
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

// MARK: - FullScreenVideoCellDelegate
extension VideoScrollFeedViewController: FullScreenVideoCellDelegate {
    func didTapCreatorAvatar(for video: Video) {
        // No-op: Avatar should not be clickable in feed view
    }
    
    func didTapLike(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        if let visibleCell = findVisibleCell(for: video) {
            let isCurrentlyLiked = video.isLikedByCurrentUser
            let newLikeState = !isCurrentlyLiked
            
            video.updateLikeStatus(isLiked: newLikeState)
            visibleCell.updateUI(with: video)
            
            let db = Firestore.firestore()
            let batch = db.batch()
            let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
            let videoRef = db.collection("videos").document(video.id)
            
            if newLikeState {
                batch.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "created_at": FieldValue.serverTimestamp()
                ], forDocument: likeRef)
                
                batch.updateData([
                    "likes_count": FieldValue.increment(Int64(1))
                ], forDocument: videoRef)
            } else {
                batch.deleteDocument(likeRef)
                
                batch.updateData([
                    "likes_count": FieldValue.increment(Int64(-1))
                ], forDocument: videoRef)
            }
            
            batch.commit { [weak self] error in
                if let error = error {
                    print("❌ Error updating like status: \(error.localizedDescription)")
                    video.updateLikeStatus(isLiked: isCurrentlyLiked)
                    visibleCell.updateUI(with: video)
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
        
        commentsVC.onCommentAdded = { [weak self] in
            video.updateCommentCount(delta: 1)
            if let cell = self?.findVisibleCell(for: video) {
                cell.updateUI(with: video)
            }
        }
        
        commentsVC.onCommentDeleted = { [weak self] in
            video.updateCommentCount(delta: -1)
            if let cell = self?.findVisibleCell(for: video) {
                cell.updateUI(with: video)
            }
        }
        
        present(commentsVC, animated: false)
    }
    
    func didTapBookmark(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        if let visibleCell = findVisibleCell(for: video) {
            let isCurrentlyBookmarked = video.isBookmarkedByCurrentUser
            let newBookmarkState = !isCurrentlyBookmarked
            
            video.updateBookmarkStatus(isBookmarked: newBookmarkState)
            visibleCell.updateUI(with: video)
            
            let db = Firestore.firestore()
            let batch = db.batch()
            let bookmarkRef = db.collection("video_bookmarks").document("\(video.id)_\(currentUserId)")
            let videoRef = db.collection("videos").document(video.id)
            
            if newBookmarkState {
                batch.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "created_at": FieldValue.serverTimestamp()
                ], forDocument: bookmarkRef)
                
                batch.updateData([
                    "bookmarks_count": FieldValue.increment(Int64(1))
                ], forDocument: videoRef)
            } else {
                batch.deleteDocument(bookmarkRef)
                
                batch.updateData([
                    "bookmarks_count": FieldValue.increment(Int64(-1))
                ], forDocument: videoRef)
            }
            
            batch.commit { [weak self] error in
                if let error = error {
                    print("❌ Error updating bookmark status: \(error.localizedDescription)")
                    video.updateBookmarkStatus(isBookmarked: isCurrentlyBookmarked)
                    visibleCell.updateUI(with: video)
                }
            }
        }
    }
    
    func didTapShare(for video: Video) {
        let items = [URL(string: video.storagePath)].compactMap { $0 }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
}
