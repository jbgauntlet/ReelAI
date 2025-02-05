

import UIKit

class AuthenticationModalViewController: UIViewController {
    
    let modalView = UIView()

    let bar = UIView()
    let signInButton = UIButton()
    let signUpButton = UIButton()
    
    let barHeight = 5.0
    let buttonHeight = 60.0
    let verticalPadding = 30.0
    let horizontalPadding = 30.0
    var safeAreaDifference = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupModalView()
        setupGestureRecognizers()
        setupContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.animate(withDuration: 0.3) {
            self.modalView.transform = .identity
        }
    }
    
    private func setupModalView() {
        let modalViewHeight = buttonHeight * 2 + barHeight + verticalPadding * 4.5
        modalView.backgroundColor = .white
        modalView.layer.cornerRadius = horizontalPadding
        modalView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(modalView)
        
        NSLayoutConstraint.activate([
            modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            modalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            modalView.heightAnchor.constraint(equalToConstant: modalViewHeight)
        ])
    }
    
    private func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        modalView.addGestureRecognizer(panGesture)
    }
    
    private func setupContent() {
        bar.backgroundColor = ColorPalette.midnightBlue
        bar.layer.cornerRadius = barHeight / 2
        bar.translatesAutoresizingMaskIntoConstraints = false
        modalView.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: modalView.topAnchor, constant: verticalPadding / 2),
            bar.heightAnchor.constraint(equalToConstant: barHeight),
            bar.widthAnchor.constraint(equalTo: modalView.widthAnchor, multiplier: 0.2),
            bar.centerXAnchor.constraint(equalTo: modalView.centerXAnchor),
        ])
        
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.backgroundColor = .black
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.addTarget(self, action: #selector(handleSignUpButtonTapped), for: .touchUpInside)
        signUpButton.layer.cornerRadius = buttonHeight / 2
        signUpButton.translatesAutoresizingMaskIntoConstraints = false
        modalView.addSubview(signUpButton)
        NSLayoutConstraint.activate([
            signUpButton.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: verticalPadding),
            signUpButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            signUpButton.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: horizontalPadding),
            signUpButton.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -horizontalPadding),
        ])
        
        signInButton.setTitle("Sign In", for: .normal)
        signInButton.backgroundColor = .white
        signInButton.setTitleColor(.black, for: .normal)
        signInButton.layer.cornerRadius = buttonHeight / 2
        signInButton.addTarget(self, action: #selector(handleSignInButtonTapped), for: .touchUpInside)
        signInButton.layer.borderColor = UIColor.black.cgColor
        signInButton.layer.borderWidth = 1
        signInButton.translatesAutoresizingMaskIntoConstraints = false
        modalView.addSubview(signInButton)
        NSLayoutConstraint.activate([
            signInButton.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: verticalPadding / 2),
            signInButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            signInButton.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: horizontalPadding),
            signInButton.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -horizontalPadding),
        ])
    }
    
    @objc private func handleSignUpButtonTapped() {
        navigateToController(SignUpViewController())
    }
        
    @objc private func handleSignInButtonTapped() {
        navigateToController(SignInViewController())
    }
    
    @objc private func navigateToController(_ controller: UIViewController) {
        if let navController = presentingViewController as? UINavigationController {
            navController.pushViewController(controller, animated: true)
            dismiss(animated: false)
        } else {
            print("Presenting view controller is not a UINavigationController")
        }
    }
    
    @objc private func handleBackgroundTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: view)
        if !modalView.frame.contains(location) {
            dismissModal()
        }
    }
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: modalView)
        if translation.y > 0 { // Only allow dragging downwards
            modalView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        }
        
        if sender.state == .ended {
            let velocity = sender.velocity(in: modalView)
            let shouldDismiss = translation.y > modalView.frame.height * 0.3 || velocity.y > 500
            
            if shouldDismiss {
                UIView.animate(withDuration: 0.3, animations: {
                    self.modalView.transform = CGAffineTransform(translationX: 0, y: self.modalView.frame.height)
                }, completion: { _ in
                    self.dismissModal()
                })
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.modalView.transform = .identity
                }
            }
        }
    }
    
    @objc func dismissModal() {
        dismiss(animated: true)
    }
}

extension AuthenticationModalViewController : UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
