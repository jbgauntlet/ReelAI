import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: UIViewController {
    
    private let userInfoLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        
        // Initially hide the logout button until we confirm user is logged in
        logoutButton.isHidden = true
    }
    
    private func setupUI() {
        view.addSubview(userInfoLabel)
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            userInfoLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            userInfoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            userInfoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            logoutButton.topAnchor.constraint(equalTo: userInfoLabel.bottomAnchor, constant: 20),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 120),
            logoutButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Add target for logout button
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserData()
    }
    
    private func fetchUserData() {
        // Check if user is signed in
        guard let user = Auth.auth().currentUser else {
            self.userInfoLabel.text = "Not signed in"
            self.logoutButton.isHidden = true
            return
        }
        
        // Show logout button since user is signed in
        self.logoutButton.isHidden = false
        
        // Get Firestore reference
        let db = Firestore.firestore()
        
        // Fetch user document
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching user data: \(error)")
                    self.userInfoLabel.text = "Error loading user info"
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self.userInfoLabel.text = "Welcome, \(user.email ?? "User")"
                    return
                }
                
                let name = data["name"] as? String ?? ""
                
                if !name.isEmpty {
                    self.userInfoLabel.text = "Welcome, \(name)"
                } else {
                    self.userInfoLabel.text = "Welcome, \(user.email ?? "User")"
                }
            }
        }
    }
    
    @objc private func handleLogout() {
        let alert = UIAlertController(title: "Logout", 
                                    message: "Are you sure you want to logout?", 
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            GlobalDataManager.shared.logout(from: self)
        })
        
        present(alert, animated: true)
    }
}
