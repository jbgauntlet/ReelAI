

import UIKit

class SplashScreenViewController: UIViewController {
    
    let topView = UIView()
    let bottomView = UIView()
    
    var logoImageView = UIImageView()
    let tagline = UILabel()
    let getStartedButton = UIButton()
    let signUpButton = UIButton()
    
    var safeAreaDifference = 0.0
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        
        let safeAreaTop = view.safeAreaLayoutGuide.layoutFrame.minY
        let safeAreaBottom = view.safeAreaLayoutGuide.layoutFrame.maxY
        safeAreaDifference = safeAreaBottom - safeAreaTop
        
        setupViews()
        setupContent()
    }
    
    func setupViews() {
        topView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topView)
        
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomView)
        
        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topView.heightAnchor.constraint(equalToConstant: safeAreaDifference / 2),
            
            bottomView.topAnchor.constraint(equalTo: topView.bottomAnchor),
            bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func setupContent() {
        let logoImageWidth = view.bounds.width * 0.75
        let logoImage = UIImage(named: "splash-logo")?.resizeWithWidth(to: logoImageWidth)
        let logoImageHeight = logoImage?.size.height ?? 0
        logoImageView = UIImageView(image: logoImage)
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(logoImageView)

        tagline.text = "Unleash your creativity and connect through endless reels!"
        tagline.font = UIFont.systemFont(ofSize: 18)
        tagline.textColor = .black
        tagline.numberOfLines = 0
        tagline.textAlignment = .center
        tagline.translatesAutoresizingMaskIntoConstraints = false
        topView.addSubview(tagline)

        let buttonHeight = 60.0
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.backgroundColor = .black
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.layer.cornerRadius = buttonHeight / 2
        getStartedButton.addTarget(self, action: #selector(navigateToMainScreen), for: .touchUpInside)
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(getStartedButton)
        
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.backgroundColor = .white
        signUpButton.setTitleColor(.black, for: .normal)
        signUpButton.addTarget(self, action: #selector(navigateToAuthentication), for: .touchUpInside)
        signUpButton.layer.borderColor = UIColor.black.cgColor
        signUpButton.layer.borderWidth = 1
        signUpButton.layer.cornerRadius = buttonHeight / 2
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        bottomView.addSubview(signUpButton) // Add "Sign Up" button to the view

        let verticalButtonPadding = 7.5
        let horizontalPadding = 30.0
        
        NSLayoutConstraint.activate([
            logoImageView.centerYAnchor.constraint(equalTo: topView.centerYAnchor),
            logoImageView.heightAnchor.constraint(equalToConstant: logoImageHeight),
            logoImageView.widthAnchor.constraint(equalToConstant: logoImageWidth),
            logoImageView.centerXAnchor.constraint(equalTo: topView.centerXAnchor),

            tagline.topAnchor.constraint(equalTo: logoImageView.bottomAnchor),
            tagline.leadingAnchor.constraint(equalTo: topView.leadingAnchor, constant: horizontalPadding * 1.5),
            tagline.trailingAnchor.constraint(equalTo: topView.trailingAnchor, constant: -(horizontalPadding * 1.5)),
            tagline.bottomAnchor.constraint(equalTo: getStartedButton.topAnchor),
            
            getStartedButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor, constant: -(buttonHeight / 2 + verticalButtonPadding)),
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            getStartedButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            signUpButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor, constant: buttonHeight / 2 + verticalButtonPadding),
            signUpButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: horizontalPadding),
            signUpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -horizontalPadding),
            signUpButton.heightAnchor.constraint(equalToConstant: buttonHeight),
        ])
    }

    // MARK: - Navigation Methods

    @objc func navigateToMainScreen() {
        navigateToControllerAsRootController(view.window, MainTabBarController())
    }
    
    @objc func navigateToAuthentication() {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }
}
