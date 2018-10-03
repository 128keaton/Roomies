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

class LoginViewController: UIViewController{
    @IBOutlet weak var emailField: UITextField?
    @IBOutlet weak var passwordField: UITextField?
    
    @IBAction func loginButtonPressed(){
        if(validateFields()){
            Auth.auth().signIn(withEmail: (emailField?.text)!, password: (passwordField?.text)!) { (authResult, authError) in
                guard let result = authResult
                    else{
                        print("authResult is nil")
                        return
                }
                print(result)
                
                if (authError != nil){
                    print(authError!)
                    return
                }
                self.displayAlert(message: "Successfully authenticated", title: "Success")
            }
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
