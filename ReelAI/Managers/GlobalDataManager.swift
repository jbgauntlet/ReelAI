import Foundation
import UIKit
import FirebaseAuth

class GlobalDataManager {
    
    static let shared = GlobalDataManager()
    var globalNav = UIView()
    var user: User?

    private init() {}
    
    func handleLoginSuccess(_ firebaseUser: FirebaseAuth.User) -> Bool {
        // Get the ID token
        firebaseUser.getIDToken { token, error in
            if let token = token {
                // Save Firebase token
                _ = saveToKeychain(value: token, forKey: "FirebaseToken", service: SERVICE)
            }
        }
        
        // Save essential user data
        let successUID = saveToKeychain(value: firebaseUser.uid, forKey: "uid", service: SERVICE)
        let successEmail = saveToKeychain(value: firebaseUser.email ?? "", forKey: "email", service: SERVICE)
        let successDisplayName = saveToKeychain(value: firebaseUser.displayName ?? "", forKey: "displayName", service: SERVICE)
        
        // Create and set user object using the new initializer
        self.user = User(from: firebaseUser)
        
        return successUID && successEmail && successDisplayName
    }
    
    func clearUserData() {
        // Clear keychain data
        _ = deleteFromKeychain(forKey: "FirebaseToken", service: SERVICE)
        _ = deleteFromKeychain(forKey: "uid", service: SERVICE)
        _ = deleteFromKeychain(forKey: "email", service: SERVICE)
        _ = deleteFromKeychain(forKey: "displayName", service: SERVICE)
        
        // Clear memory
        user = nil
    }
    
    func logout(from viewController: UIViewController) {
        do {
            // Sign out from Firebase
            try Auth.auth().signOut()
            
            // Clear all stored user data
            clearUserData()
            
            // Navigate to splash screen
            if let window = viewController.view.window {
                let splashScreen = SplashScreenViewController()
                let navigationController = UINavigationController(rootViewController: splashScreen)
                window.rootViewController = navigationController
                
                // Add animation for smooth transition
                UIView.transition(with: window,
                                duration: 0.3,
                                options: .transitionCrossDissolve,
                                animations: nil,
                                completion: nil)
            }
            
            print("✅ Successfully logged out")
        } catch let error {
            print("❌ Error signing out: \(error.localizedDescription)")
        }
    }
}
