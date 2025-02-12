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
    
    // Add error label and loading indicator
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
    
    private let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Don't have an account? Sign Up", for: .normal)
        button.setTitleColor(ColorPalette.gray, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
        emailTextField.delegate = self
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
        passwordTextField.delegate = self
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
        
        // Add error label, loading indicator, and sign up button
        contentContainerView.addSubview(errorLabel)
        contentContainerView.addSubview(loadingIndicator)
        contentContainerView.addSubview(signUpButton)
        
        NSLayoutConstraint.activate([
            errorLabel.topAnchor.constraint(equalTo: signInButton.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: signInButton.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: signInButton.trailingAnchor, constant: -16),
            
            signUpButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            signUpButton.heightAnchor.constraint(equalToConstant: buttonHeight)
        ])
        
        signUpButton.addTarget(self, action: #selector(handleSignUpButtonTapped), for: .touchUpInside)
        
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
        guard validateFields() else { return }
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text else { return }
        
        setLoading(true)
        signIn(email, password)
    }
    
    func signIn(_ email: String, _ password: String) {
        // Verify Firebase Auth is initialized
        guard Auth.auth() != nil else {
            showError("Authentication service is not available")
            setLoading(false)
            return
        }
        
        // Sign in with Firebase Auth
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    if let authError = AuthErrorCode(rawValue: error.code) {
                        switch authError {
                        case .wrongPassword:
                            self.showError("Incorrect password. Please try again.", textField: self.passwordTextField)
                        case .invalidEmail:
                            self.showError("Please enter a valid email address", textField: self.emailTextField)
                        case .userNotFound:
                            self.showError("We couldn't find an account with this email. Please check your email or sign up.", textField: self.emailTextField)
                        case .userDisabled:
                            self.showError("This account has been disabled. Please contact support.")
                        case .tooManyRequests:
                            self.showError("Too many sign-in attempts. Please wait a moment and try again.")
                        case .networkError:
                            self.showError("Unable to connect. Please check your internet connection and try again.")
                        case .invalidCredential:
                            self.showError("Your login information appears to be incorrect. Please try again.", textField: self.emailTextField)
                        case .credentialAlreadyInUse:
                            self.showError("This email is already linked to another account.")
                        case .requiresRecentLogin:
                            self.showError("For security reasons, please sign in again.")
                        case .emailAlreadyInUse:
                            self.showError("This email is already registered. Please sign in instead of creating a new account.")
                        default:
                            self.showError("Something went wrong. Please try again.")
                        }
                    } else {
                        self.showError("Unable to sign in at this time. Please try again later.")
                    }
                    self.setLoading(false)
                    return
                }
                
                guard let user = authResult?.user else {
                    self.showError("An error occurred. Please try again")
                    self.setLoading(false)
                    return
                }
                
                // Fetch user data from Firestore
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).getDocument { [weak self] (document, error) in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if let error = error {
                            self.showError("Error fetching user data: \(error.localizedDescription)")
                            self.setLoading(false)
                            return
                        }
                        
                        guard let document = document, document.exists,
                              let userData = document.data() else {
                            self.showError("User data not found")
                            self.setLoading(false)
                            return
                        }
                        
                        // Create user model from Firestore data
                        if let userModel = User(from: userData, uid: user.uid) {
                            GlobalDataManager.shared.user = userModel
                            // Navigate to main screen
                            navigateToControllerAsRootController(self.view.window, MainTabBarController())
                        } else {
                            self.showError("Error loading user data")
                            self.setLoading(false)
                        }
                    }
                }
            }
        }
    }
    
    @objc func textFieldDidChange() {
        resetFieldErrors()
        errorLabel.isHidden = true
        
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
    
    // MARK: - Validation
    private func validateFields() -> Bool {
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
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - UI Helpers
    private func showError(_ message: String, textField: UITextField? = nil) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        if let textField = textField {
            textField.layer.borderColor = UIColor.systemRed.cgColor
            textField.layer.borderWidth = 1
        }
    }
    
    private func resetFieldErrors() {
        [emailTextField, passwordTextField].forEach { textField in
            textField?.layer.borderWidth = 0
        }
    }
    
    private func setLoading(_ loading: Bool) {
        signInButton.isEnabled = !loading
        if loading {
            loadingIndicator.startAnimating()
            signInButton.setTitle("", for: .disabled)
        } else {
            loadingIndicator.stopAnimating()
            signInButton.setTitle("Sign In", for: .normal)
        }
    }
    
    @objc private func handleSignUpButtonTapped() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension SignInViewController {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            if signInButton.isEnabled {
                handleSignInButtonTapped()
            }
        }
        return true
    }
}




