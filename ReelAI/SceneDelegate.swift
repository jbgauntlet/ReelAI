import UIKit
import FirebaseCore
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Custom function to be called when the app opens
        onAppOpen()
        
        // Initializing the window with the scene's coordinate bounds
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        window?.windowScene = windowScene
        
        // Check if the user is authenticated
        let isAuthenticated = GlobalDataManager.shared.user != nil
        
        // Set initialViewController to MainTabBarController if authenticated else SplashScreenViewController and wrap as UINavigationController
        let initialViewController = isAuthenticated ? MainTabBarController() : SplashScreenViewController()
        let navigationController = UINavigationController(rootViewController: initialViewController)
        
        // Set the root view controller
        window?.rootViewController = navigationController
        
        // Make the window key and visible
        window?.makeKeyAndVisible()
        
        // Handle any URLs that were passed when launching the app
        if let urlContext = connectionOptions.urlContexts.first {
            _ = self.scene(scene, openURLContexts: [urlContext])
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
    // MARK: - Private Methods
    
    private func onAppOpen() {
        // Testing function
        testing()
        
        // Authenticate user on app open
        fetchUser()

    }
    
    private func fetchUser() {
        // First check if we have a Firebase user
        if let currentUser = Auth.auth().currentUser {
            print("✅ Found Firebase current user")
            _ = GlobalDataManager.shared.handleLoginSuccess(currentUser)
            return
        }
        
        // If no current Firebase user, try to restore from keychain
        print("🔑 Attempting to restore user from keychain")
        if let uid = retrieveFromKeychain(forKey: "uid", service: SERVICE),
           let email = retrieveFromKeychain(forKey: "email", service: SERVICE),
           let displayName = retrieveFromKeychain(forKey: "displayName", service: SERVICE),
           let token = retrieveFromKeychain(forKey: "FirebaseToken", service: SERVICE) {
            
            print("✅ Found user data in keychain")
            
            // Create user object using the new keychain initializer
            GlobalDataManager.shared.user = User(uid: uid, email: email, displayName: displayName)
            
            // Verify the token with Firebase
            Auth.auth().signIn(withCustomToken: token) { (result, error) in
                if let error = error {
                    print("❌ Error verifying token: \(error.localizedDescription)")
                    // Clear invalid data
                    GlobalDataManager.shared.clearUserData()
                } else {
                    print("✅ Successfully verified Firebase token")
                    // Update user with fresh Firebase data if available
                    if let firebaseUser = result?.user {
                        GlobalDataManager.shared.user = User(from: firebaseUser)
                    }
                }
            }
        } else {
            print("⚠️ No user data found in keychain")
        }
    }
            

    
    private func testing() {

    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        // Handle the URL (Firebase Auth will handle this automatically)
        if Auth.auth().canHandle(url) {
            // Firebase Auth will handle the URL
        }
    }

}
