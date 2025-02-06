import UIKit
import FirebaseAuth
import FirebaseFirestore

enum ConnectionType {
    case following
    case followers
    case friends
    case suggested
    
    var title: String {
        switch self {
        case .following: return "Following"
        case .followers: return "Followers"
        case .friends: return "Friends"
        case .suggested: return "Suggested"
        }
    }
}

class ProfileListsViewController : UIViewController {
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private var currentUser: User?
    private var isLoading = false {
        didSet {
            updateLoadingState()
        }
    }
    
    private var selectedType: ConnectionType = .followers {
        didSet {
            updateContent()
        }
    }
    
    private var filteredUsers: [User] = []
    private var users: [User] = [] {
        didSet {
            filteredUsers = users
            tableView.reloadData()
        }
    }
    
    // Track following status for each user
    private var followingStatus: [String: Bool] = [:] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var initialSelectionType: ConnectionType? {
        didSet {
            if isViewLoaded {
                switch initialSelectionType {
                case .following:
                    segmentedControl.selectedSegmentIndex = 0
                case .followers:
                    segmentedControl.selectedSegmentIndex = 1
                case .friends:
                    segmentedControl.selectedSegmentIndex = 2
                case .suggested:
                    segmentedControl.selectedSegmentIndex = 3
                case .none:
                    break
                }
                updateContent()
            }
        }
    }
    
    // MARK: - UI Components
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .black
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let items = [ConnectionType.following.title,
                    ConnectionType.followers.title,
                    ConnectionType.friends.title,
                    ConnectionType.suggested.title]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 1 // Followers by default
        control.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        return control
    }()
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(hex: "#F6F7F9")
        return searchBar
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(ConnectionUserCell.self, forCellReuseIdentifier: ConnectionUserCell.identifier)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .clear
        table.separatorStyle = .none
        return table
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16)
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupUI()
        fetchCurrentUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Keep navigation bar hidden when appearing
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(backButton)
        view.addSubview(usernameLabel)
        view.addSubview(segmentedControl)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            usernameLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            usernameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentedControl.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
            segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            searchBar.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func updateLoadingState() {
        if isLoading {
            activityIndicator.startAnimating()
            emptyStateLabel.isHidden = true
        } else {
            activityIndicator.stopAnimating()
            emptyStateLabel.isHidden = !users.isEmpty
            
            // Update empty state message based on current tab
            switch selectedType {
            case .following:
                emptyStateLabel.text = "You aren't following anyone yet"
            case .followers:
                emptyStateLabel.text = "You don't have any followers yet"
            case .friends:
                emptyStateLabel.text = "You don't have any friends yet"
            case .suggested:
                emptyStateLabel.text = "No suggested users available"
            }
        }
    }
    
    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        selectedType = [.following, .followers, .friends, .suggested][sender.selectedSegmentIndex]
    }
    
    // MARK: - Data
    private func fetchCurrentUser() {
        guard let userID = currentUserID else { return }
        
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching current user: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(),
               let user = User(from: data, uid: userID) {
                self.currentUser = user
                self.updateUI(with: user)
                self.loadData() // Load connection data after getting user info
            }
        }
    }
    
    private func updateUI(with user: User) {
        usernameLabel.text = user.username
    }
    
    private func loadData() {
        guard let userID = currentUserID else {
            print("Error: No current user ID")
            return
        }
        
        // Clear previous data and show loading
        users = []
        followingStatus = [:]
        isLoading = true
        
        print("Loading data for type: \(selectedType), userID: \(userID)")
        
        switch selectedType {
        case .following:
            loadFollowing(userID: userID)
        case .followers:
            loadFollowers(userID: userID)
        case .friends:
            loadFriends(userID: userID)
        case .suggested:
            loadSuggested(userID: userID)
        }
    }
    
    private func loadFollowing(userID: String) {
        print("Fetching following for user: \(userID)")
        db.collection("follows")
            .whereField("follower_id", isEqualTo: userID)
            .order(by: "created_at", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching following: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No following documents found")
                    self.isLoading = false
                    return
                }
                
                print("Found \(documents.count) following documents")
                let userIDs = documents.map { $0.get("following_id") as? String ?? "" }
                    .filter { !$0.isEmpty }
                userIDs.forEach { self.followingStatus[$0] = true }
                self.fetchUserDetails(for: userIDs)
            }
    }
    
    private func loadFollowers(userID: String) {
        print("Fetching followers for user: \(userID)")
        db.collection("follows")
            .whereField("following_id", isEqualTo: userID)
            .order(by: "created_at", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching followers: \(error.localizedDescription)")
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No followers documents found")
                    self.isLoading = false
                    return
                }
                
                print("Found \(documents.count) follower documents")
                let userIDs = documents.map { $0.get("follower_id") as? String ?? "" }
                    .filter { !$0.isEmpty }
                
                // Check which followers we follow back
                self.updateFollowingStatus(for: userIDs)
                self.fetchUserDetails(for: userIDs)
            }
    }
    
    private func loadFriends(userID: String) {
        // Implementation needed
    }
    
    private func loadSuggested(userID: String) {
        // Implementation needed
    }
    
    private func fetchUserDetails(for userIDs: [String]) {
        guard !userIDs.isEmpty else {
            print("No user IDs to fetch details for")
            self.users = []
            self.isLoading = false
            return
        }
        
        print("Fetching details for \(userIDs.count) users")
        let group = DispatchGroup()
        var fetchedUsers: [User] = []
        
        for userID in userIDs {
            group.enter()
            
            db.collection("users").document(userID).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("Error fetching user \(userID): \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let user = User(from: data, uid: userID) {
                    fetchedUsers.append(user)
                    print("Successfully fetched user: \(user.username ?? "unknown")")
                } else {
                    print("Failed to create user from data for ID: \(userID)")
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            print("Finished fetching all user details. Found \(fetchedUsers.count) users")
            self.users = fetchedUsers.sorted { ($0.username ?? "") < ($1.username ?? "") }
            self.isLoading = false
        }
    }
    
    private func updateFollowingStatus(for userIDs: [String]) {
        guard let currentUserID = currentUserID else { return }
        
        for userID in userIDs {
            let documentID = "\(currentUserID)_\(userID)"
            db.collection("follows").document(documentID)
                .getDocument { [weak self] snapshot, error in
                    if let exists = snapshot?.exists {
                        self?.followingStatus[userID] = exists
                    }
                }
        }
    }
    
    private func toggleFollow(for user: User) {
        guard let currentUserID = currentUserID else { return }
        
        let targetUserID = user.uid
        let documentID = "\(currentUserID)_\(targetUserID)" // Create document ID in format followerId_following_id
        
        let isCurrentlyFollowing = followingStatus[targetUserID] ?? false
        
        if isCurrentlyFollowing {
            // Unfollow
            db.collection("follows").document(documentID).delete { [weak self] error in
                if let error = error {
                    print("Error unfollowing user: \(error.localizedDescription)")
                    return
                }
                
                // Update local state
                self?.followingStatus[targetUserID] = false
            }
        } else {
            // Follow
            let data: [String: Any] = [
                "follower_id": currentUserID,
                "following_id": targetUserID,
                "created_at": Timestamp(date: Date())
            ]
            
            db.collection("follows").document(documentID).setData(data) { [weak self] error in
                if let error = error {
                    print("Error following user: \(error.localizedDescription)")
                    return
                }
                
                // Update local state
                self?.followingStatus[targetUserID] = true
            }
        }
    }
    
    private func updateContent() {
        loadData()
    }
}

// MARK: - UITableViewDelegate & DataSource
extension ProfileListsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConnectionUserCell.identifier, for: indexPath) as? ConnectionUserCell else {
            return UITableViewCell()
        }
        
        let user = filteredUsers[indexPath.row]
        let isFollowing = followingStatus[user.uid] ?? false
        cell.configure(with: user, isFollowing: isFollowing)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}

// MARK: - UISearchBarDelegate
extension ProfileListsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                let matchesUsername = user.username?.lowercased().contains(searchText.lowercased()) ?? false
                let matchesName = user.name?.lowercased().contains(searchText.lowercased()) ?? false
                return matchesUsername || matchesName
            }
        }
        tableView.reloadData()
    }
}

// MARK: - ConnectionUserCellDelegate
extension ProfileListsViewController: ConnectionUserCellDelegate {
    func didTapFriendButton(for user: User) {
        toggleFollow(for: user)
    }
}

// MARK: - Supporting Types
protocol ConnectionUserCellDelegate: AnyObject {
    func didTapFriendButton(for user: User)
}

class ConnectionUserCell: UITableViewCell {
    static let identifier = "ConnectionUserCell"
    
    weak var delegate: ConnectionUserCellDelegate?
    private var user: User?
    
    // MARK: - UI Components
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    private let displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private lazy var friendButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 15
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(friendButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(profileImageView)
        contentView.addSubview(displayNameLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(friendButton)
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        displayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        friendButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            
            displayNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            displayNameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
            
            usernameLabel.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: displayNameLabel.leadingAnchor),
            
            friendButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            friendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            friendButton.widthAnchor.constraint(equalToConstant: 80),
            friendButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // MARK: - Configuration
    func configure(with user: User, isFollowing: Bool) {
        self.user = user
        displayNameLabel.text = user.name
        usernameLabel.text = user.username
        
        // Update button state
        updateButtonState(isFollowing: isFollowing)
        
        // Handle avatar image
        if let username = user.username {
            if let avatarUrl = user.avatar,
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
                            self?.profileImageView.subviews.forEach { $0.removeFromSuperview() }
                            self?.profileImageView.backgroundColor = .clear
                            self?.profileImageView.image = image
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
                setupDefaultAvatar(with: username)
            }
        }
    }
    
    private func setupDefaultAvatar(with username: String) {
        // Clear any existing content
        profileImageView.image = nil
        profileImageView.subviews.forEach { $0.removeFromSuperview() }
        
        let firstChar = String(username.prefix(1)).uppercased()
        
        // Generate random color
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        profileImageView.backgroundColor = color
        
        // Create label for initials
        let label = UILabel()
        label.text = firstChar
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        profileImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileImageView.image = nil
        profileImageView.subviews.forEach { $0.removeFromSuperview() }
        displayNameLabel.text = nil
        usernameLabel.text = nil
    }
    
    private func updateButtonState(isFollowing: Bool) {
        if isFollowing {
            friendButton.setTitle("Following", for: .normal)
            friendButton.backgroundColor = .systemGray5
            friendButton.setTitleColor(.black, for: .normal)
        } else {
            friendButton.setTitle("Follow", for: .normal)
            friendButton.backgroundColor = .systemBlue
            friendButton.setTitleColor(.white, for: .normal)
        }
    }
    
    // MARK: - Actions
    @objc private func friendButtonTapped() {
        guard let user = user else { return }
        delegate?.didTapFriendButton(for: user)
    }
}
