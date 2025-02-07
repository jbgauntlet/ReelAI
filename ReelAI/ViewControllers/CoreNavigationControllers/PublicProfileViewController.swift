//
//  PublicProfileViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/4/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class PublicProfileViewController: UIViewController {
    var userId: String?
    private var userVideos: [Video] = []
    private var videosListener: ListenerRegistration?
    private let transition = HorizontalCoverTransition()
    private var isOwnProfile: Bool = false
    
    // Remove duplicate properties
    private var isFriend: Bool = false {
        didSet {
            updateFriendButton()
        }
    }
    
    private var hasPendingRequest: Bool = false {
        didSet {
            updateFriendButton()
        }
    }
    
    private let actionsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 10
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let friendButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray6
        button.setTitle("Message", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 50
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.alignment = .center
        sv.spacing = 30
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private var followersLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var followingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var likesLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let followButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ProfileVideoThumbnailCell.self, forCellWithReuseIdentifier: "ProfileVideoThumbnailCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        transitioningDelegate = self
        checkIfOwnProfile()
        setupUI()
        setupCollectionView()
        fetchUserData()
        fetchUserVideos()
        fetchLikesCount()
    }
    
    private func checkIfOwnProfile() {
        if let currentUserId = Auth.auth().currentUser?.uid,
           let profileUserId = userId {
            isOwnProfile = currentUserId == profileUserId
            actionsStackView.isHidden = isOwnProfile
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(avatarImageView)
        headerView.addSubview(usernameLabel)
        headerView.addSubview(statsStackView)
        headerView.addSubview(actionsStackView)
        headerView.addSubview(bioLabel)
        
        // Add stat views to stack
        ["Following", "Followers", "Likes"].forEach { title in
            let statView = createStatView(title: title)
            statsStackView.addArrangedSubview(statView)
        }
        
        actionsStackView.addArrangedSubview(messageButton)
        actionsStackView.addArrangedSubview(followButton)
        actionsStackView.addArrangedSubview(friendButton)
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            avatarImageView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            usernameLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            usernameLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            statsStackView.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 16),
            statsStackView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            statsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: headerView.leadingAnchor, constant: 20),
            statsStackView.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -20),
        ])
        
        // Create different constraints based on whether it's own profile
        if isOwnProfile {
            NSLayoutConstraint.activate([
                bioLabel.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 16),
                bioLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
                bioLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -32),
                bioLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
            ])
        } else {
            NSLayoutConstraint.activate([
                actionsStackView.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 16),
                actionsStackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
                actionsStackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                actionsStackView.heightAnchor.constraint(equalToConstant: 40),
                
                bioLabel.topAnchor.constraint(equalTo: actionsStackView.bottomAnchor, constant: 16),
                bioLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
                bioLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -32),
                bioLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16)
            ])
        }
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 90)
        ])
        
        followButton.addTarget(self, action: #selector(handleFollowTap), for: .touchUpInside)
        friendButton.addTarget(self, action: #selector(handleFriendTap), for: .touchUpInside)
        messageButton.addTarget(self, action: #selector(handleMessageTap), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        // Check initial friendship status
        checkFriendshipStatus()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func createStatView(title: String) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        countLabel.text = "0"
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.text = title
        titleLabel.textColor = .gray
        
        stackView.addArrangedSubview(countLabel)
        stackView.addArrangedSubview(titleLabel)

        // Store references to update later
        switch title {
        case "Following":
            followingLabel = countLabel
        case "Followers":
            followersLabel = countLabel
        case "Likes":
            likesLabel = countLabel
        default:
            break
        }
        
        return stackView
    }
    
    // MARK: - Data Fetching
    private func fetchUserData() {
        guard let userId = userId else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data() else { return }
            
            DispatchQueue.main.async {
                self.usernameLabel.text = data["username"] as? String
                self.bioLabel.text = data["bio"] as? String
                
                // Handle avatar image
                if let username = data["username"] as? String {
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
                                    // Clear any existing subviews (like default avatar label)
                                    self?.avatarImageView.subviews.forEach { $0.removeFromSuperview() }
                                    self?.avatarImageView.backgroundColor = .clear
                                    self?.avatarImageView.image = image
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
            
            // Only check follow status if it's not the user's own profile
            if !self.isOwnProfile {
                self.checkFollowStatus()
            }
        }
        
        // Fetch followers and following counts
        fetchFollowCounts()
    }
    
    private func fetchUserVideos() {
        guard let userId = userId else { return }
        
        let db = Firestore.firestore()
        videosListener = db.collection("videos")
            .whereField("creator_id", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                self?.userVideos = documents.compactMap { Video(from: $0) }
                self?.collectionView.reloadData()
            }
    }
    
    private func fetchFollowCounts() {
        guard let userId = userId else { return }
        
        let db = Firestore.firestore()
        
        // Fetch followers count
        db.collection("follows")
            .whereField("following_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, _ in
                let count = snapshot?.documents.count ?? 0
                self?.followersLabel.text = "\(count)"
            }
        
        // Fetch following count
        db.collection("follows")
            .whereField("follower_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, _ in
                let count = snapshot?.documents.count ?? 0
                self?.followingLabel.text = "\(count)"
            }
    }
    
    private func fetchLikesCount() {
        guard let userId = userId else { return }
        let db = Firestore.firestore()
        
        // Fetch total likes across all user's videos
        db.collection("videos")
            .whereField("creator_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let totalLikes = documents.reduce(0) { $0 + (($1.data()["likes_count"] as? Int) ?? 0) }
                self?.likesLabel.text = "\(totalLikes)"
            }
    }
    
    private func checkFollowStatus() {
        guard let userId = userId,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("follows")
            .whereField("follower_id", isEqualTo: currentUserId)
            .whereField("following_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, _ in
                let isFollowing = !(snapshot?.documents.isEmpty ?? true)
                self?.updateFollowButton(isFollowing: isFollowing)
            }
    }
    
    private func setupDefaultAvatar(with username: String) {
        // Clear any existing content
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        
        let firstChar = String(username.prefix(1)).uppercased()
        
        // Generate random color
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        
        // Create label for initials
        let label = UILabel()
        label.text = firstChar
        label.font = .systemFont(ofSize: 40, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
    
    private func updateFollowButton(isFollowing: Bool) {
        // Update button appearance
        followButton.backgroundColor = isFollowing ? .systemGray5 : .systemBlue
        followButton.setTitle(isFollowing ? "Following" : "Follow", for: .normal)
        followButton.setTitleColor(isFollowing ? .label : .white, for: .normal)
        
        // Animate the change
        UIView.animate(withDuration: 0.2) {
            self.followButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.followButton.transform = .identity
            }
        }
    }
    
    private func updateFriendButton() {
        // Animate the change
        UIView.animate(withDuration: 0.2) {
            self.friendButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.friendButton.transform = .identity
            }
        }

        if isFriend {
            friendButton.setTitle("Friends", for: .normal)
            friendButton.backgroundColor = .systemGray5
            friendButton.setTitleColor(.black, for: .normal)
        } else if hasPendingRequest {
            // Check if we're the sender or receiver
            guard let currentUserId = Auth.auth().currentUser?.uid,
                  let profileUserId = userId else { return }
            
            let db = Firestore.firestore()
            let requestId = "\(currentUserId)_\(profileUserId)"
            
            db.collection("friend_requests").document(requestId).getDocument { [weak self] snapshot, _ in
                guard let self = self else { return }
                
                if snapshot?.exists == true {
                    // We sent the request
                    self.friendButton.setTitle("Pending", for: .normal)
                } else {
                    // We received the request
                    self.friendButton.setTitle("Respond", for: .normal)
                }
                self.friendButton.backgroundColor = .systemGray5
                self.friendButton.setTitleColor(.black, for: .normal)
            }
        } else {
            friendButton.setTitle("Add Friend", for: .normal)
            friendButton.backgroundColor = .systemBlue
            friendButton.setTitleColor(.white, for: .normal)
        }
    }
    
    private func checkFriendshipStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let profileUserId = userId else { return }
        
        let db = Firestore.firestore()
        
        // Check if they are already friends
        let friendshipId1 = "\(currentUserId)_\(profileUserId)"
        let friendshipId2 = "\(profileUserId)_\(currentUserId)"
        
        db.collection("friendships")
            .whereField(FieldPath.documentID(), in: [friendshipId1, friendshipId2])
            .getDocuments { [weak self] snapshot, error in
                if let exists = snapshot?.documents.first?.exists {
                    self?.isFriend = exists
                    return
                }
                
                // If not friends, check for pending requests
                let requestId1 = "\(currentUserId)_\(profileUserId)"
                let requestId2 = "\(profileUserId)_\(currentUserId)"
                
                db.collection("friend_requests")
                    .whereField(FieldPath.documentID(), in: [requestId1, requestId2])
                    .whereField("status", isEqualTo: "pending")
                    .getDocuments { [weak self] snapshot, error in
                        self?.hasPendingRequest = !(snapshot?.documents.isEmpty ?? true)
                    }
            }
    }
    
    // MARK: - Actions
    @objc private func handleFollowTap() {
        guard let userId = userId,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let followRef = db.collection("follows").document("\(currentUserId)_\(userId)")
        
        followRef.getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let exists = snapshot?.exists else { return }
            
            // Optimistically update UI
            let isCurrentlyFollowing = exists
            self.updateFollowButton(isFollowing: !isCurrentlyFollowing)
            
            // Update followers count optimistically
            let currentFollowers = Int(self.followersLabel.text?.components(separatedBy: "\n").first ?? "0") ?? 0
            let newCount = isCurrentlyFollowing ? currentFollowers - 1 : currentFollowers + 1
            self.followersLabel.text = "\(newCount)"
            
            if exists {
                // Unfollow
                followRef.delete { [weak self] error in
                    if let error = error {
                        // Revert UI if error
                        self?.updateFollowButton(isFollowing: true)
                        self?.followersLabel.text = "\(currentFollowers)"
                        print("Error unfollowing: \(error.localizedDescription)")
                    }
                }
            } else {
                // Follow
                let data: [String: Any] = [
                    "follower_id": currentUserId,
                    "following_id": userId,
                    "created_at": FieldValue.serverTimestamp()
                ]
                
                followRef.setData(data) { [weak self] error in
                    if let error = error {
                        // Revert UI if error
                        self?.updateFollowButton(isFollowing: false)
                        self?.followersLabel.text = "\(currentFollowers)"
                        print("Error following: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @objc private func handleFriendTap() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let profileUserId = userId else { return }
        
        let db = Firestore.firestore()
        
        if isFriend {
            // Show action sheet to unfriend
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Unfriend", style: .destructive) { [weak self] _ in
                self?.unfriendUser()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            
        } else if hasPendingRequest {
            // Check if we're the sender or receiver
            let requestId = "\(currentUserId)_\(profileUserId)"
            let reverseRequestId = "\(profileUserId)_\(currentUserId)"
            
            db.collection("friend_requests")
                .whereField(FieldPath.documentID(), in: [requestId, reverseRequestId])
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self,
                          let document = snapshot?.documents.first else { return }
                    
                    let isReceiver = document.documentID == reverseRequestId
                    
                    if isReceiver {
                        // Show action sheet to accept/decline
                        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
                            self?.handleFriendRequestResponse(requestId: reverseRequestId, accept: true)
                        })
                        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { [weak self] _ in
                            self?.handleFriendRequestResponse(requestId: reverseRequestId, accept: false)
                        })
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                        self.present(alert, animated: true)
                    } else {
                        // Show action sheet to cancel request
                        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Cancel Request", style: .destructive) { [weak self] _ in
                            self?.cancelFriendRequest(requestId: requestId)
                        })
                        alert.addAction(UIAlertAction(title: "Back", style: .cancel))
                        self.present(alert, animated: true)
                    }
                }
        } else {
            // Send friend request
            let requestId = "\(currentUserId)_\(profileUserId)"
            
            let requestData: [String: Any] = [
                "sender_id": currentUserId,
                "receiver_id": profileUserId,
                "status": "pending",
                "created_at": FieldValue.serverTimestamp(),
                "updated_at": FieldValue.serverTimestamp()
            ]
            
            db.collection("friend_requests").document(requestId).setData(requestData) { [weak self] error in
                if error == nil {
                    self?.hasPendingRequest = true
                    
                    // Create notification for receiver
                    let notificationData: [String: Any] = [
                        "user_id": profileUserId,
                        "type": "friend_request",
                        "content": "You have a new friend request",
                        "related_id": requestId,
                        "created_at": FieldValue.serverTimestamp(),
                        "read": false
                    ]
                    
                    db.collection("notifications").addDocument(data: notificationData)
                }
            }
        }
    }
    
    private func handleFriendRequestResponse(requestId: String, accept: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let profileUserId = userId else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete the friend request
        let requestRef = db.collection("friend_requests").document(requestId)
        batch.deleteDocument(requestRef)
        
        if accept {
            // Create friendship document
            let friendshipId = "\(currentUserId)_\(profileUserId)"
            let friendshipData: [String: Any] = [
                "user1_id": currentUserId,
                "user2_id": profileUserId,
                "created_at": FieldValue.serverTimestamp()
            ]
            batch.setData(friendshipData, forDocument: db.collection("friendships").document(friendshipId))
            
            // Create notification for sender
            let notificationData: [String: Any] = [
                "user_id": profileUserId,
                "type": "friend_request_accepted",
                "content": "Your friend request was accepted",
                "related_id": friendshipId,
                "created_at": FieldValue.serverTimestamp(),
                "read": false
            ]
            batch.setData(notificationData, forDocument: db.collection("notifications").document())
        }
        
        batch.commit { [weak self] error in
            if error == nil {
                self?.hasPendingRequest = false
                if accept {
                    self?.isFriend = true
                }
            }
        }
    }

    private func cancelFriendRequest(requestId: String) {
        let db = Firestore.firestore()
        db.collection("friend_requests").document(requestId).delete { [weak self] error in
            if error == nil {
                self?.hasPendingRequest = false
            }
        }
    }
    
    private func unfriendUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let profileUserId = userId else { return }
        
        let db = Firestore.firestore()
        let friendshipId1 = "\(currentUserId)_\(profileUserId)"
        let friendshipId2 = "\(profileUserId)_\(currentUserId)"
        
        // Delete both possible friendship documents
        let batch = db.batch()
        batch.deleteDocument(db.collection("friendships").document(friendshipId1))
        batch.deleteDocument(db.collection("friendships").document(friendshipId2))
        
        batch.commit { [weak self] error in
            if error == nil {
                self?.isFriend = false
            }
        }
    }
    
    @objc private func handleMessageTap() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let otherUserId = userId else { return }
        
        let db = Firestore.firestore()
        
        // Check if a conversation already exists
        db.collection("conversations")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking existing conversations: \(error)")
                    return
                }
                
                // Look for an existing conversation with these participants
                if let existingConversation = snapshot?.documents.first(where: { document in
                    let participants = document.data()["participants"] as? [String] ?? []
                    return participants.contains(otherUserId)
                }) {
                    // Open existing conversation
                    if let conversation = Conversation(from: existingConversation) {
                        let chatVC = ChatViewController(conversation: conversation)
                        self.navigationController?.pushViewController(chatVC, animated: true)
                    }
                } else {
                    // Create a new conversation
                    let conversationData: [String: Any] = [
                        "participants": [currentUserId, otherUserId],
                        "created_at": FieldValue.serverTimestamp(),
                        "last_message": "",
                        "last_message_timestamp": FieldValue.serverTimestamp()
                    ]
                    
                    db.collection("conversations").addDocument(data: conversationData) { [weak self] error in
                        if let error = error {
                            print("Error creating conversation: \(error)")
                            return
                        }
                        
                        // Fetch the newly created conversation and open chat
                        if let document = snapshot?.documents.first,
                           let conversation = Conversation(from: document) {
                            let chatVC = ChatViewController(conversation: conversation)
                            self?.navigationController?.pushViewController(chatVC, animated: true)
                        }
                    }
                }
            }
    }
    
    @objc private func handleBack() {
        dismiss(animated: true)
    }
    
    deinit {
        videosListener?.remove()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension PublicProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileVideoThumbnailCell", for: indexPath) as! ProfileVideoThumbnailCell
        cell.configure(with: userVideos[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 2) / 3 // 2 is total spacing between items
        return CGSize(width: width, height: width * 16/9)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videoScrollFeedVC = VideoScrollFeedViewController(videos: userVideos, startingIndex: indexPath.item)
        videoScrollFeedVC.modalPresentationStyle = .fullScreen
        present(videoScrollFeedVC, animated: true)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension PublicProfileViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = true
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = false
        return transition
    }
}
