import UIKit

class EditAvatarOptionsViewController: UIViewController {
    
    // MARK: - Properties
    private var completion: ((AvatarOption) -> Void)?
    
    enum AvatarOption {
        case takePhoto
        case uploadPhoto
        case viewPhoto
    }
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    // MARK: - Lifecycle
    init(completion: @escaping (AvatarOption) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        view.addSubview(containerView)
        containerView.addSubview(stackView)
        
        // Add options
        addOption(title: "Take photo", icon: "camera.fill", action: #selector(handleTakePhoto))
        addOption(title: "Upload photo", icon: "photo.fill", action: #selector(handleUploadPhoto))
        addOption(title: "View photo", icon: "eye.fill", action: #selector(handleViewPhoto))
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        view.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        containerView.addGestureRecognizer(panGesture)
    }
    
    private func addOption(title: String, icon: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .label
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 0)
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        
        stackView.addArrangedSubview(button)
        
        if stackView.arrangedSubviews.count < 4 {
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            stackView.addArrangedSubview(separator)
        }
    }
    
    // MARK: - Actions
    @objc private func handleBackgroundTap() {
        dismiss(animated: true)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .changed:
            if translation.y > 0 {
                containerView.transform = CGAffineTransform(translationX: 0, y: translation.y)
            }
        case .ended:
            let velocity = gesture.velocity(in: view)
            if translation.y > 100 || velocity.y > 500 {
                dismiss(animated: true)
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.containerView.transform = .identity
                }
            }
        default:
            break
        }
    }
    
    @objc private func handleTakePhoto() {
        dismiss(animated: true) {
            self.completion?(.takePhoto)
        }
    }
    
    @objc private func handleUploadPhoto() {
        dismiss(animated: true) {
            self.completion?(.uploadPhoto)
        }
    }
    
    @objc private func handleViewPhoto() {
        dismiss(animated: true) {
            self.completion?(.viewPhoto)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.view == view {
            dismiss(animated: true)
        }
    }
} 