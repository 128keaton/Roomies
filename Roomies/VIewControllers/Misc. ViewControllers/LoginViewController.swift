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

class LoginViewController: UIViewController {
    @IBOutlet weak var emailField: UITextField?
    @IBOutlet weak var passwordField: UITextField?

    var entityManager = (UIApplication.shared.delegate as! AppDelegate).entityManager!

    @IBAction func loginButtonPressed() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if(validateFields()) {
            DispatchQueue.main.async {
                Auth.auth().signIn(withEmail: (self.emailField?.text)!, password: (self.passwordField?.text)!, completion: { (authResult, error) in
                    MBProgressHUD.hide(for: self.view, animated: true)
                    if let error = error {
                        self.displayAlert(message: error.localizedDescription, title: "Error")
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }

        }
    }

    func validateFields() -> Bool {
        if(emailField?.text == "") {
            displayAlert(message: "Email cannot be blank", title: "Error")
            return false
        }

        if (passwordField?.text == "") {
            displayAlert(message: "Password cannot be blank", title: "Error")
            return false
        }
        return true
    }

    func displayAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }
}
