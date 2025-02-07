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
        collectionView.register(UserSearchCell.self, forCellWithReuseIdentifier: UserSearchCell.identifier)
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
        navigationController?.popViewController(animated: true)
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.identifier, for: indexPath) as? UserSearchCell else {
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