import UIKit
import FirebaseAuth
import FirebaseFirestore

class EditProfileViewController: UIViewController {
    
    // MARK: - Properties
    private var user: User?
    
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 50
        iv.backgroundColor = .systemGray5
        iv.isUserInteractionEnabled = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let editPhotoLabel: UILabel = {
        let label = UILabel()
        label.text = "Edit photo or avatar"
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let aboutYouLabel: UILabel = {
        let label = UILabel()
        label.text = "About you"
        label.textColor = .gray
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Edit Profile"
        
        // Add back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        // Add subviews
        view.addSubview(avatarImageView)
        view.addSubview(editPhotoLabel)
        view.addSubview(aboutYouLabel)
        view.addSubview(stackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),
            
            editPhotoLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            editPhotoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            aboutYouLabel.topAnchor.constraint(equalTo: editPhotoLabel.bottomAnchor, constant: 30),
            aboutYouLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            stackView.topAnchor.constraint(equalTo: aboutYouLabel.bottomAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        // Add tap gesture to avatar
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAvatarTap))
        avatarImageView.addGestureRecognizer(tapGesture)
    }
    
    private func createInfoRow(label: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.textAlignment = .right
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.textColor = .gray
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronButton = UIButton(type: .system)
        chevronButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        chevronButton.tintColor = .systemGray3
        chevronButton.addTarget(self, action: #selector(handleChevronTap(_:)), for: .touchUpInside)
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Store the field type in the button's tag
        switch label {
        case "Name": chevronButton.tag = 0
        case "Username": chevronButton.tag = 1
        case "Bio": chevronButton.tag = 2
        case "Links": chevronButton.tag = 3
        default: break
        }
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        container.addSubview(chevronButton)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            chevronButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chevronButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronButton.widthAnchor.constraint(equalToConstant: 20),
            chevronButton.heightAnchor.constraint(equalToConstant: 20),
            
            valueLabel.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
        
        // Add separator line
        let separator = UIView()
        separator.backgroundColor = .systemGray5
        separator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)
        
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        // Make the whole row tappable
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRowTap(_:)))
        container.addGestureRecognizer(tapGesture)
        container.isUserInteractionEnabled = true
        
        return container
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
        label.font = .systemFont(ofSize: 40, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        
        avatarImageView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor)
        ])
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let data = snapshot?.data() else { return }
            
            // Update UI with user data
            if let username = data["username"] as? String {
                self.stackView.addArrangedSubview(self.createInfoRow(label: "Username", value: username))
                
                if let avatarUrl = data["avatar"] as? String,
                   let url = URL(string: avatarUrl) {
                    // TODO: Load avatar image from URL
                } else {
                    self.setupDefaultAvatar(with: username)
                }
            }
            
            if let name = data["name"] as? String {
                self.stackView.addArrangedSubview(self.createInfoRow(label: "Name", value: name))
            }
            
            if let bio = data["bio"] as? String {
                let truncatedBio = String(bio.prefix(30)) + (bio.count > 30 ? "..." : "")
                self.stackView.addArrangedSubview(self.createInfoRow(label: "Bio", value: truncatedBio))
            }
            
            if let links = data["links"] as? [String], let firstLink = links.first {
                let truncatedLink = String(firstLink.prefix(20)) + (firstLink.count > 20 ? "..." : "")
                self.stackView.addArrangedSubview(self.createInfoRow(label: "Links", value: truncatedLink))
            }
        }
    }
    
    // MARK: - Actions
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleAvatarTap() {
        // TODO: Implement avatar change functionality
    }
    
    @objc private func handleChevronTap(_ sender: UIButton) {
        navigateToEditItem(for: sender.tag)
    }
    
    @objc private func handleRowTap(_ sender: UITapGestureRecognizer) {
        guard let container = sender.view else { return }
        guard let titleLabel = container.subviews.first(where: { $0 is UILabel }) as? UILabel else { return }
        
        // Get the field type from the chevron button's tag
        guard let chevronButton = container.subviews.first(where: { ($0 as? UIButton)?.currentImage == UIImage(systemName: "chevron.right") }) as? UIButton,
              let fieldType = EditProfileItemViewController.FieldType(rawValue: chevronButton.tag) else { return }
        
        let value = (container.subviews.first { ($0 as? UILabel)?.textAlignment == .right } as? UILabel)?.text ?? ""
        navigateToEditItem(fieldType: fieldType, currentValue: value)
    }
    
    private func navigateToEditItem(for tag: Int) {
        guard let fieldType = EditProfileItemViewController.FieldType(rawValue: tag) else { return }
        let value = getFieldValue(for: fieldType)
        navigateToEditItem(fieldType: fieldType, currentValue: value)
    }
    
    private func navigateToEditItem(fieldType: EditProfileItemViewController.FieldType, currentValue: String) {
        let editItemVC = EditProfileItemViewController(fieldType: fieldType, currentValue: currentValue)
        navigationController?.pushViewController(editItemVC, animated: true)
    }
    
    private func getFieldValue(for fieldType: EditProfileItemViewController.FieldType) -> String {
        guard let data = user else { return "" }
        
        switch fieldType {
        case .name: return data.name ?? ""
        case .username: return data.username ?? ""
        case .bio: return data.bio ?? ""
        case .links: return data.links?.first ?? ""
        }
    }
} 
