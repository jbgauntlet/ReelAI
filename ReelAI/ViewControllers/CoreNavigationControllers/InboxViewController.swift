//
//  InboxViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/6/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol FriendRequestCellDelegate: AnyObject {
    func didTapAccept(for notification: Notification)
    func didTapDecline(for notification: Notification)
}

class InboxViewController: UIViewController {
    
    // MARK: - Properties
    private var notifications: [Notification] = []
    private var notificationsListener: ListenerRegistration?
    
    // MARK: - UI Components
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Inbox"
        label.font = .systemFont(ofSize: 24, weight: .bold)
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
        layout.minimumInteritemSpacing = 1
        
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
        label.textColor = .secondaryLabel
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerLabel)
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            segmentedControl.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(NotificationCell.self, forCellWithReuseIdentifier: "NotificationCell")
        collectionView.register(FriendRequestCell.self, forCellWithReuseIdentifier: "FriendRequestCell")
    }
    
    private func setupActions() {
        segmentedControl.addTarget(self, action: #selector(handleSegmentChange), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func handleSegmentChange() {
        fetchNotifications()
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
        } else {
            // Only friend requests
            query = db.collection("notifications")
                .whereField("user_id", isEqualTo: userId)
                .whereField("type", isEqualTo: "friend_request")
                .order(by: "created_at", descending: true)
        }
        
        notificationsListener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else {
                self?.emptyStateLabel.isHidden = false
                return
            }
            
            self.notifications = documents.compactMap { document in
                let data = document.data()
                guard let userId = data["user_id"] as? String,
                      let type = data["type"] as? String,
                      let content = data["content"] as? String,
                      let createdAtTimestamp = data["created_at"] as? Timestamp else {
                    return nil
                }
                
                return Notification(id: document.documentID,
                                  userId: userId,
                                  type: type,
                                  content: content,
                                  relatedId: data["related_id"] as? String,
                                  createdAt: createdAtTimestamp.dateValue(),
                                  read: data["read"] as? Bool ?? false)
            }
            
            self.emptyStateLabel.isHidden = !self.notifications.isEmpty
            self.collectionView.reloadData()
        }
    }
    
    deinit {
        notificationsListener?.remove()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension InboxViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notifications.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let notification = notifications[indexPath.item]
        
        if notification.type == "friend_request" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendRequestCell", for: indexPath) as! FriendRequestCell
            cell.configure(with: notification)
            cell.delegate = self
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
            cell.configure(with: notification)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let notification = notifications[indexPath.item]
        let height: CGFloat = notification.type == "friend_request" ? 80 : 70
        return CGSize(width: collectionView.bounds.width, height: height)
    }
}

// MARK: - FriendRequestCellDelegate
extension InboxViewController: FriendRequestCellDelegate {
    func didTapAccept(for notification: Notification) {
        // Handle accept friend request
        guard let requestId = notification.relatedId else { return }
        handleFriendRequestResponse(requestId: requestId, accept: true)
    }
    
    func didTapDecline(for notification: Notification) {
        // Handle decline friend request
        guard let requestId = notification.relatedId else { return }
        handleFriendRequestResponse(requestId: requestId, accept: false)
    }
    
    private func handleFriendRequestResponse(requestId: String, accept: Bool) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Get the friend request document
        db.collection("friend_requests").document(requestId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let senderId = data["sender_id"] as? String else { return }
            
            // Delete the friend request
            let requestRef = db.collection("friend_requests").document(requestId)
            batch.deleteDocument(requestRef)
            
            if accept {
                // Create friendship document
                let friendshipId = "\(currentUserId)_\(senderId)"
                let friendshipData: [String: Any] = [
                    "user1_id": currentUserId,
                    "user2_id": senderId,
                    "created_at": FieldValue.serverTimestamp()
                ]
                batch.setData(friendshipData, forDocument: db.collection("friendships").document(friendshipId))
                
                // Create notification for sender
                let notificationData: [String: Any] = [
                    "user_id": senderId,
                    "type": "friend_request_accepted",
                    "content": "Your friend request was accepted",
                    "related_id": friendshipId,
                    "created_at": FieldValue.serverTimestamp(),
                    "read": false
                ]
                batch.setData(notificationData, forDocument: db.collection("notifications").document())
            }
            
            // Commit the batch
            batch.commit()
        }
    }
}
