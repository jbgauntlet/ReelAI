import UIKit

class MainTabBarController: UIViewController {
    
    private var viewControllers: [UIViewController] = []
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 0
    private var currentVC: UIViewController?
    
    private let tabBarView = UIView()
    private let tabBarHeight: CGFloat = 90
    private let tabBarStackViewHeight: CGFloat = 70
    private let buttonCount: CGFloat = 5;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.isHidden = true // Hide the navigation bar
        
        setupViewControllers()
        setupTabBar()
        setupButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Ensure tab selection happens after layout
        if currentVC == nil {
            selectTab(at: selectedIndex)
        }
    }
    
    private func setupViewControllers() {
        let homeVC = UINavigationController(rootViewController: VideoScrollContentViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        
        let friendsVC = UINavigationController(rootViewController: FriendsViewController())
        friendsVC.tabBarItem = UITabBarItem(title: "Friends", image: UIImage(systemName: "person.2"), selectedImage: UIImage(systemName: "person.2.fill"))
        
        let videoFeedVC = UINavigationController(rootViewController: UIViewController())
        videoFeedVC.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "create-video"), tag: 2)
        
        let uploadVC = UINavigationController(rootViewController: MessagesViewController())
        uploadVC.tabBarItem = UITabBarItem(title: "Inbox", image: UIImage(systemName: "bubble"), selectedImage: UIImage(systemName: "bubble.fill"))
        
        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        
        viewControllers = [homeVC, friendsVC, videoFeedVC, uploadVC, profileVC]
    }
    
    private func setupTabBar() {
        tabBarView.backgroundColor = .white
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBarView)
        
        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: tabBarHeight)
        ])
        
        GlobalDataManager.shared.globalNav = tabBarView // Ensure this is weakly referenced in GlobalDataManager
    }
    
    private func setupButtons() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        tabBarView.addSubview(stackView)

        var buttonWidthSum: CGFloat = 0
        for (index, viewController) in viewControllers.enumerated() {
            let button = UIButton(type: .custom)
            button.tag = index
            button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            
            var buttonImage: UIImage? = nil
            if(index == 2) {
                if let image = viewController.tabBarItem.image {
                    buttonImage = image.withRenderingMode(.alwaysOriginal).resizeWithHeight(to: 25)
                    button.setImage(buttonImage, for: .normal)
                }
                if let selectedImage = viewController.tabBarItem.selectedImage {
                    buttonImage = selectedImage.withRenderingMode(.alwaysOriginal).resizeWithHeight(to: 25)
                    button.setImage(buttonImage, for: .selected)
                }
            }
            else {
                if let image = viewController.tabBarItem.image {
                    buttonImage = image.withRenderingMode(.alwaysOriginal).resizeWithHeight(to: 25)?.withTintColor(.gray)
                    button.setImage(buttonImage, for: .normal)
                }
                if let selectedImage = viewController.tabBarItem.selectedImage {
                    buttonImage = selectedImage.withRenderingMode(.alwaysOriginal).resizeWithHeight(to: 25)?.withTintColor(.black)
                    button.setImage(buttonImage, for: .selected)
                }
            }
            buttonWidthSum += buttonImage?.size.width ?? 0
            
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        let stackViewHorizontalPadding = (UIScreen.main.bounds.width - buttonWidthSum) / buttonCount;
        print(stackViewHorizontalPadding, tabBarView.bounds.width, UIScreen.main.bounds.width, view.bounds.width, "buttonWidthSum")
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: tabBarView.leadingAnchor, constant: stackViewHorizontalPadding / 2),
            stackView.trailingAnchor.constraint(equalTo: tabBarView.trailingAnchor, constant: -stackViewHorizontalPadding / 2),
            stackView.bottomAnchor.constraint(equalTo: tabBarView.bottomAnchor, constant: tabBarStackViewHeight - tabBarHeight),
            stackView.heightAnchor.constraint(equalToConstant: tabBarStackViewHeight)
        ])
    }
    
    private func selectTab(at index: Int) {
        if index != 0 && GlobalDataManager.shared.user == nil {
            let authVC = AuthenticationModalViewController()
            authVC.modalPresentationStyle = .custom
            authVC.transitioningDelegate = authVC
            present(authVC, animated: true)
            return
        }
        
        if index == 2 {
            let cameraVC = CameraViewController()
            cameraVC.modalPresentationStyle = .fullScreen
            present(cameraVC, animated: true)
            return
        }
        
        let selectedVC = viewControllers[index]
        
        if let currentVC = currentVC {
            currentVC.willMove(toParent: nil)
            currentVC.view.removeFromSuperview()
            currentVC.removeFromParent()
        }
        
        addChild(selectedVC)
        selectedVC.view.frame = view.bounds
        view.insertSubview(selectedVC.view, belowSubview: tabBarView)
        selectedVC.didMove(toParent: self)
        
        currentVC = selectedVC
        updateTabSelection(index: index)
    }
    
    private func updateTabSelection(index: Int) {
        for (i, button) in buttons.enumerated() {
            button.isSelected = (i == index)
        }
        selectedIndex = index
    }
    
    @objc private func tabButtonTapped(_ sender: UIButton) {
        selectTab(at: sender.tag)
    }
}
