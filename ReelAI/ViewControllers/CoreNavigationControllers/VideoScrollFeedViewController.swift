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
        collectionView.register(FullScreenVideoCell.self, forCellWithReuseIdentifier: FullScreenVideoCell.identifier)
    }
    
    private func configureVideoCell(at indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell else { return }
        
        currentlyPlayingCell?.pause()
        cell.play()
        currentlyPlayingCell = cell
        
        // Track video view
        if indexPath.item < videos.count {
            trackVideoView(videos[indexPath.item])
        }
    }
    
    private func trackVideoView(_ video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let videoRef = db.collection("videos").document(video.id)
        let viewedRef = db.collection("viewed_videos").document("\(video.id)_\(currentUserId)")
        
        // Increment view count using FieldValue.increment
        videoRef.setData([
            "views_count": FieldValue.increment(Int64(1))
        ], merge: true)
        
        // Check if this is a first view for watch history
        viewedRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ Error checking view history: \(error.localizedDescription)")
                return
            }
            
            // If this is the first view, add to watch history
            if snapshot?.exists != true {
                viewedRef.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "first_viewed": FieldValue.serverTimestamp(),
                    "last_viewed": FieldValue.serverTimestamp()
                ])
            } else {
                // Update last_viewed timestamp for existing entry
                viewedRef.updateData([
                    "last_viewed": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    @objc private func handleClose() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension VideoScrollFeedViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FullScreenVideoCell.identifier, for: indexPath) as! FullScreenVideoCell
        cell.delegate = self
        cell.configure(with: videos[indexPath.item])
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
        }
    }
}

// MARK: - FullScreenVideoCellDelegate
extension VideoScrollFeedViewController: FullScreenVideoCellDelegate {
    func didTapCreatorAvatar(for video: Video) {
        let profileVC = PublicProfileViewController()
        profileVC.userId = video.creatorId
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func didTapLike(for video: Video) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Find the cell and update UI optimistically
        if let visibleCell = findVisibleCell(for: video) {
            let isCurrentlyLiked = video.isLikedByCurrentUser
            let newLikeState = !isCurrentlyLiked
            
            // Update UI optimistically
            video.updateLikeStatus(isLiked: newLikeState)
            visibleCell.updateUI(with: video)
            
            // Update Firebase in background
            let db = Firestore.firestore()
            let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
            
            if newLikeState {
                likeRef.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "created_at": FieldValue.serverTimestamp()
                ]) { [weak self] error in
                    if let error = error {
                        // Revert on error
                        print("❌ Error liking video: \(error.localizedDescription)")
                        video.updateLikeStatus(isLiked: isCurrentlyLiked)
                        visibleCell.updateUI(with: video)
                    }
                }
            } else {
                likeRef.delete { [weak self] error in
                    if let error = error {
                        // Revert on error
                        print("❌ Error unliking video: \(error.localizedDescription)")
                        video.updateLikeStatus(isLiked: isCurrentlyLiked)
                        visibleCell.updateUI(with: video)
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
        
        // Handle comment count updates optimistically
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
        
        // Find the cell and update UI optimistically
        if let visibleCell = findVisibleCell(for: video) {
            let isCurrentlyBookmarked = video.isBookmarkedByCurrentUser
            let newBookmarkState = !isCurrentlyBookmarked
            
            // Update UI optimistically
            video.updateBookmarkStatus(isBookmarked: newBookmarkState)
            visibleCell.updateUI(with: video)
            
            // Update Firebase in background
            let db = Firestore.firestore()
            let bookmarkRef = db.collection("video_bookmarks").document("\(video.id)_\(currentUserId)")
            
            if newBookmarkState {
                bookmarkRef.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "created_at": FieldValue.serverTimestamp()
                ]) { [weak self] error in
                    if let error = error {
                        // Revert on error
                        print("❌ Error bookmarking video: \(error.localizedDescription)")
                        video.updateBookmarkStatus(isBookmarked: isCurrentlyBookmarked)
                        visibleCell.updateUI(with: video)
                    }
                }
            } else {
                bookmarkRef.delete { [weak self] error in
                    if let error = error {
                        // Revert on error
                        print("❌ Error unbookmarking video: \(error.localizedDescription)")
                        video.updateBookmarkStatus(isBookmarked: isCurrentlyBookmarked)
                        visibleCell.updateUI(with: video)
                    }
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
