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
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Configure scrollView first
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        let textFieldHeight = 60.0
        let verticalPadding = 30.0
        let horizontalPadding = 30.0
        let buttonHeight = textFieldHeight
        let labelHeight = 35.0
        
        // Back button setup
        let backButtonHeight = 22.5
        let backButtonImage = UIImage(systemName: "arrow.left")?.resizeWithHeight(to: backButtonHeight)
        backButton.setImage(backButtonImage, for: .normal)
        backButton.tintColor = .black
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(handleBackButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Update scrollView constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: verticalPadding),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: verticalPadding),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            backButton.heightAnchor.constraint(equalToConstant: backButtonHeight)
        ])
        
        // Content container setup with frame-based sizing
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainerView)
        
        // Update content container constraints
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // Ensure the content is tall enough
            contentContainerView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor)
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
        
        contentContainerView.addSubview(errorLabel)
        contentContainerView.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: signUpButton.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: signUpButton.trailingAnchor, constant: -16)
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
        print("[SignUp] Button tapped - Starting validation")
        guard validateFields() else {
            print("[SignUp] Field validation failed")
            return
        }
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text,
              let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("[SignUp] Failed to unwrap text fields")
            return
        }
        
        print("[SignUp] Fields validated successfully - Starting sign up process")
        setLoading(true)
        signUp(email, password, name, username)
    }
    
    @objc func handleSignInButtonTapped() {
        navigationController?.pushViewController(SignInViewController(), animated: true)
    }
    
    func signUp(_ email: String, _ password: String, _ name: String, _ username: String) {
        print("[SignUp] Creating user with Firebase Auth")
        // Create the user with Firebase Auth
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else {
                print("[SignUp] Self was deallocated during Firebase Auth")
                return
            }
            
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    print("[SignUp] Firebase Auth error: \(error.localizedDescription)")
                    if let authError = AuthErrorCode(rawValue: error.code) {
                        switch authError {
                        case .emailAlreadyInUse:
                            print("[SignUp] Email already in use")
                            self.showError("This email is already registered", textField: self.emailTextField)
                        case .invalidEmail:
                            print("[SignUp] Invalid email format")
                            self.showError("Please enter a valid email address", textField: self.emailTextField)
                        case .weakPassword:
                            print("[SignUp] Weak password")
                            self.showError("Password is too weak. Please use at least 6 characters", textField: self.passwordTextField)
                        default:
                            print("[SignUp] Other Firebase Auth error: \(error.localizedDescription)")
                            self.showError("Error: \(error.localizedDescription)")
                        }
                    } else {
                        print("[SignUp] Non-Firebase Auth error: \(error.localizedDescription)")
                        self.showError("An error occurred. Please try again")
                    }
                    self.setLoading(false)
                    return
                }
                
                guard let user = authResult?.user else {
                    print("[SignUp] No auth result or user after successful Firebase Auth")
                    self.showError("An error occurred. Please try again")
                    self.setLoading(false)
                    return
                }
                
                print("[SignUp] User created successfully, saving additional data to Firestore")
                // Store additional user data in Firestore
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "name": name,
                    "username": username,
                    "email": email,
                    "bio": "",
                    "profileImageUrl": "",
                    "followers": [],
                    "following": [],
                    "posts": [],
                    "likes": [],
                    "comments": [],
                    "notifications": [],
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                db.collection("users").document(user.uid).setData(userData) { [weak self] error in
                    guard let self = self else {
                        print("[SignUp] Self was deallocated during Firestore save")
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            print("[SignUp] Firestore error: \(error.localizedDescription)")
                            self.showError("Error saving user data: \(error.localizedDescription)")
                            self.setLoading(false)
                            return
                        }
                        
                        print("[SignUp] User data saved successfully, updating GlobalDataManager")
                        // Store user data in GlobalDataManager
                        var userModel = User()
                        userModel.uid = user.uid
                        userModel.name = name
                        userModel.username = username
                        userModel.email = email
                        userModel.bio = ""
                        GlobalDataManager.shared.user = userModel
                        
                        print("[SignUp] Navigating to main screen")
                        // Navigate to main screen
                        navigateToControllerAsRootController(self.view.window, MainTabBarController())
                    }
                }
            }
        }
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
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let activeField = activeTextField else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        
        // Convert the active text field's frame to the view's coordinate space
        let textFieldFrame = activeField.convert(activeField.bounds, to: view)
        
        // Calculate the bottom of the text field
        let textFieldBottom = textFieldFrame.maxY
        
        // Calculate the area that will be hidden by the keyboard
        let visibleArea = view.frame.height - keyboardHeight
        
        // Check if the text field will be hidden by the keyboard
        if textFieldBottom > visibleArea {
            // Calculate how much we need to scroll
            let scrollOffset = textFieldBottom - visibleArea + 20 // Add padding
            
            // Animate the scroll
            UIView.animate(withDuration: 0.3) {
                self.scrollView.contentOffset = CGPoint(x: 0, y: scrollOffset)
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        // Smoothly scroll back to top when keyboard hides
        UIView.animate(withDuration: 0.3) {
            self.scrollView.contentOffset = .zero
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func validateFields() -> Bool {
        // Reset UI state
        resetFieldErrors()
        errorLabel.isHidden = true
        
        // Validate email
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty else {
            showError("Please enter your email", textField: emailTextField)
            return false
        }
        
        if !isValidEmail(email) {
            showError("Please enter a valid email address", textField: emailTextField)
            return false
        }
        
        // Validate password
        guard let password = passwordTextField.text,
              !password.isEmpty else {
            showError("Please enter your password", textField: passwordTextField)
            return false
        }
        
        if password.count < 6 {
            showError("Password must be at least 6 characters", textField: passwordTextField)
            return false
        }
        
        // Validate name
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty else {
            showError("Please enter your name", textField: nameTextField)
            return false
        }
        
        if name.count < 2 {
            showError("Name must be at least 2 characters", textField: nameTextField)
            return false
        }
        
        // Validate username
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty else {
            showError("Please enter a username", textField: usernameTextField)
            return false
        }
        
        if username.count < 3 {
            showError("Username must be at least 3 characters", textField: usernameTextField)
            return false
        }
        
        if !isValidUsername(username) {
            showError("Username can only contain letters, numbers, and underscores", textField: usernameTextField)
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func isValidUsername(_ username: String) -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format:"SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: username)
    }
    
    private func showError(_ message: String, textField: UITextField? = nil) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        if let textField = textField {
            textField.layer.borderColor = UIColor.systemRed.cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    private func resetFieldErrors() {
        [emailTextField, passwordTextField, nameTextField, usernameTextField].forEach { textField in
            textField?.layer.borderWidth = 0
        }
    }
    
    private func setLoading(_ loading: Bool) {
        signUpButton.isEnabled = !loading
        if loading {
            loadingIndicator.startAnimating()
            signUpButton.setTitle("", for: .disabled)
        } else {
            loadingIndicator.stopAnimating()
            signUpButton.setTitle("Continue", for: .normal)
        }
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
