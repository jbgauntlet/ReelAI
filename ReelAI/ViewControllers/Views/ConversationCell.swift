import UIKit

class ConversationCell: UITableViewCell {
    static let identifier = "ConversationCell"
    
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 25
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let unreadBadge: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 10
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let unreadCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(lastMessageLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(unreadBadge)
        unreadBadge.addSubview(unreadCountLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            usernameLabel.trailingAnchor.constraint(equalTo: timestampLabel.leadingAnchor, constant: -8),
            
            lastMessageLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            lastMessageLabel.trailingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: -8),
            
            timestampLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            timestampLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            unreadBadge.centerYAnchor.constraint(equalTo: lastMessageLabel.centerYAnchor),
            unreadBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            unreadBadge.widthAnchor.constraint(equalToConstant: 20),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20),
            
            unreadCountLabel.centerXAnchor.constraint(equalTo: unreadBadge.centerXAnchor),
            unreadCountLabel.centerYAnchor.constraint(equalTo: unreadBadge.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with conversation: Conversation) {
        // Clear any existing avatar content
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        
        // Set username
        if let username = conversation.otherUserInfo?.username {
            usernameLabel.text = username
        } else {
            usernameLabel.text = "User"
        }
        
        // Set last message
        lastMessageLabel.text = conversation.lastMessage ?? "No messages yet"
        
        // Set timestamp
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        timestampLabel.text = formatter.localizedString(for: conversation.lastMessageTimestamp, relativeTo: Date())
        
        // Set unread count
        if conversation.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadCountLabel.text = "\(min(conversation.unreadCount, 99))"
        } else {
            unreadBadge.isHidden = true
        }
        
        // Handle avatar
        if let username = conversation.otherUserInfo?.username {
            if let avatarUrl = conversation.otherUserInfo?.avatar,
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
                setupDefaultAvatar(with: username)
            }
        } else {
            setupDefaultAvatar(with: "U")
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
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        unreadBadge.isHidden = true
    }
} 