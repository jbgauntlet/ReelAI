
import Foundation
import UIKit

func navigateToControllerAsRootController(_ currentWindow: UIWindow?, _ viewController: UIViewController) {
    let navigationController = UINavigationController(rootViewController: viewController)
    if let window = currentWindow {
        window.rootViewController = navigationController
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
}
