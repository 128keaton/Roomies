//
//  EntityManager.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/5/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class EntityManager {
    // App User Properties
    private (set) public var currentUser: AppUser?
    private var currentFIRUser: User?
    private let userPath = "users"
    private (set) public var authState: UserAuthState = .unauthorized

    // Delegates
    var userDelegate: UserManagerDelegate? = nil
    var currentApartmentDelegate: CurrentApartmentManagerDelegate? = nil
    var apartmentListDelegate: ApartmentListManagerDelegate? = nil
    var billManagerDelegate: BillListManagerDelegate? = nil

    // Misc. Properties
    private var userDefaults = UserDefaults.standard

    // MARK: Initialization

    init(firUser: User) {
        self.currentFIRUser = firUser
    }

    public func getCurrentUser(completion: @escaping (AppUser?) -> Void) {
        self.findUser(userID: (self.currentFIRUser?.uid)!, email: (self.currentFIRUser?.email)!, returnedUser: { (user) in
                if(user == nil) {
                    self.authState = .unauthorized
                    self.currentUser = nil
                    self.userDelegate?.userAuthorizationExpired()
                    completion(self.currentUser)
                } else {
                    self.authState = .authorized
                    self.currentUser = user!
                    self.userDelegate?.userHasBeenAuthenticated()
                    completion(self.currentUser)
                }
            })
    }

    public func findObjectByID<T : Decodable>(id: String, collectionPath: String, expectedType: T.Type, returnedData: @escaping(T?) -> Void) {
        Firestore.firestore().collection(collectionPath).document(id).getDocument { returnedDocument, error in
            guard let document = returnedDocument
                else{
                    // Delete document
                    returnedData(nil)
            }
            guard let entityData = document.data()
                else{
                    // Delete document
                    returnedData(nil)
            }
            
            returnedData(try! FirebaseDecoder().decode(expectedType.self, from: entityData))
        }
    }

    // Finds the user in the 'users' table by FIRUser uid
    public func findUser(userID: String, email: String, returnedUser: @escaping (AppUser?) -> Void) {
        self.findObjectByID(id: userID, collectionPath: "users", expectedType: AppUser.self) { (appUser) in
            if let user = appUser{
                returnedUser(user)
            }else{
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


    public func bulkUpdateEntityData(modificationType: DataModificationType, data: [String], entity: ObjectModel, keys: [String]) {
        var entityData = try! FirestoreEncoder().encode(entity)
        var entityKey = ""
        var entityID = ""

        if(type(of: entity) == Apartment.self) {
            entityKey = (entity as! Apartment).databaseKey
            entityID = (entity as! Apartment).apartmentID
        }

        var index = 0
        for key in keys {
            var exclusiveData = entityData[key] as! [String]

            switch modificationType {
            case .remove:
                exclusiveData = exclusiveData.filter { $0 != data[index] }
                break
            case .add:
                if(!exclusiveData.contains(data[index])) {
                    exclusiveData.append(data[index])
                }
                break
            case .update:
                exclusiveData = exclusiveData.filter { $0 != data[index] }
                exclusiveData.append(data[index])
                break
            }

            index += 1
            entityData[key] = exclusiveData
        }
        Firestore.firestore().collection(entityKey).document(entityID).updateData(entityData)
    }

    func getEntityModelFromData<T : Decodable>(_ data: [String: Any], expectedType: T.Type) -> T? {
        let returnedEntity = try! FirestoreDecoder().decode(expectedType.self, from: data)
        return returnedEntity
    }


}

// MARK: Data enum

enum DataModificationType {
    case remove
    case update
    case add
}


// MARK: Delegates

// Delegate protocol for controllers that need to know authentication status
protocol UserManagerDelegate {
    func userHasBeenAuthenticated()
    func userAuthorizationExpired()
}

// Delegate protocol for the apartment list
protocol ApartmentListManagerDelegate {
    func apartmentRemoved(removedApartment: Apartment)
    func apartmentAdded(addedApartment: Apartment)
    func apartmentChanged(changedApartment: Apartment)
}

// Delegate protocol for the currently selected apartment
protocol CurrentApartmentManagerDelegate {
    func currentApartmentRemoved(removedApartment: Apartment)
    func currentApartmentChanged(newApartment: Apartment)
    func currentApartmentUpdated(updatedApartment: Apartment)
}

// Delegate protocol for bills
protocol BillListManagerDelegate {
    func billRemoved(removedBill: Bill)
    func billAdded(addedBill: Bill)
    func billChanged(changedBill: Bill)
}
