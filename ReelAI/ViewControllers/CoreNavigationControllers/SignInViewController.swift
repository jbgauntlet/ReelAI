import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignInViewController: UIViewController, UITextFieldDelegate {

    let backButton = UIButton()
    let contentContainerView = UIView()
    let signInLabel = UILabel()
    let emailTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
    var passwordTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 45))
    let togglePasswordButton = UIButton()
    let signInButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let textFieldHeight = 60.0
        let verticalPadding = 30.0
        let horizontalPadding = 30.0
        let buttonHeight = textFieldHeight
        let labelHeight = 35.0
        
        let contentContainerHeight = 5 * textFieldHeight + 4 * verticalPadding + labelHeight
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainerView)
        NSLayoutConstraint.activate([
            contentContainerView.heightAnchor.constraint(equalToConstant: contentContainerHeight),
            contentContainerView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        let backButtonImage = UIImage(systemName: "arrow.left")?.resizeWithHeight(to: 22.5)
        backButton.setImage(backButtonImage, for: .normal)
        backButton.tintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(handleBackButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalPadding),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            backButton.heightAnchor.constraint(equalToConstant: 22.5),
        ])
        
        let fontDescriptor = UIFontDescriptor(fontAttributes: [
            .family: "Inter",
            .traits: [
                UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold
            ]
        ])
        signInLabel.text = "Sign In"
        signInLabel.font = UIFont(descriptor: fontDescriptor, size: 28)
        signInLabel.textAlignment = .center
        signInLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(signInLabel)
        NSLayoutConstraint.activate([
            signInLabel.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            signInLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            signInLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            signInLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
        
        emailTextField.placeholder = "Email"
        emailTextField.backgroundColor = ColorPalette.lightGray
        emailTextField.layer.cornerRadius = textFieldHeight / 6
        emailTextField.autocorrectionType = .no
        emailTextField.autocapitalizationType = .none
        emailTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(emailTextField)
        NSLayoutConstraint.activate([
            emailTextField.topAnchor.constraint(equalTo: signInLabel.bottomAnchor, constant: verticalPadding),
            emailTextField.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: horizontalPadding),
            emailTextField.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor,constant: -horizontalPadding),
            emailTextField.heightAnchor.constraint(equalToConstant: textFieldHeight)
        ])
        
        let passwordHiddenImage = UIImage(systemName: "eye.slash.fill")?.resizeWithHeight(to: 22.5)
        let passwordVisibleImage = UIImage(systemName: "eye.fill")?.resizeWithHeight(to: 22.5)
        let passwordHiddenImageWidth = passwordHiddenImage?.size.width ?? 0
        togglePasswordButton.setImage(passwordHiddenImage, for: .normal)
        togglePasswordButton.setImage(passwordVisibleImage, for: .selected)
        togglePasswordButton.addTarget(self, action: #selector(handleTogglePasswordButtonTapped), for: .touchUpInside)
        togglePasswordButton.tintColor = .black
        togglePasswordButton.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: passwordHiddenImageWidth + 15))
        passwordTextField.placeholder = "Password"
        passwordTextField.backgroundColor = ColorPalette.lightGray
        passwordTextField.layer.cornerRadius = textFieldHeight / 6
        passwordTextField.isSecureTextEntry = true
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(passwordTextField)
        passwordTextField.addSubview(togglePasswordButton)
        NSLayoutConstraint.activate([
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: verticalPadding),
            passwordTextField.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: horizontalPadding),
            passwordTextField.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor,constant: -horizontalPadding),
            passwordTextField.heightAnchor.constraint(equalToConstant: textFieldHeight),
            
            togglePasswordButton.trailingAnchor.constraint(equalTo: passwordTextField.trailingAnchor, constant: -(horizontalPadding / 4)),
            togglePasswordButton.heightAnchor.constraint(equalToConstant: textFieldHeight / 2),
            togglePasswordButton.widthAnchor.constraint(equalToConstant: passwordHiddenImageWidth),
            togglePasswordButton.centerYAnchor.constraint(equalTo: passwordTextField.centerYAnchor)
        ])
        
        signInButton.alpha = 0.5
        signInButton.isEnabled = false
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.backgroundColor = .black
        signInButton.setTitleColor(.white, for: .normal)
        signInButton.layer.cornerRadius = buttonHeight / 2
        signInButton.addTarget(self, action: #selector(handleSignInButtonTapped), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: verticalPadding),
            signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            signInButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
        
        let tapOutsideGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapOutsideGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapOutsideGesture)
    }
    
    @objc func handleBackButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleTogglePasswordButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        passwordTextField.isSecureTextEntry = !sender.isSelected
    }
    
    @objc func handleSignInButtonTapped() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        signIn(email, password)
    }
    
    func signIn(_ email: String, _ password: String) {
        signInButton.isEnabled = false
        
        // Verify Firebase Auth is initialized
        guard Auth.auth() != nil else {
            print("Firebase Auth is not initialized")
            signInButton.isEnabled = true
            return
        }
        
        print("Attempting to sign in with email: \(email)")
        
        // Sign in with Firebase Auth
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    // Detailed error logging
                    print("Firebase Auth Error Code: \(error.code)")
                    print("Firebase Auth Error Domain: \(error.domain)")
                    print("Firebase Auth Error Description: \(error.localizedDescription)")
                    print("Firebase Auth Error User Info: \(error.userInfo)")
                    
                    if let authError = AuthErrorCode(rawValue: error.code) {
                        print("Firebase Auth Error Code Name: \(authError)")
                        switch authError {
                        case .wrongPassword:
                            print("Wrong password")
                        case .invalidEmail:
                            print("Invalid email format")
                        case .userNotFound:
                            print("User not found")
                        case .invalidCustomToken:
                            print("Invalid custom token")
                        case .credentialAlreadyInUse:
                            print("Credential already in use")
                        case .operationNotAllowed:
                            print("Operation not allowed - check if Email/Password sign-in is enabled in Firebase Console")
                        default:
                            print("Other Firebase Auth error: \(authError)")
                        }
                    }
                    
                    // TODO: Show error to user
                    self.signInButton.isEnabled = true
                    return
                }
                
                guard let user = authResult?.user else {
                    print("No user found after successful sign in")
                    self.signInButton.isEnabled = true
                    return
                }
                
                // Fetch user data from Firestore
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).getDocument { [weak self] (document, error) in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Firestore Error: \(error.localizedDescription)")
                            self.signInButton.isEnabled = true
                            return
                        }
                        
                        guard let document = document, document.exists,
                              let userData = document.data() else {
                            print("User document not found or missing data")
                            self.signInButton.isEnabled = true
                            return
                        }
                        
                        // Create user model from Firestore data
                        if let userModel = User(from: userData, uid: user.uid) {
                            GlobalDataManager.shared.user = userModel
                            // Navigate to main screen
                            navigateToControllerAsRootController(self.view.window, MainTabBarController())
                        } else {
                            print("Error creating user model from data")
                            self.signInButton.isEnabled = true
                        }
                    }
                }
            }
        }
        
        // Keep the old API call as fallback or remove if not needed
        /* APICaller.shared.sendRequest(LoginRequest(email: email, password: password), "login", .POST, false, LoginResponse.self) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let success = GlobalDataManager.shared.handleLoginSuccess(response)
                    if(success) { navigateToControllerAsRootController(self.view.window, MainTabBarController()) }
                case .failure(let error):
                    print(error.localizedDescription)
                }
                self.signInButton.isEnabled = true
            }
        } */
    }
    
    @objc func textFieldDidChange() {
        var canSubmit = true
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        
        if(email.isEmpty || password.isEmpty) {
            canSubmit = false
        }
        
        signInButton.isEnabled = canSubmit
        signInButton.alpha = canSubmit ? 1.0 : 0.5
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
