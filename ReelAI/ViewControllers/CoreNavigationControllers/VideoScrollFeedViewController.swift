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
        
        let db = Firestore.firestore()
        let likeRef = db.collection("video_likes").document("\(video.id)_\(currentUserId)")
        
        if let visibleCell = findVisibleCell(for: video) {
            likeRef.getDocument { [weak self] snapshot, error in
                guard let exists = snapshot?.exists else { return }
                
                if exists {
                    // Unlike
                    visibleCell.animateLikeButton(isLiked: false)
                    likeRef.delete { error in
                        if error == nil {
                            visibleCell.fetchLikesCount(for: video)
                        } else {
                            visibleCell.animateLikeButton(isLiked: true)
                        }
                    }
                } else {
                    // Like
                    visibleCell.animateLikeButton(isLiked: true)
                    likeRef.setData([
                        "video_id": video.id,
                        "user_id": currentUserId,
                        "created_at": FieldValue.serverTimestamp()
                    ]) { error in
                        if error == nil {
                            visibleCell.fetchLikesCount(for: video)
                        } else {
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
            if let cell = self?.findVisibleCell(for: video) {
                let currentCount = Int(cell.commentCountLabel.text ?? "0") ?? 0
                cell.commentCountLabel.text = "\(currentCount + 1)"
            }
        }
        
        commentsVC.onCommentDeleted = { [weak self] in
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
        
        bookmarkRef.getDocument { [weak self] snapshot, error in
            guard let exists = snapshot?.exists else { return }
            
            if exists {
                bookmarkRef.delete()
            } else {
                bookmarkRef.setData([
                    "video_id": video.id,
                    "user_id": currentUserId,
                    "created_at": FieldValue.serverTimestamp()
                ])
            }
        }
    }
    
    func didTapShare(for video: Video) {
        let items = [URL(string: video.storagePath)].compactMap { $0 }
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
}
