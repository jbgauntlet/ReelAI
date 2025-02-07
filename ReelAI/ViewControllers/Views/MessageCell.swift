import UIKit
import FirebaseAuth

class MessageCell: UICollectionViewCell {
    static let identifier = "MessageCell"
    
    // MARK: - UI Components
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(timestampLabel)
        
        // Create constraints but don't activate them yet
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),
            
            timestampLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            timestampLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    // MARK: - Configuration
    func configure(with message: Message) {
        messageLabel.text = message.text
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        timestampLabel.text = formatter.string(from: message.timestamp)
        
        let currentUserId = Auth.auth().currentUser?.uid
        let isFromCurrentUser = message.senderId == currentUserId
        
        // Deactivate both constraints first
        leadingConstraint.isActive = false
        trailingConstraint.isActive = false
        
        if isFromCurrentUser {
            // Sent message (right side)
            trailingConstraint.isActive = true
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            timestampLabel.textAlignment = .right
            timestampLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor).isActive = true
        } else {
            // Received message (left side)
            leadingConstraint.isActive = true
            bubbleView.backgroundColor = .tertiarySystemFill
            messageLabel.textColor = .label
            timestampLabel.textAlignment = .left
            timestampLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor).isActive = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        timestampLabel.text = nil
    }
} 