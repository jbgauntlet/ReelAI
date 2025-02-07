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
        
        // Make the stack view tappable
        stackView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(statTapped(_:)))
        stackView.addGestureRecognizer(tapGesture)
        
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
        button.setBackgroundImage(UIImage.from(color: UIColor(hex: "EEEEEF")), for: .normal)
        button.setBackgroundImage(UIImage.from(color: .darkGray), for: .highlighted)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.layer.borderWidth = 0
        button.setTitleColor(.black, for: .highlighted)
        return button
    }()
    
    private let shareProfileButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Share Profile", for: .normal)
        button.setBackgroundImage(UIImage.from(color: UIColor(hex: "EEEEEF")), for: .normal)
        button.setBackgroundImage(UIImage.from(color: .darkGray), for: .highlighted)
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.layer.borderWidth = 0
        button.setTitleColor(.black, for: .highlighted)
        return button
    }()
    
    private let addFriendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "person.badge.plus", withConfiguration: config), for: .normal)
        button.setBackgroundImage(UIImage.from(color: UIColor(hex: "EEEEEF")), for: .normal)
        button.setBackgroundImage(UIImage.from(color: .darkGray), for: .highlighted)
        button.tintColor = .black
        button.layer.cornerRadius = 15
        button.clipsToBounds = true
        button.layer.borderWidth = 0
        button.setTitleColor(.black, for: .highlighted)
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
        let sc = UISegmentedControl()
        VideoSection.allCases.enumerated().forEach { index, section in
            sc.insertSegment(withTitle: section.title, at: index, animated: false)
        }
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let videoCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0  // No spacing between items in the same row
        layout.minimumLineSpacing = 0       // No spacing between rows
        layout.sectionInset = .zero         // No section insets
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ProfileVideoThumbnailCell.self, forCellWithReuseIdentifier: "ProfileVideoThumbnailCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.alwaysBounceVertical = true
        return cv
    }()
    
    private let optionsButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "line.horizontal.3", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let notificationButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        button.setImage(UIImage(systemName: "bell.fill", withConfiguration: config), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let unreadBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 5
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        fetchUserData()
        fetchVideos()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Remove scrollView and add contentView directly to main view
        view.addSubview(contentView)
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statsStackView)
        
        // Add stat views first
        ["Following", "Followers", "Likes"].forEach { title in
            statsStackView.addArrangedSubview(createStatView(title: title))
        }
        
        contentView.addSubview(buttonStackView)
        
        // Add buttons to button stack view
        buttonStackView.addArrangedSubview(editProfileButton)
        buttonStackView.addArrangedSubview(shareProfileButton)
        buttonStackView.addArrangedSubview(addFriendButton)
        
        contentView.addSubview(bioLabel)
        contentView.addSubview(addBioButton)
        contentView.addSubview(sectionSelector)
        contentView.addSubview(videoCollectionView)
        
        // Setup section selector
        sectionSelector.selectedSegmentIndex = 0
        sectionSelector.removeAllSegments()
        VideoSection.allCases.enumerated().forEach { index, section in
            sectionSelector.insertSegment(withTitle: section.title, at: index, animated: false)
        }
        sectionSelector.selectedSegmentIndex = 0
        
        view.addSubview(optionsButton)
        view.addSubview(notificationButton)
        notificationButton.addSubview(unreadBadge)
        
        videoCollectionView.delegate = self
        videoCollectionView.dataSource = self
        
        let padding: CGFloat = 16
        let tabBarHeight: CGFloat = 90 // Match MainTabBarController's tab bar height
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
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
            videoCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            optionsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            optionsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            optionsButton.widthAnchor.constraint(equalToConstant: 44),
            optionsButton.heightAnchor.constraint(equalToConstant: 44),
            
            notificationButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            notificationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notificationButton.widthAnchor.constraint(equalToConstant: 44),
            notificationButton.heightAnchor.constraint(equalToConstant: 44),
            
            unreadBadge.topAnchor.constraint(equalTo: notificationButton.topAnchor, constant: 2),
            unreadBadge.trailingAnchor.constraint(equalTo: notificationButton.trailingAnchor, constant: -2),
            unreadBadge.widthAnchor.constraint(equalToConstant: 10),
            unreadBadge.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
    
    private func setupConstraints() {
        // No additional constraints needed as setupUI handles all constraints
    }
    
    private func setupActions() {
        sectionSelector.addTarget(self, action: #selector(sectionChanged), for: .valueChanged)
        editProfileButton.addTarget(self, action: #selector(editProfileTapped), for: .touchUpInside)
        shareProfileButton.addTarget(self, action: #selector(shareProfileTapped), for: .touchUpInside)
        addFriendButton.addTarget(self, action: #selector(addFriendTapped), for: .touchUpInside)
        addBioButton.addTarget(self, action: #selector(addBioTapped), for: .touchUpInside)
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
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
    
    @objc private func optionsButtonTapped() {
        let optionsVC = ProfileOptionsViewController { [weak self] option in
            guard let self = self else { return }
            switch option {
            case .logout:
                GlobalDataManager.shared.logout(from: self)
            }
        }
        present(optionsVC, animated: true)
    }
    
    @objc private func notificationButtonTapped() {
        let notificationsVC = NotificationsViewController()
        notificationsVC.modalPresentationStyle = .fullScreen
        present(notificationsVC, animated: true)
    }
    
    @objc private func statTapped(_ gesture: UITapGestureRecognizer) {
        guard let stackView = gesture.view as? UIStackView,
              let index = statsStackView.arrangedSubviews.firstIndex(of: stackView) else { return }
        
        let profileListsVC = ProfileListsViewController()
        
        // Set the initial selected segment based on which stat was tapped
        switch index {
        case 0: // Following
            profileListsVC.initialSelectionType = .following
        case 1: // Followers
            profileListsVC.initialSelectionType = .followers
        default:
            return
        }
        
        navigationController?.pushViewController(profileListsVC, animated: true)
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
                
                // Handle avatar image
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
        
        fetchCounts()
    }
    
    private func fetchCounts() {
        guard let userId = userId ?? Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Get following count (users that this user follows)
        db.collection("follows")
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
        
        // Get followers count (users that follow this user)
        db.collection("follows")
            .whereField("following_id", isEqualTo: userId)
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
            
        case .bookmarked:
            print("🔖 Fetching bookmarked videos")
            // First get the bookmarked video IDs
            db.collection("video_bookmarks")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No bookmarked videos found")
                        self?.videos = []
                        self?.videoCollectionView.reloadData()
                        return
                    }
                    
                    print("✅ Found \(documents.count) bookmarked videos")
                    let videoIds = documents.compactMap { $0.data()["video_id"] as? String }
                    self?.fetchVideosByIds(videoIds)
                }
            
        case .liked:
            print("❤️ Fetching liked videos")
            // First get the liked video IDs
            db.collection("video_likes")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "created_at", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No liked videos found")
                        self?.videos = []
                        self?.videoCollectionView.reloadData()
                        return
                    }
                    
                    print("✅ Found \(documents.count) liked videos")
                    let videoIds = documents.compactMap { $0.data()["video_id"] as? String }
                    self?.fetchVideosByIds(videoIds)
                }
            
        case .watchHistory:
            print("⏳ Fetching watch history")
            // Get videos from viewed_videos collection
            db.collection("viewed_videos")
                .whereField("user_id", isEqualTo: userId)
                .order(by: "last_viewed", descending: true) // Show most recently viewed first
                .getDocuments { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else {
                        print("❌ No watch history found")
                        self?.videos = []
                        self?.videoCollectionView.reloadData()
                        return
                    }
                    
                    print("✅ Found \(documents.count) watched videos")
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
        
        print("🎯 Fetching details for \(ids.count) videos")
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var fetchedVideos: [Video] = []
        
        for id in ids {
            group.enter()
            db.collection("videos").document(id).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let error = error {
                    print("❌ Error fetching video \(id): \(error.localizedDescription)")
                    return
                }
                
                if let document = snapshot,
                   let video = Video(from: document) {
                    fetchedVideos.append(video)
                    print("✅ Successfully fetched video: \(id)")
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            print("🎬 Finished fetching all videos. Found \(fetchedVideos.count) videos")
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
    
    // Add method to update unread badge
    func updateUnreadBadge(hasUnread: Bool) {
        unreadBadge.isHidden = !hasUnread
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < videos.count,
              let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileVideoThumbnailCell", for: indexPath) as? ProfileVideoThumbnailCell else {
            return UICollectionViewCell()
        }
        
        let video = videos[indexPath.item]
        cell.configure(with: video)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.bounds.width
        let itemWidth = totalWidth / 3  // Exactly three items per row
        let itemHeight = itemWidth * 16/9  // Maintain 16:9 aspect ratio
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0  // No spacing between items in the same row
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0  // No spacing between rows
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < videos.count else { return }
        
        let videoScrollFeedVC = VideoScrollFeedViewController(videos: videos, startingIndex: indexPath.item)
        videoScrollFeedVC.modalPresentationStyle = .fullScreen
        present(videoScrollFeedVC, animated: true)
    }
}

extension UIImage {
    static func from(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
