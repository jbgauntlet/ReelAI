//
//  LivestreamViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/6/25.
//

import UIKit

class InboxViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


////
////  InboxViewController.swift
////  ReelAI
////
////  Created by GauntletAI on 2/6/25.
////
//
//import UIKit
//import FirebaseFirestore
//import FirebaseAuth
//
//protocol FriendRequestCellDelegate: AnyObject {
//    func didTapAccept(for notification: Notification)
//    func didTapDecline(for notification: Notification)
//}
//
//class InboxViewController: UIViewController {
//    
//    // MARK: - Properties
//    private var notifications: [Notification] = []
//    private var notificationsListener: ListenerRegistration?
//    
//    // MARK: - UI Components
//    private let headerLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Inbox"
//        label.font = .systemFont(ofSize: 24, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    private let segmentedControl: UISegmentedControl = {
//        let sc = UISegmentedControl(items: ["All", "Friend Requests"])
//        sc.selectedSegmentIndex = 0
//        sc.translatesAutoresizingMaskIntoConstraints = false
//        return sc
//    }()
//    
//    private let collectionView: UICollectionView = {
//        let layout = UICollectionViewFlowLayout()
//        layout.minimumLineSpacing = 1
//        layout.minimumInteritemSpacing = 1
//        
//        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
//        cv.backgroundColor = .systemBackground
//        cv.alwaysBounceVertical = true
//        cv.translatesAutoresizingMaskIntoConstraints = false
//        return cv
//    }()
//    
//    private let emptyStateLabel: UILabel = {
//        let label = UILabel()
//        label.text = "No notifications yet"
//        label.font = .systemFont(ofSize: 16)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.isHidden = true
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCollectionView()
//        setupActions()
//        fetchNotifications()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        navigationController?.setNavigationBarHidden(true, animated: animated)
//    }
//    
//    // MARK: - Setup
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        
//        view.addSubview(headerLabel)
//        view.addSubview(segmentedControl)
//        view.addSubview(collectionView)
//        view.addSubview(emptyStateLabel)
//        
//        NSLayoutConstraint.activate([
//            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
//            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            
//            segmentedControl.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
//            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            
//            collectionView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
//            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
//            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
//        ])
//    }
//    
//    private func setupCollectionView() {
//        collectionView.delegate = self
//        collectionView.dataSource = self
//        collectionView.register(NotificationCell.self, forCellWithReuseIdentifier: "NotificationCell")
//        collectionView.register(FriendRequestCell.self, forCellWithReuseIdentifier: "FriendRequestCell")
//    }
//    
//    private func setupActions() {
//        segmentedControl.addTarget(self, action: #selector(handleSegmentChange), for: .valueChanged)
//    }
//    
//    // MARK: - Actions
//    @objc private func handleSegmentChange() {
//        fetchNotifications()
//    }
//    
//    // MARK: - Data Fetching
//    private func fetchNotifications() {
//        guard let userId = Auth.auth().currentUser?.uid else { return }
//        
//        // Remove existing listener
//        notificationsListener?.remove()
//        
//        let db = Firestore.firestore()
//        let query: Query
//        
//        if segmentedControl.selectedSegmentIndex == 0 {
//            // All notifications
//            query = db.collection("notifications")
//                .whereField("user_id", isEqualTo: userId)
//                .order(by: "created_at", descending: true)
//        } else {
//            // Only pending friend requests (exclude accepted ones)
//            query = db.collection("notifications")
//                .whereField("user_id", isEqualTo: userId)
//                .whereField("type", isEqualTo: "friend_request")  // Only pending requests
//                .whereField("read", isEqualTo: false)  // Only unread requests
//                .order(by: "created_at", descending: true)
//        }
//        
//        notificationsListener = query.addSnapshotListener { [weak self] snapshot, error in
//            guard let self = self,
//                  let documents = snapshot?.documents else {
//                self?.emptyStateLabel.isHidden = false
//                return
//            }
//            
//            // Process notifications and validate friend requests
//            let notificationsWithValidation = documents.compactMap { document -> (Notification, String)? in
//                let data = document.data()
//                guard let userId = data["user_id"] as? String,
//                      let type = data["type"] as? String,
//                      let content = data["content"] as? String,
//                      let createdAtTimestamp = data["created_at"] as? Timestamp,
//                      let relatedId = data["related_id"] as? String else {
//                    return nil
//                }
//                
//                // Skip friend request accepted notifications in Friend Requests tab
//                if self.segmentedControl.selectedSegmentIndex == 1 && type == "friend_request_accepted" {
//                    return nil
//                }
//                
//                let notification = Notification(id: document.documentID,
//                                             userId: userId,
//                                             type: type,
//                                             content: content,
//                                             relatedId: relatedId,
//                                             createdAt: createdAtTimestamp.dateValue(),
//                                             read: data["read"] as? Bool ?? false)
//                
//                return (notification, relatedId)
//            }
//            
//            // Validate friend request notifications by checking if the friend request still exists
//            let batch = db.batch()
//            let group = DispatchGroup()
//            var validNotifications: [Notification] = []
//            var hasGhostNotifications = false
//            
//            for (notification, relatedId) in notificationsWithValidation {
//                if notification.type == "friend_request" {
//                    group.enter()
//                    db.collection("friend_requests").document(relatedId).getDocument { snapshot, error in
//                        defer { group.leave() }
//                        
//                        if let exists = snapshot?.exists, exists {
//                            validNotifications.append(notification)
//                        } else {
//                            // Friend request doesn't exist, clean up the ghost notification
//                            batch.deleteDocument(db.collection("notifications").document(notification.id))
//                            hasGhostNotifications = true
//                        }
//                    }
//                } else {
//                    validNotifications.append(notification)
//                }
//            }
//            
//            group.notify(queue: .main) {
//                // Commit cleanup batch if needed
//                if hasGhostNotifications {
//                    batch.commit { error in
//                        if let error = error {
//                            print("Error cleaning up ghost notifications: \(error.localizedDescription)")
//                        }
//                        self.updateUI(with: validNotifications)
//                    }
//                } else {
//                    self.updateUI(with: validNotifications)
//                }
//            }
//        }
//    }
//    
//    private func updateUI(with notifications: [Notification]) {
//        self.notifications = notifications
//        
//        // Update empty state based on current filter
//        if segmentedControl.selectedSegmentIndex == 1 {
//            // Friend Requests tab - only show for pending friend requests
//            let hasPendingRequests = notifications.contains { $0.type == "friend_request" }
//            emptyStateLabel.text = "No friend requests"
//            emptyStateLabel.isHidden = hasPendingRequests
//        } else {
//            // All notifications tab
//            emptyStateLabel.text = "No notifications yet"
//            emptyStateLabel.isHidden = !notifications.isEmpty
//        }
//        
//        collectionView.reloadData()
//    }
//    
//    // MARK: - Notification Handling
//    private func markAsRead(_ notification: Notification) {
//        let db = Firestore.firestore()
//        db.collection("notifications").document(notification.id).updateData([
//            "read": true
//        ])
//    }
//    
//    private func handleNotificationTap(_ notification: Notification) {
//        // Mark as read
//        markAsRead(notification)
//        
//        // Handle different notification types
//        switch notification.type {
//        case "friend_request_accepted":
//            // Navigate to the friend's profile
//            if let friendshipId = notification.relatedId {
//                let components = friendshipId.split(separator: "_")
//                if components.count == 2,
//                   let currentUserId = Auth.auth().currentUser?.uid {
//                    let friendId = String(currentUserId == components[0] ? components[1] : components[0])
//                    let profileVC = PublicProfileViewController()
//                    profileVC.userId = friendId
//                    navigationController?.pushViewController(profileVC, animated: true)
//                }
//            }
//            
//        case "friend_request":
//            // Already handled by the accept/decline buttons
//            break
//            
//        // Add more cases for other notification types as needed
//        default:
//            break
//        }
//    }
//    
//    deinit {
//        notificationsListener?.remove()
//    }
//}
//
//// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
//extension InboxViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return notifications.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let notification = notifications[indexPath.item]
//        handleNotificationTap(notification)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let notification = notifications[indexPath.item]
//        
//        if notification.type == "friend_request" {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendRequestCell", for: indexPath) as! FriendRequestCell
//            cell.configure(with: notification)
//            cell.delegate = self
//            return cell
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NotificationCell", for: indexPath) as! NotificationCell
//            cell.configure(with: notification)
//            
//            // Add tap gesture if notification is actionable
//            if notification.type == "friend_request_accepted" {
//                cell.isUserInteractionEnabled = true
//            } else {
//                cell.isUserInteractionEnabled = false
//            }
//            
//            return cell
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let notification = notifications[indexPath.item]
//        let height: CGFloat = notification.type == "friend_request" ? 80 : 70
//        return CGSize(width: collectionView.bounds.width, height: height)
//    }
//}
//
//// MARK: - FriendRequestCellDelegate
//extension InboxViewController: FriendRequestCellDelegate {
//    func didTapAccept(for notification: Notification) {
//        // Handle accept friend request
//        guard let requestId = notification.relatedId else { return }
//        handleFriendRequestResponse(requestId: requestId, accept: true)
//    }
//    
//    func didTapDecline(for notification: Notification) {
//        // Handle decline friend request
//        guard let requestId = notification.relatedId else { return }
//        handleFriendRequestResponse(requestId: requestId, accept: false)
//    }
//    
//    private func handleFriendRequestResponse(requestId: String, accept: Bool) {
//        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
//        
//        let db = Firestore.firestore()
//        let batch = db.batch()
//        
//        // First get the friend request to get sender info
//        db.collection("friend_requests").document(requestId).getDocument { [weak self] snapshot, error in
//            guard let self = self,
//                  let data = snapshot?.data(),
//                  let senderId = data["sender_id"] as? String else { return }
//            
//            // Delete the friend request
//            let requestRef = db.collection("friend_requests").document(requestId)
//            batch.deleteDocument(requestRef)
//            
//            // Find and delete ALL notifications related to this friend request
//            db.collection("notifications")
//                .whereField("related_id", isEqualTo: requestId)
//                .getDocuments { snapshot, error in
//                    guard let documents = snapshot?.documents else { return }
//                    
//                    // Remove all related notifications from UI
//                    let notificationIds = documents.map { $0.documentID }
//                    let indexesToDelete = self.notifications.enumerated()
//                        .filter { notificationIds.contains($0.element.id) }
//                        .map { $0.offset }
//                    
//                    // Delete notifications from Firestore
//                    documents.forEach { document in
//                        // Mark as read before deleting
//                        batch.updateData(["read": true], forDocument: document.reference)
//                        batch.deleteDocument(document.reference)
//                    }
//                    
//                    if accept {
//                        // Create friendship document
//                        let friendshipId = "\(currentUserId)_\(senderId)"
//                        let friendshipData: [String: Any] = [
//                            "user1_id": currentUserId,
//                            "user2_id": senderId,
//                            "created_at": FieldValue.serverTimestamp()
//                        ]
//                        batch.setData(friendshipData, forDocument: db.collection("friendships").document(friendshipId))
//                        
//                        // Create notification for sender (already marked as unread)
//                        let notificationData: [String: Any] = [
//                            "user_id": senderId,
//                            "type": "friend_request_accepted",
//                            "content": "Your friend request was accepted",
//                            "related_id": friendshipId,
//                            "created_at": FieldValue.serverTimestamp(),
//                            "read": false
//                        ]
//                        batch.setData(notificationData, forDocument: db.collection("notifications").document())
//                    }
//                    
//                    // Commit the batch
//                    batch.commit { error in
//                        if let error = error {
//                            print("Error handling friend request: \(error.localizedDescription)")
//                            // If there was an error, refresh the notifications to restore state
//                            DispatchQueue.main.async {
//                                self.fetchNotifications()
//                            }
//                        } else {
//                            // On success, update UI
//                            DispatchQueue.main.async {
//                                // Remove notifications from local array and update UI
//                                var indexPaths = [IndexPath]()
//                                for index in indexesToDelete.sorted(by: >) {
//                                    self.notifications.remove(at: index)
//                                    indexPaths.append(IndexPath(item: index, section: 0))
//                                }
//                                
//                                // Batch delete all cells
//                                if !indexPaths.isEmpty {
//                                    self.collectionView.deleteItems(at: indexPaths)
//                                }
//                                
//                                self.emptyStateLabel.isHidden = !self.notifications.isEmpty
//                            }
//                        }
//                    }
//                }
//        }
//    }
//}
