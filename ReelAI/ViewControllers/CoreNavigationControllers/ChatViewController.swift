import UIKit
import FirebaseFirestore
import FirebaseAuth

class ChatViewController: UIViewController {
    
    // MARK: - Properties
    private let conversation: Conversation
    private var messages: [Message] = []
    private var messagesListener: ListenerRegistration?
    private var messagesByDate: [(date: Date, messages: [Message])] = []
    
    // MARK: - UI Components
    private let customNavigationView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let userInfoStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 2
        sv.alignment = .leading
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.alwaysBounceVertical = true
        cv.keyboardDismissMode = .interactive
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let messageInputView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGroupedBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Message..."
        tf.font = .systemFont(ofSize: 16)
        tf.backgroundColor = .systemBackground
        tf.layer.cornerRadius = 20
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToBottom(animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(customNavigationView)
        customNavigationView.addSubview(backButton)
        customNavigationView.addSubview(avatarImageView)
        customNavigationView.addSubview(userInfoStackView)
        
        userInfoStackView.addArrangedSubview(usernameLabel)
        userInfoStackView.addArrangedSubview(statusLabel)
        
        view.addSubview(collectionView)
        view.addSubview(messageInputView)
        messageInputView.addSubview(messageTextField)
        messageInputView.addSubview(sendButton)
        
        // Add delegate for messageTextField
        messageTextField.delegate = self
        
        NSLayoutConstraint.activate([
            customNavigationView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavigationView.heightAnchor.constraint(equalToConstant: 60),
            
            backButton.leadingAnchor.constraint(equalTo: customNavigationView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: customNavigationView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            avatarImageView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            avatarImageView.centerYAnchor.constraint(equalTo: customNavigationView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            userInfoStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            userInfoStackView.centerYAnchor.constraint(equalTo: customNavigationView.centerYAnchor),
            userInfoStackView.trailingAnchor.constraint(equalTo: customNavigationView.trailingAnchor, constant: -16),
            
            collectionView.topAnchor.constraint(equalTo: customNavigationView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: messageInputView.topAnchor),
            
            messageInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messageInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messageInputView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            messageInputView.heightAnchor.constraint(equalToConstant: 60),
            
            messageTextField.leadingAnchor.constraint(equalTo: messageInputView.leadingAnchor, constant: 16),
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
        collectionView.register(DateSeparatorCell.self, forCellWithReuseIdentifier: DateSeparatorCell.identifier)
        
        // Setup actions
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(handleSendButtonTapped), for: .touchUpInside)
    }
    
    private func setupNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        // Configure user info
        if let otherUser = conversation.otherUserInfo {
            usernameLabel.text = otherUser.name ?? otherUser.username ?? "User"
            statusLabel.text = "Active now" // You can update this based on user's actual status
            
            if let avatarUrl = otherUser.avatar,
               let url = URL(string: avatarUrl) {
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.avatarImageView.image = image
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.setupDefaultAvatar(with: otherUser.username ?? "U")
                        }
                    }
                }.resume()
            } else {
                setupDefaultAvatar(with: otherUser.username ?? "U")
            }
        }
    }
    
    private func setupDefaultAvatar(with username: String) {
        let firstChar = String(username.prefix(1)).uppercased()
        let hue = CGFloat(username.hashValue) / CGFloat(Int.max)
        let color = UIColor(hue: hue, saturation: 0.5, brightness: 0.8, alpha: 1.0)
        
        avatarImageView.backgroundColor = color
        
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
    @objc private func handleBack() {
        dismiss(animated: true)
    }
    
    @objc private func handleSendButtonTapped() {
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
    
    private func scrollToBottom(animated: Bool = true) {
        guard !messagesByDate.isEmpty else { return }
        let lastSection = messagesByDate.count - 1
        let lastItemIndex = messagesByDate[lastSection].messages.count
        let lastIndexPath = IndexPath(item: lastItemIndex, section: lastSection)
        
        // Ensure the index path is valid before scrolling
        let section = lastIndexPath.section
        let item = lastIndexPath.item
        if section < collectionView.numberOfSections,
           item < collectionView.numberOfItems(inSection: section) {
            collectionView.scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
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
            self.scrollToBottom(animated: true)
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
    private func groupMessagesByDate() {
        let calendar = Calendar.current
        let groupedMessages = Dictionary(grouping: messages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
        
        messagesByDate = groupedMessages.map { (date, messages) in
            (date: date, messages: messages.sorted { $0.timestamp < $1.timestamp })
        }.sorted { $0.date < $1.date }
    }
    
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
                
                self.groupMessagesByDate()
                self.collectionView.reloadData()
                self.scrollToBottom(animated: true)
            }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ChatViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return messagesByDate.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messagesByDate[section].messages.count + 1 // +1 for date separator
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DateSeparatorCell.identifier,
                for: indexPath
            ) as? DateSeparatorCell else {
                return UICollectionViewCell()
            }
            
            let date = messagesByDate[indexPath.section].date
            cell.configure(with: date)
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MessageCell.identifier,
                for: indexPath
            ) as? MessageCell else {
                return UICollectionViewCell()
            }
            
            let message = messagesByDate[indexPath.section].messages[indexPath.item - 1]
            cell.configure(with: message)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        
        if indexPath.item == 0 {
            return CGSize(width: width, height: 40) // Height for date separator
        }
        
        let message = messagesByDate[indexPath.section].messages[indexPath.item - 1]
        
        // Calculate height based on message text
        let maxWidth = width * 0.75 - 24 // 75% of width minus padding
        let font = UIFont.systemFont(ofSize: 16)
        let messageText = message.text
        
        let constraintRect = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let boundingBox = messageText.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let messageHeight = ceil(boundingBox.height) + 16 // Add padding
        let totalHeight = messageHeight + 24 // Add space for timestamp
        
        return CGSize(width: width, height: totalHeight)
    }
}

// MARK: - UITextFieldDelegate
extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == messageTextField {
            handleSendButtonTapped()
            return false
        }
        return true
    }
} 