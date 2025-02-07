import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController {
    
    // MARK: - Properties
    private let conversation: Conversation
    private var messages: [Message] = []
    private var messagesListener: ListenerRegistration?
    private var otherUser: User?
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .interactive
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let messageInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Message..."
        tf.font = .systemFont(ofSize: 16)
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 20
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 16
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
    
    // MARK: - Lifecycle
    init(conversation: Conversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        listenToMessages()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        view.addSubview(messageInputView)
        messageInputView.addSubview(messageTextField)
        messageInputView.addSubview(sendButton)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            
            messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputView.heightAnchor.constraint(equalToConstant: 60),
            
            messageTextField.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 12),
            messageTextField.centerYAnchor.constraint(equalTo: messageInputView.centerYAnchor),
            messageTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            messageTextField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: messageInputView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add top border to messageInputView
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        messageInputView.addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: messageInputView.trailingAnchor),
            separator.topAnchor.constraint(equalTo: messageInputView.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Setup collection view
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: MessageCell.identifier)
        
        // Setup actions
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        // Create custom title view
        let titleView = UIView()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(avatarImageView)
        titleView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: titleView.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 32),
            avatarImageView.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: titleView.trailingAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: titleView.centerYAnchor)
        ])
        
        navigationItem.titleView = titleView
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Fetch other user's information
        fetchOtherUserInfo()
    }
    
    private func fetchOtherUserInfo() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Find the other user's ID from participants
        let otherUserId = conversation.participants.first { $0 != currentUserId } ?? ""
        
        let db = Firestore.firestore()
        db.collection("users").document(otherUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data() else { return }
            
            // Create user object
            self.otherUser = User(from: data, uid: otherUserId)
            
            // Update UI
            DispatchQueue.main.async {
                self.nameLabel.text = self.otherUser?.username
                
                if let username = self.otherUser?.username {
                    if let avatarUrl = self.otherUser?.avatar,
                       let url = URL(string: avatarUrl) {
                        // Load avatar image
                        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                            if let data = data,
                               let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    self?.avatarImageView.image = image
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self?.setupDefaultAvatar(with: username)
                                }
                            }
                        }.resume()
                    } else {
                        self.setupDefaultAvatar(with: username)
                    }
                }
            }
        }
    }
    
    private func setupDefaultAvatar(with username: String) {
        // Clear any existing content
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        
        let firstChar = String(username.prefix(1)).uppercased()
        
        // Generate color based on username
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        
        // Create label for initial
        let label = UILabel()
        label.text = firstChar
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc private func sendButtonTapped() {
        guard let messageText = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !messageText.isEmpty,
              let currentUserId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let messageData: [String: Any] = [
            "sender_id": currentUserId,
            "text": messageText,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("conversations").document(conversation.id)
            .collection("messages")
            .addDocument(data: messageData) { [weak self] error in
                if let error = error {
                    print("Error sending message: \(error)")
                    return
                }
                
                self?.messageTextField.text = ""
                
                // Update conversation's last message
                db.collection("conversations").document(self?.conversation.id ?? "")
                    .updateData([
                        "last_message": messageText,
                        "last_message_timestamp": FieldValue.serverTimestamp()
                    ])
            }
    }
    
    @objc private func handleKeyboardWillShow(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        
        UIView.animate(withDuration: 0.3) {
            self.messageInputView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight + self.view.safeAreaInsets.bottom)
            self.collectionView.contentInset.bottom = keyboardHeight
            self.collectionView.scrollIndicatorInsets.bottom = keyboardHeight
            
            // Scroll to bottom if there are messages
            if !self.messages.isEmpty {
                let lastItem = IndexPath(item: self.messages.count - 1, section: 0)
                self.collectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
            }
        }
    }
    
    @objc private func handleKeyboardWillHide(_ notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.messageInputView.transform = .identity
            self.collectionView.contentInset.bottom = 0
            self.collectionView.scrollIndicatorInsets.bottom = 0
        }
    }
    
    // MARK: - Data
    private func listenToMessages() {
        let db = Firestore.firestore()
        messagesListener = db.collection("conversations").document(conversation.id)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening to messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { document in
                    Message(from: document)
                }
                
                self.collectionView.reloadData()
                
                // Scroll to bottom if there are messages
                if !self.messages.isEmpty {
                    let lastItem = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView.scrollToItem(at: lastItem, at: .bottom, animated: true)
                }
            }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ChatViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MessageCell.identifier,
            for: indexPath
        ) as? MessageCell else {
            return UICollectionViewCell()
        }
        
        let message = messages[indexPath.item]
        cell.configure(with: message)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let message = messages[indexPath.item]
        let width = collectionView.bounds.width
        let estimatedHeight: CGFloat = 40
        
        return CGSize(width: width, height: estimatedHeight)
    }
} 