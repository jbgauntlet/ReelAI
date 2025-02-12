import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol FriendRequestCellDelegate: AnyObject {
    func didTapAccept(for notification: Notification)
    func didTapDecline(for notification: Notification)
}

class NotificationsViewController: UIViewController {
    
    // MARK: - Properties
    private var notifications: [Notification] = []
    private var notificationsListener: ListenerRegistration?
    
    // MARK: - UI Components
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Notifications"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["All", "Friend Requests"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.alwaysBounceVertical = true
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No notifications yet"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupActions()
        fetchNotifications()
    }
    
    deinit {
        notificationsListener?.remove()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(NotificationCell.self, forCellWithReuseIdentifier: NotificationCell.identifier)
        collectionView.register(FriendRequestCell.self, forCellWithReuseIdentifier: "FriendRequestCell")
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        segmentedControl.addTarget(self, action: #selector(handleSegmentChange), for: .valueChanged)
    }
    
    // MARK: - Data Fetching
    private func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener
        notificationsListener?.remove()
        
        let db = Firestore.firestore()
        let query: Query
        
        if segmentedControl.selectedSegmentIndex == 0 {
            // All notifications
            query = db.collection("notifications")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
                .limit(to: 50)
        } else {
            // Only pending friend requests (exclude accepted ones)
            query = db.collection("notifications")
                .whereField("user_id", isEqualTo: userId)
                .whereField("type", isEqualTo: "friend_request")
                .whereField("read", isEqualTo: false)
                .order(by: "created_at", descending: true)
        }
        
        notificationsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else {
                self?.emptyStateLabel.isHidden = false
                return
            }
            
            // Process notifications and validate friend requests
            let notificationsWithValidation = documents.compactMap { document -> (Notification, String)? in
                guard let notification = Notification(from: document),
                      let relatedId = notification.relatedId else {
                    return nil
                }
                
                // Skip friend request accepted notifications in Friend Requests tab
                if self.segmentedControl.selectedSegmentIndex == 1 && notification.type == "friend_request_accepted" {
                    return nil
                }
                
                return (notification, relatedId)
            }
            
            // Validate friend request notifications by checking if the friend request still exists
            let batch = db.batch()
            let group = DispatchGroup()
            var validNotifications: [Notification] = []
            var hasGhostNotifications = false
            
            for (notification, relatedId) in notificationsWithValidation {
                if notification.type == "friend_request" {
                    group.enter()
                    db.collection("friend_requests").document(relatedId).getDocument { snapshot, error in
                        defer { group.leave() }
                        
                        if let exists = snapshot?.exists, exists {
                            validNotifications.append(notification)
                        } else {
                            // Friend request doesn't exist, clean up the ghost notification
                            batch.deleteDocument(db.collection("notifications").document(notification.id))
                            hasGhostNotifications = true
                        }
                    }
                } else {
                    validNotifications.append(notification)
                }
            }
            
            group.notify(queue: .main) {
                // Commit cleanup batch if needed
                if hasGhostNotifications {
                    batch.commit { error in
                        if let error = error {
                            print("Error cleaning up ghost notifications: \(error.localizedDescription)")
                        }
                        self.updateUI(with: validNotifications)
                    }
                } else {
                    self.updateUI(with: validNotifications)
                }
                
                // Update badge in profile
                if let profileVC = self.presentingViewController as? ProfileViewController {
                    profileVC.updateUnreadBadge(hasUnread: false)
                }
            }
        }
    }
    
    private func updateUI(with notifications: [Notification]) {
        self.notifications = notifications
        
        // Update empty state based on current filter
        if segmentedControl.selectedSegmentIndex == 1 {
            // Friend Requests tab - only show for pending friend requests
            let hasPendingRequests = notifications.contains { $0.type == "friend_request" }
            emptyStateLabel.text = "No friend requests"
            emptyStateLabel.isHidden = hasPendingRequests
        } else {
            // All notifications tab
            emptyStateLabel.text = "No notifications yet"
            emptyStateLabel.isHidden = !notifications.isEmpty
        }
        
        collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func handleClose() {
        dismiss(animated: true)
    }
    
    @objc private func handleSegmentChange() {
        fetchNotifications()
    }
    
    private func markAsRead(_ notification: Notification) {
        let db = Firestore.firestore()
        db.collection("notifications").document(notification.id).updateData([
            "read": true
        ])
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        // Mark as read
        markAsRead(notification)
        
        // Handle different notification types
        switch notification.type {
        case "friend_request_accepted":
            // Navigate to the friend's profile
            if let friendshipId = notification.relatedId {
                let components = friendshipId.split(separator: "_")
                if components.count == 2,
                   let currentUserId = Auth.auth().currentUser?.uid {
                    let friendId = String(currentUserId == components[0] ? components[1] : components[0])
                    let profileVC = PublicProfileViewController()
                    profileVC.userId = friendId
                    let nav = UINavigationController(rootViewController: profileVC)
                    present(nav, animated: true)
                }
            }
            
        case "friend_request":
            // Already handled by the accept/decline buttons
            break
            
        case "comment":
            if let videoId = notification.relatedId {
                let commentsVC = CommentsViewController()
                commentsVC.videoId = videoId
                present(commentsVC, animated: true)
            }
            
        case "like", "follow":
            if let userId = notification.relatedId {
                let profileVC = PublicProfileViewController()
                profileVC.userId = userId
                let nav = UINavigationController(rootViewController: profileVC)
                present(nav, animated: true)
            }
            
        default:
            break
        }
    }
    
    private func deleteNotification(_ notification: Notification) {
        let db = Firestore.firestore()
        db.collection("notifications").document(notification.id).delete { [weak self] error in
            if let error = error {
                print("Error deleting notification: \(error.localizedDescription)")
            } else {
                // Remove from local array and update UI
                if let index = self?.notifications.firstIndex(where: { $0.id == notification.id }) {
                    self?.notifications.remove(at: index)
                    self?.updateUI(with: self?.notifications ?? [])
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension NotificationsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let notification = notifications[indexPath.item]
        
        if notification.type == "friend_request" {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendRequestCell", for: indexPath) as? FriendRequestCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: notification)
            cell.delegate = self
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NotificationCell.identifier, for: indexPath) as? NotificationCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: notification)
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let notification = notifications[indexPath.item]
        handleNotificationTap(notification)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let notification = notifications[indexPath.item]
        let height: CGFloat = notification.type == "friend_request" ? 100 : 80 // Friend request cells are taller
        return CGSize(width: collectionView.bounds.width, height: height)
    }
}

// MARK: - FriendRequestCellDelegate
extension NotificationsViewController: FriendRequestCellDelegate {
    func didTapAccept(for notification: Notification) {
        guard let requestId = notification.relatedId else { return }
        
        let db = Firestore.firestore()
        db.collection("friend_requests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let senderId = data["sender_id"] as? String,
                  let receiverId = data["receiver_id"] as? String else {
                return
            }
            
            // Create friendship
            let friendshipId1 = "\(senderId)_\(receiverId)"
            let friendshipId2 = "\(receiverId)_\(senderId)"
            
            let batch = db.batch()
            
            // Add both friendship documents
            let friendship1Ref = db.collection("friendships").document(friendshipId1)
            batch.setData([
                "user1_id": senderId,
                "user2_id": receiverId,
                "created_at": FieldValue.serverTimestamp()
            ], forDocument: friendship1Ref)
            
            let friendship2Ref = db.collection("friendships").document(friendshipId2)
            batch.setData([
                "user1_id": receiverId,
                "user2_id": senderId,
                "created_at": FieldValue.serverTimestamp()
            ], forDocument: friendship2Ref)
            
            // Delete the friend request
            batch.deleteDocument(db.collection("friend_requests").document(requestId))
            
            // Mark notification as read
            batch.updateData(["read": true], forDocument: db.collection("notifications").document(notification.id))
            
            // Create notification for sender
            let acceptanceNotificationRef = db.collection("notifications").document()
            batch.setData([
                "user_id": senderId,
                "type": "friend_request_accepted",
                "content": "accepted your friend request",
                "related_id": receiverId,
                "created_at": FieldValue.serverTimestamp(),
                "read": false
            ], forDocument: acceptanceNotificationRef)
            
            batch.commit { error in
                if let error = error {
                    print("Error accepting friend request: \(error.localizedDescription)")
                } else {
                    self?.fetchNotifications()
                }
            }
        }
    }
    
    func didTapDecline(for notification: Notification) {
        guard let requestId = notification.relatedId else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete the friend request
        batch.deleteDocument(db.collection("friend_requests").document(requestId))
        
        // Mark notification as read
        batch.updateData(["read": true], forDocument: db.collection("notifications").document(notification.id))
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error declining friend request: \(error.localizedDescription)")
            } else {
                self?.fetchNotifications()
            }
        }
    }
}

// MARK: - NotificationCellDelegate
extension NotificationsViewController: NotificationCellDelegate {
    func didTapDelete(for notification: Notification) {
        deleteNotification(notification)
    }
} 