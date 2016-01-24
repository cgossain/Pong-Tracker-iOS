//
//  TransientPresentationController.swift
//  Pong-Tracker
//
//  Created by Christian Gossain on 2015-06-27.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class TransientPresentationController: UIPresentationController {
    
    let dimmingView: UIView
    
    override init(presentedViewController: UIViewController, presentingViewController: UIViewController) {
        dimmingView = UIView()
        dimmingView.backgroundColor = UIColor.blackColor()
        super.init(presentedViewController: presentedViewController, presentingViewController: presentingViewController)
    }
    
    // MARK: Presentation
    
    override func presentationTransitionWillBegin() {
        self.dimmingView.frame = self.containerView!.bounds;
        self.dimmingView.alpha = 0.0;
        
        self.containerView!.addSubview(self.dimmingView)
        self.containerView!.addSubview(self.presentedView()!)
        
        // fade in the dimming view
        self.presentingViewController.transitionCoordinator()?.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.dimmingView.alpha = 0.5;
        }, completion: nil)
    }
    
    override func presentationTransitionDidEnd(completed: Bool) {
        if !completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    // MARK: Dismissal
    
    override func dismissalTransitionWillBegin() {
        // fade in the dimming view
        self.presentingViewController.transitionCoordinator()?.animateAlongsideTransition({ (context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.dimmingView.alpha = 0.5;
            }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(completed: Bool) {
        if completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    // MARK: Size
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        // width and height
        let width = 600.0
        let height = 600.0
        
        // origin
        let x = (Double(self.containerView!.bounds.size.width) - width) / 2.0
        let y = (Double(self.containerView!.bounds.size.height) - height) / 2.0
        
        // return the frame
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
