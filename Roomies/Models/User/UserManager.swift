//
//  UserManager.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import Firebase

class UserManager {
    private (set) public var currentUser: User?

    // TODO: use a completion block here
    func signInUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, authError) in
            guard let result = authResult
                else {
                    print("authResult is nil")
                    return
            }
            print(result)
            if (authError != nil) {
                print(authError!)
            }
        }
    }
    
    // Registers a a user with email, password and full name
    func registerUser(email: String, password: String, fullName: String) {

    }

}
