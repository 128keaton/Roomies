//
//  UserManager.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class UserManager {
    private (set) public var currentUser: AppUser?
    private var currentFIRUser: User?
    private let userPath = "users"

    // TODO: use a completion block here
    func signInUser(email: String, password: String, authReturned: @escaping (AppUser?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, authError) in
            // If you didn't get a result, you're el fucko'd
            guard let result = authResult
                else {
                    self.currentFIRUser = nil
                    self.currentUser = nil
                    print("authResult is nil")
                    authReturned(nil)
                    return
            }
            print(result)

            // If you got an auth error, fucking ditto muh guy
            if (authError != nil) {
                authReturned(nil)
                self.currentFIRUser = nil
                self.currentUser = nil
                print(authError!)
            }

            // Finds the FIRUser and then either finds or creates a user in the 'users' table
            self.currentFIRUser = authResult?.user
            self.findUser(userID: self.currentFIRUser!.uid, email: email, returnedUser: { (appUser) in
                if(appUser != nil) {
                    authReturned(appUser)
                } else {
                    authReturned(nil)
                }
            })
        }
    }

    // Registers a a user with email, password and full name
    func registerUser(email: String, password: String, fullName: String) {

    }

    private func findUser(userID: String, email: String, returnedUser: @escaping (AppUser?) -> Void) {
        Firestore.firestore().collection(userPath).document(userID).getDocument { document, error in
            if document != nil && document?.data() != nil {
                let user = try! FirestoreDecoder().decode(AppUser.self, from: document!.data()!)
                returnedUser(user)
            } else {
                self.createUserOnBackend(fullName: nil, email: email, userID: userID, completion: { (success) in
                    if(success) {
                        self.findUser(userID: userID, email: email, returnedUser: { (user) in
                            returnedUser(user)
                        })
                    } else {
                        returnedUser(nil)
                    }
                })
            }
        }
    }

    func createUserOnBackend(fullName: String?, email: String, userID: String, completion: @escaping (Bool) -> Void) {
        let transientUser = AppUser(emailAddress: email, fullName: fullName)
        transientUser.userID = userID
        let encodedUser = try! FirestoreEncoder().encode(transientUser)
        Firestore.firestore().collection(userPath).document(userID).setData(encodedUser) { (error) in
            if(error != nil) {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
}
