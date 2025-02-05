//
//  EditProfileItemViewController.swift
//  ReelAI
//
//  Created by GauntletAI on 2/4/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class EditProfileItemViewController: UIViewController {
    
    enum FieldType: Int {
        case name = 0
        case username = 1
        case bio = 2
        case links = 3
        
        var title: String {
            switch self {
            case .name: return "Name"
            case .username: return "Username"
            case .bio: return "Bio"
            case .links: return "Links"
            }
        }
        
        var placeholder: String {
            switch self {
            case .name: return "Enter your name"
            case .username: return "Enter username"
            case .bio: return "Write a bio"
            case .links: return "Add links"
            }
        }
        
        var characterLimit: Int? {
            switch self {
            case .name: return 50
            case .username: return 30
            case .bio: return 150
            case .links: return nil
            }
        }
        
        var helpText: String? {
            switch self {
            case .name: return "Your name will be visible to other users"
            case .username: return "Username must be unique and contain only letters, numbers, and underscores"
            case .bio: return "Tell others about yourself"
            case .links: return "Add links to your social media profiles"
            }
        }
    }
    
    // MARK: - Properties
    private let fieldType: FieldType
    private var currentValue: String
    private var hasChanges: Bool = false {
        didSet {
            saveButton.isEnabled = hasChanges
            saveButton.tintColor = hasChanges ? .systemRed : .systemRed.withAlphaComponent(0.5)
        }
    }
    
    // MARK: - UI Components
    private let fieldNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var inputField: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.layer.borderColor = UIColor.systemGray5.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .systemGray3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let helpTextLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(handleSave)
        )
        button.tintColor = .systemRed
        button.isEnabled = false
        button.setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)],
            for: .normal
        )
        return button
    }()
    
    // MARK: - Lifecycle
    init(fieldType: FieldType, currentValue: String) {
        self.fieldType = fieldType
        self.currentValue = currentValue
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation setup
        navigationItem.title = fieldType.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )
        navigationItem.rightBarButtonItem = saveButton
        
        // Configure fields
        fieldNameLabel.text = fieldType.title
        inputField.text = currentValue
        placeholderLabel.text = fieldType.placeholder
        placeholderLabel.isHidden = !currentValue.isEmpty
        
        if let helpText = fieldType.helpText {
            helpTextLabel.text = helpText
        }
        
        if let charLimit = fieldType.characterLimit {
            updateCharacterCount(text: currentValue, limit: charLimit)
        }
        
        // Add subviews
        view.addSubview(fieldNameLabel)
        view.addSubview(inputField)
        inputField.addSubview(placeholderLabel)
        view.addSubview(helpTextLabel)
        
        if fieldType.characterLimit != nil {
            view.addSubview(characterCountLabel)
        }
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 16
        
        NSLayoutConstraint.activate([
            fieldNameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            fieldNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            fieldNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            
            inputField.topAnchor.constraint(equalTo: fieldNameLabel.bottomAnchor, constant: 8),
            inputField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            inputField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            inputField.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            placeholderLabel.topAnchor.constraint(equalTo: inputField.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputField.leadingAnchor, constant: 4),
            placeholderLabel.trailingAnchor.constraint(equalTo: inputField.trailingAnchor, constant: -4),
            
            helpTextLabel.topAnchor.constraint(equalTo: inputField.bottomAnchor, constant: 8),
            helpTextLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            helpTextLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
        
        if fieldType.characterLimit != nil {
            NSLayoutConstraint.activate([
                characterCountLabel.topAnchor.constraint(equalTo: helpTextLabel.bottomAnchor, constant: 4),
                characterCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
            ])
        }
    }
    
    private func updateCharacterCount(text: String, limit: Int) {
        characterCountLabel.text = "\(text.count)/\(limit)"
        characterCountLabel.textColor = text.count > limit ? .systemRed : .gray
    }
    
    // MARK: - Actions
    @objc private func handleCancel() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleSave() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        let field: String
        switch fieldType {
        case .name: field = "name"
        case .username: field = "username"
        case .bio: field = "bio"
        case .links: field = "links"
        }
        
        userRef.updateData([field: inputField.text]) { [weak self] error in
            if let error = error {
                print("Error updating \(field): \(error)")
                // TODO: Show error alert
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension EditProfileItemViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        hasChanges = textView.text != currentValue
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        if let charLimit = fieldType.characterLimit {
            updateCharacterCount(text: textView.text, limit: charLimit)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
