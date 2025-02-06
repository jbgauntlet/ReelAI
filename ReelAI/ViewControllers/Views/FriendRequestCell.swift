import UIKit
import FirebaseFirestore

class FriendRequestCell: UICollectionViewCell {
    static let identifier = "FriendRequestCell"
    
    // MARK: - Properties
    weak var delegate: FriendRequestCellDelegate?
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
    
    private let buttonsStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Accept", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let declineButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Decline", for: .normal)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.black, for: .normal)
        button.layer.cornerRadius = 15
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
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
        contentView.addSubview(buttonsStackView)
        
        buttonsStackView.addArrangedSubview(acceptButton)
        buttonsStackView.addArrangedSubview(declineButton)
        
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
            
            buttonsStackView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            buttonsStackView.leadingAnchor.constraint(equalTo: contentLabel.leadingAnchor),
            buttonsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonsStackView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupActions() {
        acceptButton.addTarget(self, action: #selector(handleAccept), for: .touchUpInside)
        declineButton.addTarget(self, action: #selector(handleDecline), for: .touchUpInside)
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
        
        // Fetch sender's data to display avatar
        if let requestId = notification.relatedId {
            let db = Firestore.firestore()
            db.collection("friend_requests").document(requestId).getDocument { [weak self] snapshot, error in
                guard let data = snapshot?.data(),
                      let senderId = data["sender_id"] as? String else { return }
                
                // Fetch sender's profile
                db.collection("users").document(senderId).getDocument { [weak self] snapshot, error in
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
    
    // MARK: - Actions
    @objc private func handleAccept() {
        guard let notification = notification else { return }
        
        // Disable buttons to prevent multiple taps
        acceptButton.isEnabled = false
        declineButton.isEnabled = false
        
        // Animate button state
        UIView.animate(withDuration: 0.2) {
            self.acceptButton.alpha = 0.5
            self.declineButton.alpha = 0.5
        }
        
        delegate?.didTapAccept(for: notification)
    }
    
    @objc private func handleDecline() {
        guard let notification = notification else { return }
        
        // Disable buttons to prevent multiple taps
        acceptButton.isEnabled = false
        declineButton.isEnabled = false
        
        // Animate button state
        UIView.animate(withDuration: 0.2) {
            self.acceptButton.alpha = 0.5
            self.declineButton.alpha = 0.5
        }
        
        delegate?.didTapDecline(for: notification)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        avatarImageView.subviews.forEach { $0.removeFromSuperview() }
        contentLabel.text = nil
        timeLabel.text = nil
        contentView.backgroundColor = .systemBackground
        notification = nil
        
        // Reset button states
        acceptButton.isEnabled = true
        declineButton.isEnabled = true
        acceptButton.alpha = 1.0
        declineButton.alpha = 1.0
    }
} 