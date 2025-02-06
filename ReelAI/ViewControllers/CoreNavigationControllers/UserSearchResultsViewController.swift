import UIKit
import FirebaseFirestore
import FirebaseAuth

class UserSearchResultsViewController: UIViewController {
    
    // MARK: - Properties
    private let searchQuery: String
    private var users: [User] = []
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private var isLoading = false
    private var hasMoreResults = true
    
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
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Init
    init(searchQuery: String) {
        self.searchQuery = searchQuery
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
        setupActions()
        performInitialSearch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        titleLabel.text = "Results for \"\(searchQuery)\""
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 10),
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
    private func performInitialSearch() {
        guard !isLoading else { return }
        isLoading = true
        loadingIndicator.startAnimating()
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let query = db.collection("users")
            .whereField("username_lowercase", isGreaterThanOrEqualTo: searchQuery.lowercased())
            .whereField("username_lowercase", isLessThan: searchQuery.lowercased() + "\\uf8ff")
            .limit(to: 20)
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            self.loadingIndicator.stopAnimating()
            
            if let error = error {
                print("Error searching users: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.lastDocument = documents.last
            self.hasMoreResults = !documents.isEmpty
            
            let users = documents.compactMap { document -> User? in
                if document.documentID == currentUserId { return nil }
                return User(from: document.data(), uid: document.documentID)
            }
            
            self.users = users
            self.collectionView.reloadData()
        }
    }
    
    private func loadMoreResults() {
        guard !isLoading,
              hasMoreResults,
              let lastDocument = lastDocument,
              let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        let query = db.collection("users")
            .whereField("username_lowercase", isGreaterThanOrEqualTo: searchQuery.lowercased())
            .whereField("username_lowercase", isLessThan: searchQuery.lowercased() + "\\uf8ff")
            .limit(to: 20)
            .start(afterDocument: lastDocument)
        
        query.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.isLoading = false
            
            if let error = error {
                print("Error loading more users: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.lastDocument = documents.last
            self.hasMoreResults = !documents.isEmpty
            
            let newUsers = documents.compactMap { document -> User? in
                if document.documentID == currentUserId { return nil }
                return User(from: document.data(), uid: document.documentID)
            }
            
            let startIndex = self.users.count
            self.users.append(contentsOf: newUsers)
            
            let indexPaths = (0..<newUsers.count).map { index in
                IndexPath(item: startIndex + index, section: 0)
            }
            
            self.collectionView.insertItems(at: indexPaths)
        }
    }
    
    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension UserSearchResultsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UserSearchCell.identifier, for: indexPath) as? UserSearchCell else {
            return UICollectionViewCell()
        }
        
        let user = users[indexPath.item]
        cell.configure(with: user)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = users[indexPath.item]
        let profileVC = PublicProfileViewController()
        profileVC.userId = user.uid
        navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 70)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let scrollViewHeight = scrollView.frame.height
        
        if offset > contentHeight - scrollViewHeight - 100 {
            loadMoreResults()
        }
    }
} 