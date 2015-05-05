//
//  RootViewController.swift
//  Pong-Tracker
//
//  Created by Christian R. Gossain on 2015-05-03.
//  Copyright (c) 2015 Christian R. Gossain. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var firstTeamViewController: UIView!
    @IBOutlet weak var secondTeamViewController: UIView!
    @IBOutlet weak var controlPadViewController: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Methods (Private)
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
