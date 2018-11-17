//
//  TabBarViewController.swift
//  AD_App
//
//  Created by Chun-kit Ho on 17/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import KeychainSwift

class TabBarViewController: UITabBarController {

    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let statusBarView = UIView(frame: UIApplication.shared.statusBarFrame)
        let statusBarColor = UIColor(red: 0/255, green: 51/255, blue: 160/255, alpha: 1.0)
        statusBarView.backgroundColor = statusBarColor
        view.addSubview(statusBarView)
    }
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
        //return UIStatusBarStyle.default   // Make dark again
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
