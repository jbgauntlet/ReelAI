import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddFriendViewController: UIViewController {
    
    // MARK: - Properties
    private var searchTimer: Timer?
    private var searchResults: [User] = []
    private let db = Firestore.firestore()
    
    // MARK: - UI Components
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add Friend"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search by username"
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .onDrag
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        
        searchBar.delegate = self
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            searchBar.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(AddFriendUserSearchCell.self, forCellWithReuseIdentifier: AddFriendUserSearchCell.identifier)
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }
    
    // MARK: - Search
    private func performSearch(with query: String) {
        guard !query.isEmpty else {
            searchResults = []
            collectionView.reloadData()
            return
        }
        
        let lowercaseQuery = query.lowercased()
        print("🔍 Starting search with query: '\(query)' (lowercase: '\(lowercaseQuery)')")
        loadingIndicator.startAnimating()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // First try exact username match
        let exactQuery = db.collection("users")
            .whereField("username_lowercase", isEqualTo: lowercaseQuery)
            .limit(to: 5)
        
        // Then try partial matches with username_lowercase
        let usernameQuery = db.collection("users")
            .whereField("username_lowercase", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("username_lowercase", isLessThan: lowercaseQuery + "\u{f8ff}")
            .limit(to: 5)
        
        // Also try partial matches with name_lowercase
        let nameQuery = db.collection("users")
            .whereField("name_lowercase", isGreaterThanOrEqualTo: lowercaseQuery)
            .whereField("name_lowercase", isLessThan: lowercaseQuery + "\u{f8ff}")
            .limit(to: 5)
        
        // Debug: Let's also try a simple query to get all users
        let debugQuery = db.collection("users").limit(to: 5)
        
        // Execute queries
        let group = DispatchGroup()
        var allResults = Set<User>() // Use Set to avoid duplicates
        
        group.enter()
        exactQuery.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("❌ Exact query error: \(error.localizedDescription)")
                return
            }
            if let documents = snapshot?.documents {
                print("📄 Exact query found \(documents.count) results")
                documents.forEach { document in
                    if document.documentID != currentUserId {
                        print("📝 Exact match document data: \(document.data())")
                        if let user = User(from: document.data(), uid: document.documentID) {
                            allResults.insert(user)
                        }
                    }
                }
            }
        }
        
        group.enter()
        usernameQuery.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("❌ Username query error: \(error.localizedDescription)")
                return
            }
            if let documents = snapshot?.documents {
                print("📄 Username query found \(documents.count) results")
                documents.forEach { document in
                    if document.documentID != currentUserId {
                        print("📝 Username match document data: \(document.data())")
                        if let user = User(from: document.data(), uid: document.documentID) {
                            allResults.insert(user)
                        }
                    }
                }
            }
        }
        
        group.enter()
        nameQuery.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("❌ Name query error: \(error.localizedDescription)")
                return
            }
            if let documents = snapshot?.documents {
                print("📄 Name query found \(documents.count) results")
                documents.forEach { document in
                    if document.documentID != currentUserId {
                        print("📝 Name match document data: \(document.data())")
                        if let user = User(from: document.data(), uid: document.documentID) {
                            allResults.insert(user)
                        }
                    }
                }
            }
        }
        
        // Debug: Get all users to verify data exists
        group.enter()
        debugQuery.getDocuments { snapshot, error in
            defer { group.leave() }
            if let error = error {
                print("❌ Debug query error: \(error.localizedDescription)")
                return
            }
            if let documents = snapshot?.documents {
                print("🔍 Debug: Found \(documents.count) total users in database")
                documents.forEach { document in
                    print("📝 User document: \(document.documentID)")
                    print("   username: \(document.data()["username"] ?? "nil")")
                    print("   username_lowercase: \(document.data()["username_lowercase"] ?? "nil")")
                    print("   name: \(document.data()["name"] ?? "nil")")
                    print("   name_lowercase: \(document.data()["name_lowercase"] ?? "nil")")
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.loadingIndicator.stopAnimating()
            
            // Convert Set to Array and sort by username
            self.searchResults = Array(allResults).sorted { ($0.username ?? "") < ($1.username ?? "") }
            self.collectionView.reloadData()
            
            print("🔍 Final search results: \(self.searchResults.count) users found")
            self.searchResults.forEach { user in
                print("👤 Found user: @\(user.username ?? "no_username") (\(user.name ?? "no_name"))")
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleBack() {
        dismiss(animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension AddFriendViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.performSearch(with: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text, !query.isEmpty else { return }
        searchBar.resignFirstResponder()
        let resultsVC = UserSearchResultsViewController(searchQuery: query)
        navigationController?.pushViewController(resultsVC, animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension AddFriendViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddFriendUserSearchCell.identifier, for: indexPath) as? AddFriendUserSearchCell else {
            return UICollectionViewCell()
        }
        
        let user = searchResults[indexPath.item]
        cell.configure(with: user)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = searchResults[indexPath.item]
        let profileVC = PublicProfileViewController()
        profileVC.userId = user.uid
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 70)
    }
}

// MARK: - AddFriendUserSearchCell
class AddFriendUserSearchCell: UICollectionViewCell {
    static let identifier = "AddFriendUserSearchCell"
    
    // MARK: - Properties
    private var user: User?
    private var isFriend: Bool = false
    private var hasPendingRequest: Bool = false
    
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 25
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addFriendButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.backgroundColor = .systemBackground
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(addFriendButton)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: addFriendButton.leadingAnchor, constant: -12),
            
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            addFriendButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            addFriendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            addFriendButton.widthAnchor.constraint(equalToConstant: 100),
            addFriendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        addFriendButton.addTarget(self, action: #selector(handleFriendTap), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with user: User) {
        self.user = user
        nameLabel.text = user.name
        usernameLabel.text = "@\(user.username ?? "")"
        
        if let avatarUrl = user.avatar,
           let url = URL(string: avatarUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarImageView.image = image
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.setupDefaultAvatar(with: user.username ?? "")
                    }
                }
            }.resume()
        } else {
            setupDefaultAvatar(with: user.username ?? "")
        }
        
        checkFriendshipStatus()
    }
    
    private func setupDefaultAvatar(with username: String) {
        let firstChar = String(username.prefix(1)).uppercased()
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        avatarImageView.image = nil
        
        let label = UILabel()
        label.text = firstChar
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
    
    private func checkFriendshipStatus() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let profileUserId = user?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Check if they are already friends
        let friendshipId1 = "\(currentUserId)_\(profileUserId)"
        let friendshipId2 = "\(profileUserId)_\(currentUserId)"
        
        db.collection("friendships")
            .whereField(FieldPath.documentID(), in: [friendshipId1, friendshipId2])
            .getDocuments { [weak self] snapshot, error in
                if let exists = snapshot?.documents.first?.exists {
                    self?.isFriend = exists
                    self?.updateFriendButton()
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
                        self?.updateFriendButton()
                    }
            }
    }
    
    private func updateFriendButton() {
        if isFriend {
            addFriendButton.setTitle("Unfriend", for: .normal)
            addFriendButton.backgroundColor = .systemRed
            addFriendButton.setTitleColor(.white, for: .normal)
        } else if hasPendingRequest {
            addFriendButton.setTitle("Pending", for: .normal)
            addFriendButton.backgroundColor = .systemGray5
            addFriendButton.setTitleColor(.black, for: .normal)
        } else {
            addFriendButton.setTitle("Add Friend", for: .normal)
            addFriendButton.backgroundColor = .systemBlue
            addFriendButton.setTitleColor(.white, for: .normal)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        nameLabel.text = nil
        usernameLabel.text = nil
        user = nil
        isFriend = false
        hasPendingRequest = false
    }
    
    @objc private func handleFriendTap() {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let profileUserId = user?.uid else { return }
        
        if isFriend {
            // Directly unfriend without showing action sheet
            removeFriend(currentUserId: currentUserId, friendId: profileUserId)
            return
        }
        
        if !hasPendingRequest {
            // Send friend request
            let requestId = "\(currentUserId)_\(profileUserId)"
            
            let requestData: [String: Any] = [
                "sender_id": currentUserId,
                "receiver_id": profileUserId,
                "status": "pending",
                "created_at": FieldValue.serverTimestamp(),
                "updated_at": FieldValue.serverTimestamp()
            ]
            
            let db = Firestore.firestore()
            db.collection("friend_requests").document(requestId).setData(requestData) { [weak self] error in
                if error == nil {
                    self?.hasPendingRequest = true
                    self?.updateFriendButton()
                    
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
    
    private func removeFriend(currentUserId: String, friendId: String) {
        let db = Firestore.firestore()
        let friendshipId1 = "\(currentUserId)_\(friendId)"
        let friendshipId2 = "\(friendId)_\(currentUserId)"
        
        let batch = db.batch()
        
        // Try to delete both possible friendship documents
        batch.deleteDocument(db.collection("friendships").document(friendshipId1))
        batch.deleteDocument(db.collection("friendships").document(friendshipId2))
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
            } else {
                self?.isFriend = false
                self?.updateFriendButton()
            }
        }
    }
} 