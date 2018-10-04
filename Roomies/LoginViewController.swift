//
//  LoginViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import MBProgressHUD

class LoginViewController: UIViewController{
    @IBOutlet weak var emailField: UITextField?
    @IBOutlet weak var passwordField: UITextField?
    
    var userManager: UserManager? = nil
    
    override func viewDidLoad() {
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
    }
    
    @IBAction func loginButtonPressed(){
        
        if(validateFields()){
            userManager?.signInUser(email: (emailField?.text)!, password: (passwordField?.text)!, authReturned: { (user) in
                if(user == nil){
                    self.displayAlert(message: "Incorrect username or password", title: "Error")
                }
            })
        }
    }
    
    func validateFields() -> Bool{
        if(emailField?.text == ""){
            displayAlert(message: "Email cannot be blank", title: "Error")
            return false
        }
        
        if (passwordField?.text == ""){
            displayAlert(message: "Password cannot be blank", title: "Error")
            return false
        }
        return true
    }
    
    func displayAlert(message: String, title: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }
}
