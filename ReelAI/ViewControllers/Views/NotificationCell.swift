import UIKit
import FirebaseFirestore

class NotificationCell: UICollectionViewCell {
    static let identifier = "NotificationCell"
    
    // MARK: - Properties
    private var notification: Notification?
    
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
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        contentView.addSubview(contentLabel)
        contentView.addSubview(timeLabel)
        
        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            contentLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: contentLabel.leadingAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    func configure(with notification: Notification) {
        self.notification = notification
        contentLabel.text = notification.content
        timeLabel.text = notification.createdAt.timeAgoDisplay()
        
        // Add unread indicator if needed
        if !notification.read {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        } else {
            contentView.backgroundColor = .systemBackground
        }
        
        // Fetch user's data to display avatar
        let db = Firestore.firestore()
        db.collection("users").document(notification.userId).getDocument { [weak self] snapshot, error in
            guard let userData = snapshot?.data(),
                  let username = userData["username"] as? String else { return }
            
            if let avatarUrl = userData["avatar"] as? String,
               let url = URL(string: avatarUrl) {
                // Load avatar image
                URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                    if let data = data, let image = UIImage(data: data) {
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
                self?.setupDefaultAvatar(with: username)
            }
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        contentLabel.text = nil
        timeLabel.text = nil
        contentView.backgroundColor = .systemBackground
        notification = nil
    }
} 