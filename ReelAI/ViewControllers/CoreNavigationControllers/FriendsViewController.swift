import UIKit
import FirebaseAuth
import FirebaseFirestore

class FriendsViewController: UIViewController {

    // MARK: - Properties
    private var friends: [User] = []
    private var filteredFriends: [User] = []
    private var friendsListener: ListenerRegistration?
    private let transition = HorizontalCoverTransition()
    
    // MARK: - UI Components
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Friends"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search friends"
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = UIColor(hex: "#F6F7F9")
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
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "No friends yet"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addFriendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "person.badge.plus", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupActions()
        fetchFriends()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerLabel)
        view.addSubview(addFriendButton)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            addFriendButton.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            addFriendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addFriendButton.widthAnchor.constraint(equalToConstant: 44),
            addFriendButton.heightAnchor.constraint(equalToConstant: 44),
            
            searchBar.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
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
        collectionView.register(FriendCell.self, forCellWithReuseIdentifier: FriendCell.identifier)
        
        searchBar.delegate = self
    }
    
    private func setupActions() {
        addFriendButton.addTarget(self, action: #selector(handleAddFriend), for: .touchUpInside)
    }
    
    // MARK: - Data Fetching
    private func fetchFriends() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listener
        friendsListener?.remove()
        
        let db = Firestore.firestore()
        
        // Query friendships where current user is either user1 or user2
        let query1 = db.collection("friendships").whereField("user1_id", isEqualTo: currentUserId)
        let query2 = db.collection("friendships").whereField("user2_id", isEqualTo: currentUserId)
        
        // Combine results from both queries
        let group = DispatchGroup()
        var friendIds = Set<String>()
        
        group.enter()
        query1.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let documents = snapshot?.documents {
                documents.forEach { document in
                    if let user2Id = document.data()["user2_id"] as? String {
                        friendIds.insert(user2Id)
                    }
                }
            }
        }
        
        group.enter()
        query2.getDocuments { [weak self] snapshot, error in
            defer { group.leave() }
            if let documents = snapshot?.documents {
                documents.forEach { document in
                    if let user1Id = document.data()["user1_id"] as? String {
                        friendIds.insert(user1Id)
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if friendIds.isEmpty {
                self.updateUI(with: [])
                return
            }
            
            // Fetch user details for all friends
            let userRefs = friendIds.map { db.collection("users").document($0) }
            db.collection("users").whereField(FieldPath.documentID(), in: Array(friendIds))
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self,
                          let documents = snapshot?.documents else {
                        self?.updateUI(with: [])
                        return
                    }
                    
                    let friends = documents.compactMap { document -> User? in
                        let data = document.data()
                        return User(from: data, uid: document.documentID)
                    }.sorted { ($0.username ?? "") < ($1.username ?? "") }
                    
                    self.updateUI(with: friends)
                }
        }
    }
    
    private func updateUI(with friends: [User]) {
        self.friends = friends
        self.filteredFriends = friends
        self.emptyStateLabel.isHidden = !friends.isEmpty
        self.collectionView.reloadData()
    }
    
    // MARK: - Actions
    @objc private func handleAddFriend() {
        let addFriendVC = AddFriendViewController()
        addFriendVC.modalPresentationStyle = .fullScreen
        addFriendVC.transitioningDelegate = self
        present(addFriendVC, animated: true)
    }
    
    private func handleUnfriend(_ user: User) {
        let alert = UIAlertController(
            title: "Remove Friend",
            message: "Are you sure you want to remove \(user.username ?? "this user") from your friends?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            self?.removeFriend(user)
        })
        
        present(alert, animated: true)
    }
    
    private func removeFriend(_ user: User) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let friendshipId1 = "\(currentUserId)_\(user.uid)"
        let friendshipId2 = "\(user.uid)_\(currentUserId)"
        
        let batch = db.batch()
        
        // Try to delete both possible friendship documents
        batch.deleteDocument(db.collection("friendships").document(friendshipId1))
        batch.deleteDocument(db.collection("friendships").document(friendshipId2))
        
        batch.commit { [weak self] error in
            if let error = error {
                print("Error removing friend: \(error.localizedDescription)")
            } else {
                // Refresh friends list
                self?.fetchFriends()
            }
        }
    }
    
    deinit {
        friendsListener?.remove()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension FriendsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredFriends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FriendCell.identifier, for: indexPath) as? FriendCell else {
            return UICollectionViewCell()
        }
        
        let friend = filteredFriends[indexPath.item]
        cell.configure(with: friend)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let friend = filteredFriends[indexPath.item]
        let profileVC = PublicProfileViewController()
        profileVC.userId = friend.uid
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 70)
    }
}

// MARK: - UISearchBarDelegate
extension FriendsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredFriends = friends
        } else {
            filteredFriends = friends.filter { friend in
                let matchesUsername = friend.username?.lowercased().contains(searchText.lowercased()) ?? false
                let matchesName = friend.name?.lowercased().contains(searchText.lowercased()) ?? false
                return matchesUsername || matchesName
            }
        }
        collectionView.reloadData()
    }
}

// MARK: - FriendCellDelegate
extension FriendsViewController: FriendCellDelegate {
    func didTapMoreOptions(for user: User) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "View Profile", style: .default) { [weak self] _ in
            let profileVC = PublicProfileViewController()
            profileVC.userId = user.uid
            self?.navigationController?.pushViewController(profileVC, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Remove Friend", style: .destructive) { [weak self] _ in
            self?.handleUnfriend(user)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension FriendsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = true
        return transition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.isPresenting = false
        return transition
    }
}

// MARK: - FriendCell
protocol FriendCellDelegate: AnyObject {
    func didTapMoreOptions(for user: User)
}

class FriendCell: UICollectionViewCell {
    static let identifier = "FriendCell"
    
    // MARK: - Properties
    weak var delegate: FriendCellDelegate?
    private var user: User?
    
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
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        button.tintColor = .black
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
        contentView.addSubview(moreButton)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -12),
            
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            moreButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            moreButton.widthAnchor.constraint(equalToConstant: 44),
            moreButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        moreButton.addTarget(self, action: #selector(handleMoreTap), for: .touchUpInside)
    }
    
    // MARK: - Configuration
    func configure(with user: User) {
        self.user = user
        nameLabel.text = user.name
        usernameLabel.text = "@\(user.username ?? "")"
        
        if let avatarUrl = user.avatar,
           let url = URL(string: avatarUrl) {
            // Load avatar image
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
    }
    
    private func setupDefaultAvatar(with username: String) {
        let firstChar = String(username.prefix(1)).uppercased()
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        
        // Remove any existing subviews
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        
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
    
    // MARK: - Actions
    @objc private func handleMoreTap() {
        guard let user = user else { return }
        delegate?.didTapMoreOptions(for: user)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        nameLabel.text = nil
        usernameLabel.text = nil
        user = nil
    }
}
