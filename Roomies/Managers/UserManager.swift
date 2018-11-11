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
    private (set) public var authState: UserAuthState = .unauthorized

    var delegate: UserManagerDelegate? = nil

    init() {

    }

    init(firUser: User) {
        self.currentFIRUser = firUser
    }
    
    func getCurrentUser(completion: @escaping (AppUser) -> Void){
        self.findUser(userID: (self.currentFIRUser?.uid)!, email: (self.currentFIRUser?.email)!, returnedUser: { (user) in
            if(user == nil) {
                self.authState = .unauthorized
                print("User has been unauthenticated??")
            } else {
                self.authState = .authorized
                self.currentUser = user!
                self.delegate?.userHasBeenAuthenticated()
                completion(self.currentUser!)
            }
        })
    }

    public func recheckAuth() {
        if(self.authState == .authorized && self.currentUser != nil) {
            self.delegate?.userHasBeenAuthenticated()
        }
    }

    // TODO: use a completion block here
    func signInUser(email: String, password: String, authReturned: @escaping (AppUser?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, authError) in
            self.handleUserAuthResult(email: email, authResult: authResult, authError: authError, authReturned: { (user) in
                authReturned(user)
            })
        }
    }

    // Registers a a user with email, password and full name
    func registerUser(email: String, password: String, fullName: String, authReturned: @escaping (AppUser?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, authError) in
            self.handleUserAuthResult(email: email, authResult: authResult, authError: authError, authReturned: { (user) in
                authReturned(user)
            })
        }
    }


    // Handles the authorization result callback
    private func handleUserAuthResult(email: String, authResult: AuthDataResult?, authError: Error?, authReturned: @escaping (AppUser?) -> Void) {
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
                self.authState = .authorized
                authReturned(appUser)
            } else {
                authReturned(nil)
            }
        })
    }

    // Username lookup from userID
    public func getUserNameFor(userID: String, returnedUserName: @escaping (String?) -> Void) {
        Firestore.firestore().collection(userPath).document(userID).getDocument { document, error in
            if document != nil && document?.data() != nil {
                let user = try! FirestoreDecoder().decode(AppUser.self, from: document!.data()!)
                returnedUserName(user.fullName)
            }
        }
    }

    // Finds the user in the 'users' table by FIRUser uid
    public func findUser(userID: String, email: String, returnedUser: @escaping (AppUser?) -> Void) {
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

    public func findUserByID(userID: String, returnedUser: @escaping (AppUser?) -> Void) {
        Firestore.firestore().collection(userPath).document(userID).getDocument { document, error in
            if document != nil && document?.data() != nil {
                let user = try! FirestoreDecoder().decode(AppUser.self, from: document!.data()!)
                returnedUser(user)
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

    public func updateUserData(modificationType: DataModificationType, data: String, userID: String, key: String) {
        findUserByID(userID: userID) { (user) in
            if(user != nil) {
                self.updateUserData(modificationType: modificationType, data: data, user: user, key: key)
            } else {
                print("Unable to update user (\(user!)) data: \(data)")
            }
        }
    }

    public func updateUserData(modificationType: DataModificationType, data: String, user: AppUser?, key: String) {
        let userToModify = self.determineUserObject(user: user)
        var userData = try! FirestoreEncoder().encode(userToModify)
        let userID = userToModify.userID

        var exclusiveData = userData[key] as! [String]

        switch modificationType {
        case .remove:
            exclusiveData = exclusiveData.filter { $0 != data }
            break
        case .add:
            if(!exclusiveData.contains(data)) {
                exclusiveData.append(data)
            }
            break
        case .update:
            exclusiveData = exclusiveData.filter { $0 != data }
            exclusiveData.append(data)
            break
        }

        userData[key] = exclusiveData

        Firestore.firestore().collection("users").document(userID).updateData(userData)
    }

    private func determineUserObject(user: AppUser?) -> AppUser {
        var userToModify = self.currentUser
        if(user != nil) {
            userToModify = user
        }
        return userToModify!
    }
}

