//
//  BaseViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class BaseViewController: UITabBarController{
    override func viewDidAppear(_ animated: Bool) {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if(user == nil){
                  self.performSegue(withIdentifier: "showLogin", sender: self)
            }
        }
    
    }
}
