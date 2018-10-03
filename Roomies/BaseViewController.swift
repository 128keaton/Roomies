//
//  BaseViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class BaseViewController: UITabBarController{
    override func viewDidAppear(_ animated: Bool) {
        let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        if(userManager.currentUser == nil){
            self.performSegue(withIdentifier: "showLogin", sender: self)
        }
    }
}
