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
        
        if isPresenting {
            let toView = toViewController.view!
            toView.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: containerView.bounds.height)
            containerView.addSubview(toView)
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                         delay: 0,
                         options: .curveEaseInOut,
                         animations: {
                fromViewController.view.alpha = 0.5
                toView.frame = containerView.bounds
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        } else {
            let toView = toViewController.view!
            let fromView = fromViewController.view!
            
            // Ensure the destination view is in the container and behind the current view
            if toView.superview == nil {
                containerView.insertSubview(toView, belowSubview: fromView)
                toView.frame = containerView.bounds
            }
            
            // Reset the alpha of the destination view
            toView.alpha = 0.5
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext),
                         delay: 0,
                         options: .curveEaseInOut,
                         animations: {
                fromView.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: containerView.bounds.height)
                toView.alpha = 1.0
            }, completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            })
        }
    }
}
