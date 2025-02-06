import UIKit

class MainTabBarController: UIViewController {
    
    // Properties to hold the child view controllers, buttons, labels, and selected index
    private var viewControllers: [UIViewController] = []
    private var buttons: [UIButton] = []
    private var labels: [UILabel] = []
    private var selectedIndex: Int = 0
    private var views: [UIView] = []
    
    // Tab bar view
    private let tabBarView = UIView()
    private let tabBarHeight: CGFloat = 90 // Standard tab bar height
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide default navigation bar
        navigationController?.navigationBar.isHidden = true
        
        // Initialize the view controllers with their respective navigation controllers and tab bar items
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        homeVC.tabBarItem.tag = 0
        
        let friendsVC = UINavigationController(rootViewController: ProfileListsViewController())
        friendsVC.tabBarItem = UITabBarItem(title: "Friends", image: UIImage(systemName: "person.2"), selectedImage: UIImage(systemName: "person.2.fill"))
        friendsVC.tabBarItem.tag = 1
        
        let videoFeedVC = UINavigationController(rootViewController: VideoScrollContentViewController())
        videoFeedVC.tabBarItem = UITabBarItem(title: "", image: UIImage(systemName: "plus.circle.fill"), selectedImage: UIImage(systemName: "plus.circle.fill"))
        videoFeedVC.tabBarItem.tag = 2
        
        let uploadVC = UINavigationController(rootViewController: UploadViewController())
        uploadVC.tabBarItem = UITabBarItem(title: "Upload", image: UIImage(systemName: "video.badge.plus"), selectedImage: UIImage(systemName: "video.badge.plus.fill"))
        uploadVC.tabBarItem.tag = 3
        
        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        profileVC.tabBarItem.tag = 4
        
        viewControllers = [homeVC, friendsVC, videoFeedVC, uploadVC, profileVC]
        
        // Setup the custom tab bar and the child view controllers
        setupTabBar()
        setupViewControllers()
        
        // Select the initial tab
        selectTab(at: selectedIndex)
    }
    
    // Function to set up child view controllers, buttons, and labels
    func setupViewControllers() {
        // Initialize buttons for each tab
        for _ in 0..<viewControllers.count {
            let button = UIButton(type: .custom)
            buttons.append(button)
        }
        
        // Configure each button and its corresponding view controller
        for (index, viewController) in viewControllers.enumerated() {
            // Add the child view controllers to the container
            addChild(viewController)
            viewController.didMove(toParent: self)
            
            
            // Configure the button for each view controller
            buttons[index].tag = index
            buttons[index].addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)
            
            if index == 2 {
                // Customize the middle button (e.g., larger size, no title)
                let image = viewController.tabBarItem.image?.withRenderingMode(.alwaysOriginal).withTintColor(.black)
                let resizedImage = image!.resized(to: CGSize(width: 50, height: 50))
                
                buttons[index].setImage(resizedImage, for: .normal)
                buttons[index].setImage(viewController.tabBarItem.selectedImage, for: .selected)
            } else {
                // Customize other buttons
                let image = viewController.tabBarItem.image?.withRenderingMode(.alwaysOriginal).withTintColor(ColorPalette.gray)
                
                // Scale to keep aspect ratio
                let size = image?.size
                let oldWidth = size?.width
                let oldHeight = size?.height
                let scaleFactor = 25.0 / oldHeight!
                let newWidth = oldWidth! * scaleFactor
                
                let resizedImage = image!.resized(to: CGSize(width: newWidth, height: 25))
                let selectedImage = viewController.tabBarItem.selectedImage?.withRenderingMode(.alwaysOriginal).withTintColor(.black)
                buttons[index].setImage(resizedImage, for: .normal)
                buttons[index].setImage(selectedImage, for: .selected)
            }
            
            buttons[index].translatesAutoresizingMaskIntoConstraints = false
        }
        
        // Initialize views for button layout
        for _ in 0..<viewControllers.count {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            views.append(view)
            
            // Add views to the tab bar view
            tabBarView.addSubview(view)
        }
        
        // Define layout constraints for the tab bar views
        let width = view.bounds.width
        let iconWidth = 60.0
        let spacePer = (width - (iconWidth * 5)) / 5
        
        NSLayoutConstraint.activate([
            views[0].trailingAnchor.constraint(equalTo: views[1].leadingAnchor, constant: -spacePer),
            views[0].widthAnchor.constraint(equalToConstant: iconWidth),
            views[0].centerYAnchor.constraint(equalTo: tabBarView.centerYAnchor, constant: -10),
            
            views[1].trailingAnchor.constraint(equalTo: views[2].leadingAnchor, constant: -spacePer),
            views[1].widthAnchor.constraint(equalToConstant: iconWidth),
            views[1].centerYAnchor.constraint(equalTo: tabBarView.centerYAnchor, constant: -10),
            
            views[2].centerXAnchor.constraint(equalTo: tabBarView.centerXAnchor),
            views[2].widthAnchor.constraint(equalToConstant: iconWidth),
            views[2].centerYAnchor.constraint(equalTo: tabBarView.centerYAnchor, constant: -10),
            
            views[3].leadingAnchor.constraint(equalTo: views[2].trailingAnchor, constant: spacePer),
            views[3].widthAnchor.constraint(equalToConstant: iconWidth),
            views[3].centerYAnchor.constraint(equalTo: tabBarView.centerYAnchor, constant: -10),
            
            views[4].leadingAnchor.constraint(equalTo: views[3].trailingAnchor, constant: spacePer),
            views[4].widthAnchor.constraint(equalToConstant: iconWidth),
            views[4].centerYAnchor.constraint(equalTo: tabBarView.centerYAnchor, constant: -10),
        ])
        
        // Configure labels for non-middle buttons
        let labelConfigs = [("Home", views[0]), ("Friends", views[1]), ("", UIView()), ("Upload", views[3]), ("Profile", views[4])]
        
        for (index, config) in labelConfigs.enumerated() {
            if index == 2 { continue }
            
            let label = UILabel()
            label.text = config.0
            label.textColor = ColorPalette.gray
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
            label.translatesAutoresizingMaskIntoConstraints = false
            labels.append(label)
            
            config.1.addSubview(buttons[index])
            config.1.addSubview(label)
            NSLayoutConstraint.activate([
                buttons[index].leadingAnchor.constraint(equalTo: config.1.leadingAnchor),
                buttons[index].trailingAnchor.constraint(equalTo: config.1.trailingAnchor),
                buttons[index].topAnchor.constraint(equalTo: config.1.topAnchor),
                
                label.leadingAnchor.constraint(equalTo: config.1.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: config.1.trailingAnchor),
                label.topAnchor.constraint(equalTo: buttons[index].bottomAnchor),
                label.bottomAnchor.constraint(equalTo: config.1.bottomAnchor)
            ])
        }
        
        // Add middle button without a label
        views[2].addSubview(buttons[2])
        NSLayoutConstraint.activate([
            buttons[2].leadingAnchor.constraint(equalTo: views[2].leadingAnchor),
            buttons[2].trailingAnchor.constraint(equalTo: views[2].trailingAnchor),
            buttons[2].topAnchor.constraint(equalTo: views[2].topAnchor),
            buttons[2].bottomAnchor.constraint(equalTo: views[2].bottomAnchor)
        ])
        
        // Add empty UILabel to maintain array structure consistency
        labels.insert(UILabel(), at: 2)
    }
    
    // Function to set up the custom tab bar view
    private func setupTabBar() {
        // Customize the tab bar view
        tabBarView.backgroundColor = .white
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBarView)
        
        // Set constraints for the tab bar view
        NSLayoutConstraint.activate([
            tabBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarView.heightAnchor.constraint(equalToConstant: tabBarHeight)
        ])
        
        GlobalDataManager.shared.globalNav = tabBarView
    }
    
    // Function to select and display the desired tab's view controller
    private func selectTab(at index: Int) {
        if(index != 0 && GlobalDataManager.shared.user == nil) {
            let authVC = AuthenticationModalViewController()
            authVC.modalPresentationStyle = .custom
            authVC.transitioningDelegate = authVC
            
            present(authVC, animated: true, completion: nil)
            return
        }
        
        print("Selecting tab at index: \(index)")
        
        // Remove the current view controller's view
        let currentVC = viewControllers[selectedIndex]
        currentVC.view.removeFromSuperview()
        
        // Add the selected view controller's view
        let selectedVC = viewControllers[index]
        selectedVC.view.frame = CGRect(
            x: view.bounds.minX,
            y: view.bounds.minY,
            width: view.bounds.width,
            height: view.bounds.height - tabBarHeight
        )
        view.insertSubview(selectedVC.view, belowSubview: tabBarView)
        
        // Update the selected button state and label colors
        print("Deselecting tab at index: \(selectedIndex)")
        buttons[selectedIndex].isSelected = false
        let originalImage = viewControllers[selectedIndex].tabBarItem.image?.withRenderingMode(.alwaysOriginal).withTintColor(ColorPalette.gray)
        print("Setting original image for deselected tab: \(String(describing: originalImage))")
        buttons[selectedIndex].setImage(originalImage, for: .normal)

        print("Selecting tab at index: \(index)")
        buttons[index].isSelected = true
        let filledImage = viewControllers[index].tabBarItem.selectedImage?.withRenderingMode(.alwaysOriginal).withTintColor(.black)
        print("Setting filled image for selected tab: \(String(describing: filledImage))")
        buttons[index].setImage(filledImage, for: .normal)

        labels[selectedIndex].textColor = ColorPalette.gray
        labels[index].textColor = .black
        
        // Update the selected index
        selectedIndex = index
    }
    
    // Function to handle tab button tap events
    @objc private func tabButtonTapped(_ sender: UIButton) {
        selectTab(at: sender.tag)
    }
}
