//
//  CommentsViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/4/25.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class CommentsViewController: UIViewController {
    var videoId: String?
    private var comments: [Comment] = []
    private var commentsListener: ListenerRegistration?
    
    // Callbacks for optimistic UI updates
    var onCommentAdded: (() -> Void)?
    var onCommentDeleted: (() -> Void)?
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let commentsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.alwaysBounceVertical = true
        return cv
    }()
    
    private let commentInputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        // Add subtle top border
        let borderLayer = CALayer()
        borderLayer.backgroundColor = UIColor.systemGray5.cgColor
        borderLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1)
        view.layer.addSublayer(borderLayer)
        return view
    }()
    
    private let commentTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Add a comment..."
        tf.font = .systemFont(ofSize: 16)
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 20
        // Add padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 40))
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Post", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        setupActions()
        setupKeyboardHandling()
        fetchComments()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Set modal presentation style
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .black.withAlphaComponent(0)
        
        view.addSubview(containerView)
        containerView.addSubview(headerLabel)
        containerView.addSubview(commentsCollectionView)
        containerView.addSubview(commentInputContainer)
        
        commentInputContainer.addSubview(commentTextField)
        commentInputContainer.addSubview(postButton)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            headerLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            commentInputContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            commentInputContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            commentInputContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            commentInputContainer.heightAnchor.constraint(equalToConstant: 80),
            
            commentTextField.leadingAnchor.constraint(equalTo: commentInputContainer.leadingAnchor, constant: 16),
            commentTextField.trailingAnchor.constraint(equalTo: postButton.leadingAnchor, constant: -8),
            commentTextField.centerYAnchor.constraint(equalTo: commentInputContainer.centerYAnchor),
            commentTextField.heightAnchor.constraint(equalToConstant: 40),
            
            postButton.trailingAnchor.constraint(equalTo: commentInputContainer.trailingAnchor, constant: -16),
            postButton.centerYAnchor.constraint(equalTo: commentInputContainer.centerYAnchor),
            postButton.widthAnchor.constraint(equalToConstant: 60),
            
            commentsCollectionView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 16),
            commentsCollectionView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            commentsCollectionView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            commentsCollectionView.bottomAnchor.constraint(equalTo: commentInputContainer.topAnchor)
        ])
        
        // Add tap gesture to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
        
        // Initially position container off screen
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        
        // Add delegate for text field
        commentTextField.delegate = self
    }
    
    private func setupCollectionView() {
        commentsCollectionView.delegate = self
        commentsCollectionView.dataSource = self
        commentsCollectionView.register(CommentCell.self, forCellWithReuseIdentifier: CommentCell.identifier)
    }
    
    private func setupActions() {
        postButton.addTarget(self, action: #selector(handlePost), for: .touchUpInside)
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func animateIn() {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = .black.withAlphaComponent(0.5)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            self.containerView.transform = .identity
        }
    }
    
    private func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3) {
            self.view.backgroundColor = .clear
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        } completion: { _ in
            completion()
        }
    }
    
    // MARK: - Keyboard Handling
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.containerView.transform = .identity
        }
    }
    
    // MARK: - Actions
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) {
            dismiss(animated: true)
        }
    }
    
    @objc private func handlePost() {
        guard let videoId = videoId,
              let userId = Auth.auth().currentUser?.uid,
              let text = commentTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        // Dismiss keyboard first
        commentTextField.resignFirstResponder()
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Create comment document
        let commentRef = db.collection("comments").document()
        let commentId = commentRef.documentID
        
        // Create local comment immediately
        let localComment = Comment(
            id: commentId,
            videoId: videoId,
            userId: userId,
            text: text,
            createdAt: Date()
        )
        
        // Add to local array and update UI immediately
        self.comments.insert(localComment, at: 0) // Insert at top since sorted by newest
        self.headerLabel.text = "\(self.comments.count) comments"
        self.commentsCollectionView.reloadData()
        
        // Clear text field immediately for better UX
        self.commentTextField.text = ""
        
        // Trigger optimistic UI update for the video's comment count
        onCommentAdded?()
        
        let data: [String: Any] = [
            "id": commentId,
            "video_id": videoId,
            "user_id": userId,
            "text": text,
            "created_at": FieldValue.serverTimestamp()
        ]
        batch.setData(data, forDocument: commentRef)
        
        // Update video's comment count
        let videoRef = db.collection("videos").document(videoId)
        batch.updateData([
            "comments_count": FieldValue.increment(Int64(1))
        ], forDocument: videoRef)
        
        // Commit the batch
        batch.commit { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                // If there was an error, remove the optimistically added comment
                if let index = self.comments.firstIndex(where: { $0.id == commentId }) {
                    self.comments.remove(at: index)
                    self.headerLabel.text = "\(self.comments.count) comments"
                    self.commentsCollectionView.reloadData()
                }
                // Revert the optimistic UI update for the video's comment count
                self.onCommentDeleted?()
                
                // Show error to user
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to post comment: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }
    
    func deleteComment(_ comment: Comment) {
        // Trigger optimistic UI update
        onCommentDeleted?()
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete the comment
        let commentRef = db.collection("comments").document(comment.id)
        batch.deleteDocument(commentRef)
        
        // Update video's comment count
        let videoRef = db.collection("videos").document(comment.videoId)
        batch.updateData([
            "comments_count": FieldValue.increment(Int64(-1))
        ], forDocument: videoRef)
        
        // Commit the batch
        batch.commit { [weak self] error in
            if error != nil {
                // If there was an error, revert the optimistic update
                self?.onCommentAdded?()
            }
        }
    }
    
    // MARK: - Data Fetching
    private func fetchComments() {
        guard let videoId = videoId else { return }
        
        let db = Firestore.firestore()
        // Create a real-time listener
        commentsListener = db.collection("comments")
            .whereField("video_id", isEqualTo: videoId)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let documents = snapshot?.documents else { return }
                
                self.comments = documents.compactMap { Comment(from: $0) }
                self.headerLabel.text = "\(self.comments.count) comments"
                self.commentsCollectionView.reloadData()
            }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // Dismiss keyboard before animating out
        view.endEditing(true)
        
        animateOut {
            super.dismiss(animated: false, completion: completion)
        }
    }
    
    deinit {
        // Remove the listener when the view controller is deallocated
        commentsListener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CommentsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        return !containerView.frame.contains(location)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension CommentsViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCell.identifier, for: indexPath) as? CommentCell else {
            return UICollectionViewCell()
        }
        
        let comment = comments[indexPath.item]
        cell.configure(with: comment)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 80)
    }
}

// MARK: - CommentCell
class CommentCell: UICollectionViewCell {
    static let identifier = "CommentCell"
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 20
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let commentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(commentLabel)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            
            timeLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
            timeLabel.centerYAnchor.constraint(equalTo: usernameLabel.centerYAnchor),
            
            commentLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            commentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            commentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with comment: Comment) {
        commentLabel.text = comment.text
        timeLabel.text = comment.createdAt.timeAgoDisplay()
        
        // Fetch user data
        let db = Firestore.firestore()
        db.collection("users").document(comment.userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let username = data["username"] as? String else { return }
            
            DispatchQueue.main.async {
                self?.usernameLabel.text = username
                
                // Handle avatar image
                if let avatarUrl = data["avatar"] as? String,
                   let url = URL(string: avatarUrl) {
                    // Create a URLSession data task to fetch the image
                    URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                        if let error = error {
                            print("Error loading comment avatar: \(error.localizedDescription)")
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
                    self?.setupDefaultAvatar(with: username)
                }
            }
        }
    }
    
    private func setupDefaultAvatar(with username: String) {
        // Clear any existing content
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        
        let firstChar = String(username.prefix(1)).uppercased()
        
        // Generate random color
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        
        // Create label for initials
        let label = UILabel()
        label.text = firstChar
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
}

// MARK: - UITextFieldDelegate
extension CommentsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handlePost()
        return true
    }
}
