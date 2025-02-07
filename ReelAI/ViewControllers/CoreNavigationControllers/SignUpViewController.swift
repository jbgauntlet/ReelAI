import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {

    let backButton = UIButton()
    let scrollView = UIScrollView()
    let contentContainerView = UIView()
    let signUpLabel = UILabel()
    let emailTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
    var passwordTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 45))
    let togglePasswordButton = UIButton()
    let nameTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
    let usernameTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
    let signUpButton = UIButton()
    let signInButton = UIButton()
    
    var activeTextField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let textFieldHeight = 60.0
        let verticalPadding = 30.0
        let horizontalPadding = 30.0
        let buttonHeight = textFieldHeight
        let labelHeight = 35.0
        
        let backButtonHeight = 22.5
        let backButtonImage = UIImage(systemName: "arrow.left")?.resizeWithHeight(to: backButtonHeight)
        backButton.setImage(backButtonImage, for: .normal)
        backButton.tintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(handleBackButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalPadding),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            backButton.heightAnchor.constraint(equalToConstant: backButtonHeight),
        ])
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: verticalPadding),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let contentContainerHeight = 5 * textFieldHeight + 4 * verticalPadding + labelHeight
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainerView)
        NSLayoutConstraint.activate([
            contentContainerView.heightAnchor.constraint(equalToConstant: contentContainerHeight),
            contentContainerView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor, constant: -((backButtonHeight + verticalPadding * 2) / 2)),
            contentContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let fontDescriptor = UIFontDescriptor(fontAttributes: [
            .family: "Inter",
            .traits: [
                UIFontDescriptor.TraitKey.weight: UIFont.Weight.bold
            ]
        ])
        signUpLabel.text = "Sign Up"
        signUpLabel.font = UIFont(descriptor: fontDescriptor, size: 28)
        signUpLabel.textAlignment = .center
        signUpLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(signUpLabel)
        NSLayoutConstraint.activate([
            signUpLabel.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            signUpLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            signUpLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            signUpLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
        
        emailTextField.placeholder = "Email"
        emailTextField.backgroundColor = ColorPalette.lightGray
        emailTextField.layer.cornerRadius = textFieldHeight / 6
        emailTextField.autocorrectionType = .no
        emailTextField.autocapitalizationType = .none
        emailTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        emailTextField.delegate = self
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(emailTextField)
        NSLayoutConstraint.activate([
            emailTextField.topAnchor.constraint(equalTo: signUpLabel.bottomAnchor, constant: verticalPadding),
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
        passwordTextField.delegate = self
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
        
        nameTextField.placeholder = "Name"
        nameTextField.backgroundColor = ColorPalette.lightGray
        nameTextField.layer.cornerRadius = textFieldHeight / 6
        nameTextField.autocorrectionType = .no
        nameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        nameTextField.delegate = self
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(nameTextField)
        NSLayoutConstraint.activate([
            nameTextField.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: verticalPadding),
            nameTextField.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: horizontalPadding),
            nameTextField.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -horizontalPadding),
            nameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight)
        ])
        
        usernameTextField.placeholder = "Username"
        usernameTextField.backgroundColor = ColorPalette.lightGray
        usernameTextField.layer.cornerRadius = textFieldHeight / 6
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        usernameTextField.delegate = self
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(usernameTextField)
        NSLayoutConstraint.activate([
            usernameTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: verticalPadding),
            usernameTextField.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: horizontalPadding),
            usernameTextField.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -horizontalPadding),
            usernameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight)
        ])
        
        signUpButton.alpha = 0.5
        signUpButton.isEnabled = false
        signUpButton.setTitle("Continue", for: .normal)
        signUpButton.backgroundColor = .black
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.layer.cornerRadius = buttonHeight / 2
        signUpButton.addTarget(self, action: #selector(handleSignUpButtonTapped), for: .touchUpInside)
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: verticalPadding),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            signUpButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
        
        signInButton.setTitle("Already have an account? Sign In", for: .normal)
        signInButton.backgroundColor = .white
        signInButton.setTitleColor(ColorPalette.gray, for: .normal)
        signInButton.addTarget(self, action: #selector(handleSignInButtonTapped), for: .touchUpInside)
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor),
            signInButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            signInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            signInButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
        
        let tapOutsideGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapOutsideGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapOutsideGesture)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleBackButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleTogglePasswordButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        passwordTextField.isSecureTextEntry = !sender.isSelected
    }
    
    @objc func handleSignUpButtonTapped() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let name = nameTextField.text else { return }
        guard let username = usernameTextField.text else { return }
        
        signUp(email, password, name, username)
    }
    
    @objc func handleSignInButtonTapped() {
        navigationController?.pushViewController(SignInViewController(), animated: true)
    }
    
    func signUp(_ email: String, _ password: String, _ name: String, _ username: String) {
        signUpButton.isEnabled = false
        
        // Create the user with Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    // Detailed error logging
                    print("Firebase Auth Error Code: \(error.code)")
                    print("Firebase Auth Error Domain: \(error.domain)")
                    print("Firebase Auth Error Description: \(error.localizedDescription)")
                    
                    if let authError = AuthErrorCode(rawValue: error.code) {
                        print("Firebase Auth Error Code Name: \(authError)")
                        switch authError {
                        case .emailAlreadyInUse:
                            print("Email is already in use")
                        case .invalidEmail:
                            print("Invalid email format")
                        case .weakPassword:
                            print("Password is too weak")
                        default:
                            print("Other Firebase Auth error")
                        }
                    }
                    
                    // TODO: Show error to user
                    self.signUpButton.isEnabled = true
                    return
                }
                
                guard let user = authResult?.user else {
                    print("No user found after successful creation")
                    self.signUpButton.isEnabled = true
                    return
                }
                
                // Store additional user data in Firestore
                let userData: [String: Any] = [
                    // Basic Info
                    "name": name,
                    "name_lowercase": name.lowercased(),
                    "username": username,
                    "username_lowercase": username.lowercased(),
                    "email": email,
                    "bio": "",
                    "avatar": "",
                    "links": [],
                    
                    // Counters (initialized to 0)
                    "followers_count": 0,
                    "following_count": 0,
                    "likes_count": 0,
                    "videos_count": 0,
                    "friends_count": 0,
                    "comments_count": 0,
                    
                    // Metadata
                    "created_at": FieldValue.serverTimestamp(),
                    "updated_at": FieldValue.serverTimestamp()
                ]
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData(userData) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Firestore Error: \(error.localizedDescription)")
                            // TODO: Show error to user
                            self.signUpButton.isEnabled = true
                            return
                        }
                        
                        // Store user data in GlobalDataManager
                        var userModel = User()
                        userModel.uid = user.uid
                        userModel.name = name
                        userModel.username = username
                        userModel.email = email
                        userModel.bio = ""
                        GlobalDataManager.shared.user = userModel
                        
                        // Navigate to main screen
                        navigateToControllerAsRootController(self.view.window, MainTabBarController())
                    }
                }
            }
        }
        
        // Keep the old API call as fallback or remove if not needed
        /* APICaller.shared.sendRequest(SignUpRequest(email: email, password: password, firstname: firstname, lastname: lastname), "register", .POST, false, SignUpResponse.self) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let userId = response.user_id!
                    self.navigationController?.pushViewController(VerifyAccountViewController(userId, email, password, firstname, lastname), animated: true)
                case .failure(let error):
                    print(error.localizedDescription)
                }
                self.signUpButton.isEnabled = true
            }
        } */
    }
    
    @objc func textFieldDidChange() {
        var canSubmit = true
        let email = emailTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        let name = nameTextField.text ?? ""
        let username = usernameTextField.text ?? ""
        
        if(email.isEmpty || password.isEmpty || name.isEmpty || username.isEmpty) {
            canSubmit = false
        }
        
        signUpButton.isEnabled = canSubmit
        signUpButton.alpha = canSubmit ? 1.0 : 0.5
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardHeight = keyboardFrame.height
        var contentInset = scrollView.contentInset
        contentInset.bottom = keyboardHeight
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset

        if let activeTextField = activeTextField {
            let visibleRect = view.frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0))
            if !visibleRect.contains(activeTextField.frame.origin) {
                scrollView.scrollRectToVisible(activeTextField.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        var contentInset = scrollView.contentInset
        contentInset.bottom = 0
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension SignUpViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
    }
}
