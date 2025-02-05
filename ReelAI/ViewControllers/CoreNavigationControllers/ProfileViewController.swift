import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

class ProfileViewController: UIViewController {
    
    enum VideoSection: Int, CaseIterable {
        case myVideos = 0
        case watchHistory
        case bookmarked
        case liked
        
        var title: String {
            switch self {
            case .myVideos: return "My Videos"
            case .watchHistory: return "Watch History"
            case .bookmarked: return "Bookmarked"
            case .liked: return "Liked"
            }
        }
    }
    
    // MARK: - Properties
    var userId: String? // User ID to display profile for
    private var selectedSection: VideoSection = .myVideos
    private var videos: [Video] = []
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 50 // Will be half of width/height
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
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
        return stackView
    }
    
    private let buttonStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 10
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let editProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Edit Profile", for: .normal)
        button.backgroundColor = .systemBackground
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        return button
    }()
    
    private let shareProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share Profile", for: .normal)
        button.backgroundColor = .systemBackground
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        return button
    }()
    
    private let addFriendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "person.badge.plus", withConfiguration: config), for: .normal)
        button.backgroundColor = .systemBackground
        button.tintColor = .black
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        return button
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addBioButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add bio", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let sectionSelector: UISegmentedControl = {
        let sc = UISegmentedControl(items: VideoSection.allCases.map { $0.title })
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let videoCollectionView: UICollectionView = {
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
        setupUI()
        setupConstraints()
        setupActions()
        fetchUserData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statsStackView)
        
        // Add stat views
        ["Following", "Followers", "Likes"].forEach { title in
            statsStackView.addArrangedSubview(createStatView(title: title))
        }
        
        contentView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(editProfileButton)
        buttonStackView.addArrangedSubview(shareProfileButton)
        buttonStackView.addArrangedSubview(addFriendButton)
        
        contentView.addSubview(bioLabel)
        contentView.addSubview(addBioButton)
        contentView.addSubview(sectionSelector)
        contentView.addSubview(videoCollectionView)
        
        videoCollectionView.delegate = self
        videoCollectionView.dataSource = self
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 16
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: padding),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            statsStackView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: padding),
            statsStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            buttonStackView.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: padding),
            buttonStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            buttonStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            
            bioLabel.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: padding),
            bioLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            bioLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            addBioButton.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: padding),
            addBioButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            sectionSelector.topAnchor.constraint(equalTo: bioLabel.bottomAnchor, constant: padding),
            sectionSelector.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            sectionSelector.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            
            videoCollectionView.topAnchor.constraint(equalTo: sectionSelector.bottomAnchor, constant: padding),
            videoCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            videoCollectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])
    }
    
    private func setupActions() {
        sectionSelector.addTarget(self, action: #selector(sectionChanged), for: .valueChanged)
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        shareProfileButton.addTarget(self, action: #selector(shareProfileTapped), for: .touchUpInside)
        addFriendButton.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
        addBioButton.addTarget(self, action: #selector(addBioTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func sectionChanged() {
        guard let section = VideoSection(rawValue: sectionSelector.selectedSegmentIndex) else { return }
        selectedSection = section
        fetchVideos()
    }
    
    @objc private func editProfileTapped() {
        let editProfileVC = EditProfileViewController()
        navigationController?.pushViewController(editProfileVC, animated: true)
    }
    
    @objc private func shareProfileTapped() {
        // TODO: Implement share profile
    }
    
    @objc private func addFriendTapped() {
        // TODO: Implement add friend
    }
    
    @objc private func addBioTapped() {
        // TODO: Implement add bio
    }
    
    // MARK: - Data Fetching
    private func fetchUserData() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data(),
                  let username = data["username"] as? String else { return }
            
            DispatchQueue.main.async {
                self.nameLabel.text = username
                
                if let bio = data["bio"] as? String, !bio.isEmpty {
                    self.bioLabel.isHidden = false
                    self.addBioButton.isHidden = true
                    self.bioLabel.text = bio
                } else {
                    self.bioLabel.isHidden = true
                    self.addBioButton.isHidden = false
                }
                
                if let avatarUrl = data["avatar"] as? String,
                   let url = URL(string: avatarUrl) {
                    // TODO: Load avatar image
                } else {
                    self.setupDefaultAvatar(with: username)
                }
            }
        }
        
        fetchCounts()
    }
    
    private func fetchCounts() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Get following count
        db.collection("user_followers")
            .whereField("follower_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                if let count = snapshot?.documents.count {
                    DispatchQueue.main.async {
                        if let followingStack = self?.statsStackView.arrangedSubviews[0] as? UIStackView,
                           let countLabel = followingStack.arrangedSubviews[0] as? UILabel {
                            countLabel.text = String(count)
                        }
                    }
                }
            }
        
        // Get followers count
        db.collection("user_followers")
            .whereField("followed_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                if let count = snapshot?.documents.count {
                    DispatchQueue.main.async {
                        if let followersStack = self?.statsStackView.arrangedSubviews[1] as? UIStackView,
                           let countLabel = followersStack.arrangedSubviews[0] as? UILabel {
                            countLabel.text = String(count)
                        }
                    }
                }
            }
        
        // Get total likes count from all user's videos
        db.collection("videos")
            .whereField("creator_id", isEqualTo: userId)
            .getDocuments { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                var totalLikes = 0
                let group = DispatchGroup()
                
                for doc in documents {
                    group.enter()
                    db.collection("video_likes")
                        .whereField("video_id", isEqualTo: doc.documentID)
                        .getDocuments { snapshot, error in
                            if let likesCount = snapshot?.documents.count {
                                totalLikes += likesCount
                            }
                            group.leave()
                        }
                }
                
                group.notify(queue: .main) {
                    if let likesStack = self?.statsStackView.arrangedSubviews[2] as? UIStackView,
                       let countLabel = likesStack.arrangedSubviews[0] as? UILabel {
                        countLabel.text = String(totalLikes)
                    }
                }
            }
    }
    
    private func fetchVideos() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else {
            print("❌ No user ID available")
            return
        }
        print("🔍 Fetching videos for user: \(userId)")
        print("📱 Current section: \(selectedSection)")
        
        let db = Firestore.firestore()
        
        switch selectedSection {
        case .myVideos:
            print("🎬 Fetching user's own videos")
            db.collection("videos")
                .whereField("creator_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    if let error = error {
                        print("❌ Error fetching videos: \(error.localizedDescription)")
                    } else {
                        print("✅ Got video documents: \(snapshot?.documents.count ?? 0)")
                    }
                    self?.handleVideoSnapshot(snapshot, error)
                }
            
        case .watchHistory:
            print("📺 Fetching watch history")
            db.collection("video_views")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "last_viewed", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No watch history documents found")
                        return
                    }
                    print("✅ Found \(documents.count) watched videos")
                    let videoIds = documents.compactMap { $0.data()["video_id"] as? String }
                    self?.fetchVideosByIds(videoIds)
                }
            
        case .bookmarked:
            print("🔖 Fetching bookmarked videos")
            db.collection("video_bookmarks")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No bookmarked videos found")
                        return
                    }
                    print("✅ Found \(documents.count) bookmarked videos")
                    let videoIds = documents.compactMap { $0.data()["video_id"] as? String }
                    self?.fetchVideosByIds(videoIds)
                }
            
        case .liked:
            print("❤️ Fetching liked videos")
            db.collection("video_likes")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No liked videos found")
                        return
                    }
                    print("✅ Found \(documents.count) liked videos")
                    let videoIds = documents.compactMap { $0.data()["video_id"] as? String }
                    self?.fetchVideosByIds(videoIds)
                }
        }
    }
    
    private func handleVideoSnapshot(_ snapshot: QuerySnapshot?, _ error: Error?) {
        guard let documents = snapshot?.documents else {
            self.videos = []
            self.videoCollectionView.reloadData()
            return
        }
        
        self.videos = documents.compactMap { document in
            return Video(from: document)
        }
        
        DispatchQueue.main.async {
            self.videoCollectionView.reloadData()
        }
    }
    
    private func fetchVideosByIds(_ ids: [String]) {
        guard !ids.isEmpty else {
            self.videos = []
            self.videoCollectionView.reloadData()
            return
        }
        
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var fetchedVideos: [Video] = []
        
        for id in ids {
            group.enter()
            db.collection("videos").document(id).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let document = snapshot,
                   let video = Video(from: document) {
                    fetchedVideos.append(video)
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.videos = fetchedVideos
            self?.videoCollectionView.reloadData()
        }
    }
    
    private func setupDefaultAvatar(with username: String) {
        let firstChar = String(username.prefix(1)).uppercased()
        
        // Generate random color
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        
        // Create label for initials
        let label = UILabel()
        label.text = firstChar
        label.font = UIFont.systemFont(ofSize: 40, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension ProfileViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileVideoThumbnailCell", for: indexPath) as! ProfileVideoThumbnailCell
        cell.configure(with: videos[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 2) / 3 // 2 is total spacing between items
        return CGSize(width: width, height: width * 16/9)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videoScrollFeedVC = VideoScrollFeedViewController(videos: videos, startingIndex: indexPath.item)
        videoScrollFeedVC.modalPresentationStyle = .fullScreen
        present(videoScrollFeedVC, animated: true)
    }
}
