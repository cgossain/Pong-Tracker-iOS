//
//  PopPresentationAnimator.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-28.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class PopPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let presenting: Bool
    
    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }
    
    // MARK: UIViewControllerAnimatedTransitioning
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return self.presenting ? 0.4 : 0.4
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if self.presenting {
            self.animatePresentationWithTransitionContext(transitionContext)
        }
        else {
            self.animateDismissalWithTransitionContext(transitionContext)
        }
    }
    
    // MARK: Methods (Private)
    
    func animatePresentationWithTransitionContext(context: UIViewControllerContextTransitioning) {
        let presentedViewController = context.viewControllerForKey(UITransitionContextToViewControllerKey)
        let presentedView = presentedViewController?.view
        let containerView = context.containerView()
        
        // unwrap
        if let viewController = presentedViewController, let presented = presentedView {
            // start the view at the center of container view
            presented.frame = context.finalFrameForViewController(viewController)
            
            // add the view to the container view
            containerView.addSubview(presented)
            
            // begin at 1% scale
            presented.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.01, 0.01)
            
            // animate for 100% scale
            UIView.animateWithDuration(self.transitionDuration(context),
                delay: 0.0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0.5,
                options: nil,
                animations: { () -> Void in
                    // animate to 100% scale
                    presented.transform = CGAffineTransformIdentity
                    
                }, completion: { (finished: Bool) -> Void in
                    // notify the system that the transition is complete
                    context.completeTransition(finished)
            })
        }
    }
    
    func animateDismissalWithTransitionContext(context: UIViewControllerContextTransitioning) {
        let presentedView = context.viewForKey(UITransitionContextFromViewKey)
        
        // unwrap
        if let presented = presentedView {
            // fade out
            UIView.animateWithDuration(self.transitionDuration(context) * 0.5, // fade out a litte faster than the dimming view
                delay: 0.0,
                options: UIViewAnimationOptions.CurveLinear,
                animations: { () -> Void in
                    // fade out
                    presented.alpha = 0.0;
                    
                }, completion: { (finished: Bool) -> Void in
                    // notify the system that the transition is complete
                    context.completeTransition(finished)
            })
        }
    }

}
