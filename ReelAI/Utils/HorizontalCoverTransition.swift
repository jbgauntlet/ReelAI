import UIKit

class HorizontalCoverTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    var isPresenting: Bool = true // Property to determine the direction of the transition
    
    // Specify the duration of the animation transition
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35 // The transition will last 0.35 seconds
    }
    
    // Handle the animation of the transition
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from) else {
            return // Exit if the view controllers can't be found
        }
        
        let containerView = transitionContext.containerView
        let screenWidth = containerView.bounds.width
        
        let toView = toViewController.view!
        
        if isPresenting {
            print("toView: " + toView.description)
            print("toViewController: " + toViewController.description)
            print("fromViewController: " + fromViewController.description)
            
            // Presenting (forward transition)
            toView.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: containerView.bounds.height)
            containerView.addSubview(toView)
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromViewController.view.alpha = 0.5 // Optional: Dim the underlying view
                toView.frame = containerView.bounds // Slide in toView from the right
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            print("toView: " + toView.description)
            print("toViewController: " + toViewController.description)
            print("fromViewController: " + fromViewController.description)
            
            // Dismissing (backward transition)
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromViewController.view.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: containerView.bounds.height) // Slide out to the right
                toView.alpha = 1.0 // Restore the alpha of the toView
            }, completion: { finished in
                fromViewController.view.removeFromSuperview() // Remove the fromView from the hierarchy
                transitionContext.completeTransition(finished)
            })
        }
    }
}
