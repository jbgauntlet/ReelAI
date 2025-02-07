

import UIKit


class VerifyAccountViewController: UIViewController, UITextFieldDelegate {

    let backButton = UIButton()
    let contentContainerView = UIView()
    let verifyLabel = UILabel()
    let codeTextField = PaddedTextField(padding: UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
    let verifyButton = UIButton()
    
    let userId: Int
    let email: String
    let password: String
    let firstname: String
    let lastname: String
    
    init(_ userId: Int, _ email: String, _ password: String, _ firstname: String, _ lastname: String) {
        self.userId = userId
        self.email = email
        self.password = password
        self.firstname = firstname
        self.lastname = lastname
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        verifyLabel.text = "Verify your account"
        verifyLabel.font = UIFont(descriptor: fontDescriptor, size: 28)
        verifyLabel.textAlignment = .center
        verifyLabel.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(verifyLabel)
        NSLayoutConstraint.activate([
            verifyLabel.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            verifyLabel.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            verifyLabel.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            verifyLabel.heightAnchor.constraint(equalToConstant: labelHeight),
        ])
        
        codeTextField.placeholder = "Verification Code"
        codeTextField.backgroundColor = ColorPalette.lightGray
        codeTextField.layer.cornerRadius = textFieldHeight / 6
        codeTextField.autocorrectionType = .no
        codeTextField.autocapitalizationType = .allCharacters
        codeTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        codeTextField.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(codeTextField)
        NSLayoutConstraint.activate([
            codeTextField.topAnchor.constraint(equalTo: verifyLabel.bottomAnchor, constant: verticalPadding),
            codeTextField.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: horizontalPadding),
            codeTextField.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor,constant: -horizontalPadding),
            codeTextField.heightAnchor.constraint(equalToConstant: textFieldHeight)
        ])
        
        verifyButton.alpha = 0.5
        verifyButton.isEnabled = false
        verifyButton.setTitle("Continue", for: .normal)
        verifyButton.backgroundColor = .black
        verifyButton.setTitleColor(.white, for: .normal)
        verifyButton.layer.cornerRadius = buttonHeight / 2
        verifyButton.addTarget(self, action: #selector(handleVerifyButtonTapped), for: .touchUpInside)
        verifyButton.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(verifyButton)
        NSLayoutConstraint.activate([
            verifyButton.topAnchor.constraint(equalTo: codeTextField.bottomAnchor, constant: verticalPadding),
            verifyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            verifyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            verifyButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
    }
    
    @objc func handleBackButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func handleVerifyButtonTapped() {
        guard let code = codeTextField.text else { return }
        
        verifyAccount(code)
    }
    
    func verifyAccount(_ code: String) {
        navigateToControllerAsRootController(self.view.window, MainTabBarController())
    }
    
//    func login(completion: @escaping (Bool) -> Void) {
//        APICaller.shared.sendRequest(LoginRequest(email: email, password: password), "login", .POST, false, LoginResponse.self) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let response):
//                    let success = GlobalDataManager.shared.handleLoginSuccess(response)
//                    if(success) {
//                        GlobalDataManager.shared.user?.email = self.email
//                        GlobalDataManager.shared.user?.lastname = self.lastname
//                        GlobalDataManager.shared.user?.userId = self.userId
//                    }
//                    completion(success)
//                case .failure(let error):
//                    print(error.localizedDescription)
//                    completion(false)
//                }
//            }
//        }
//    }
    
    @objc func textFieldDidChange() {
        var canSubmit = true
        let code = codeTextField.text ?? ""
        
        if(code.isEmpty) { canSubmit = false }
        
        verifyButton.isEnabled = canSubmit
        verifyButton.alpha = canSubmit ? 1.0 : 0.5
    }
    
}
