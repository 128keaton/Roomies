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
import CoreLocation

class EntityManager: NSObject {
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
    var groceryManagerDelegate: GroceryManagerDelegate? = nil

    // Misc. Properties
    private var userDefaults = UserDefaults.standard
    public var lastUserLocation: CLLocation? = nil
    private (set) public var currentApartment: Apartment? = nil

    // Listeners
    private var groceriesListener: ListenerRegistration? = nil

    // MARK: Initialization

    init(firUser: User) {
        self.currentFIRUser = firUser
    }

    // Checks if the user location is in range of any of their apartments
    private func checkIfLocationInRangeOfApartments(location: CLLocation) {
        guard let userID = self.currentUser?.userID
            else {
                return
        }

        Firestore.firestore().collection("apartments").whereField("userIDs", arrayContains: userID).getDocuments { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            for document in snapshot.documents {
                let apartment = try! FirebaseDecoder().decode(Apartment.self, from: document.data())
                let apartmentLocation = CLLocation(latitude: apartment.apartmentLatitude, longitude: apartment.apartmentLongitude)
                if(location.distance(from: apartmentLocation) <= 10) {
                    self.bulkUpdateEntityData(modificationType: .added, data: [userID], entity: apartment, keys: ["usersInRange"])
                } else if(apartment.usersInRange.contains(userID)) {
                    self.bulkUpdateEntityData(modificationType: .removed, data: [userID], entity: apartment, keys: ["usersInRange"])
                }
            }
        }
    }

    // Gets the current user's distance from the current apartment in miles
    public func getDistanceFromCurrentApartment() -> Double? {
        guard let apartment = currentApartment
            else {
                return nil
        }
        guard let userLocation = lastUserLocation
            else {
                return nil
        }

        let apartmentLocation = CLLocation(latitude: apartment.apartmentLatitude, longitude: apartment.apartmentLongitude)
        return Double(round(1000 * apartmentLocation.distance(from: userLocation) * 0.000621371) / 1000)
    }

    // Gets the current user
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
                else {
                    // Delete document
                    return returnedData(nil)
            }
            guard let entityData = document.data()
                else {
                    // Delete document
                    return returnedData(nil)
            }

            returnedData(try! FirebaseDecoder().decode(expectedType.self, from: entityData))
        }
    }

    public func updateEntity<T>(entity: T) {
        var entityKey = ""
        var entityID = ""
        var collectionKey = ""
        var entityData: [String: Any]? = nil

        guard let apartment = currentApartment
            else {
                return
        }

        if(type(of: entity) == GroceryItem.self) {
            let groceryItem = (entity as! GroceryItem)
            entityKey = groceryItem.databaseKey
            entityID = groceryItem.groceryItemID
            collectionKey = "groceries"
            entityData = try! FirebaseEncoder().encode(groceryItem) as! [String: Any]
        }

        guard let updatedEntityData = entityData
            else {
                return
        }

        bulkUpdateEntityData(modificationType: .modified, data: [entityID], entity: apartment, keys: [collectionKey])
        Firestore.firestore().collection(entityKey).document(entityID).updateData(updatedEntityData)
    }

    public func persistEntity(entity: ObjectModel){
        bulkUpdateEntityData(modificationType: .added, data: [], entity: entity, keys: [])
    }
    
    public func deleteEntity<T>(entity: T) {
        var entityKey = ""
        var entityID = ""
        var collectionKey = ""

        guard let apartment = currentApartment
            else {
                return
        }

        if(type(of: entity) == GroceryItem.self) {
            let groceryItem = (entity as! GroceryItem)
            entityKey = groceryItem.databaseKey
            entityID = groceryItem.groceryItemID
            collectionKey = "groceries"
        }

        bulkUpdateEntityData(modificationType: .removed, data: [entityID], entity: apartment, keys: [collectionKey])
        Firestore.firestore().collection(entityKey).document(entityID).delete()
    }

    // Finds the user in the 'users' table by FIRUser uid
    public func findUser(userID: String, email: String, returnedUser: @escaping (AppUser?) -> Void) {
        self.findObjectByID(id: userID, collectionPath: "users", expectedType: AppUser.self) { (appUser) in
            if let user = appUser {
                returnedUser(user)
            }
        }
    }

    public func persistNewUser(user: AppUser, completion: @escaping (AppUser?) -> Void) {
        bulkUpdateEntityData(modificationType: .added, data: [], entity: user, keys: [])
        let handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let returnedAuthUser = user
                else {
                    return completion(nil)
            }
            self.findUser(userID: returnedAuthUser.uid, email: returnedAuthUser.email!, returnedUser: { (newUser) in
                completion(newUser)
            })
        }
        Auth.auth().removeStateDidChangeListener(handle)
    }

    func addApartmentToUsers(apartment: Apartment, completion: @escaping (Bool) -> Void) {
        if(self.currentUser != nil && !(self.currentUser?.apartments.contains(apartment.apartmentID))!) {
            self.currentUser?.apartments.append(apartment.apartmentID)
        }

        bulkUpdateEntityData(modificationType: .added, data: apartment.userIDs, entity: apartment, keys: ["userIDs"])
        bulkUpdateEntityData(modificationType: .added, data: apartment.userNames, entity: apartment, keys: ["userNames"])

        completion(true)
    }


    public func bulkUpdateEntityData(modificationType: DocumentChangeType, data: [String], entity: ObjectModel, keys: [String]) {
        var entityData = try! FirestoreEncoder().encode(entity)
        var entityKey = ""
        var entityID = ""

        if(type(of: entity) == Apartment.self) {
            entityKey = (entity as! Apartment).databaseKey
            entityID = (entity as! Apartment).apartmentID
        } else if (type(of: entity) == User.self) {
            entityKey = (entity as! AppUser).databaseKey
            entityID = (entity as! AppUser).userID
        } else if(type(of: entity) == GroceryItem.self){
            entityKey = (entity as! GroceryItem).databaseKey
            entityID = (entity as! GroceryItem).groceryItemID
        }

        var index = 0
        for key in keys {
            var exclusiveData = entityData[key] as! [String]

            switch modificationType {
            case .removed:
                exclusiveData = exclusiveData.filter { $0 != data[index] }
                break
            case .added:
                if(!exclusiveData.contains(data[index])) {
                    exclusiveData.append(data[index])
                }
                break
            case .modified:
                exclusiveData = exclusiveData.filter { $0 != data[index] }
                exclusiveData.append(data[index])
                break
            }

            index += 1
            entityData[key] = exclusiveData
        }
        Firestore.firestore().collection(entityKey).document(entityID).updateData(entityData)
    }

    private func getEntityModelFromData<T : Decodable>(_ data: [String: Any], expectedType: T.Type) -> T? {
        let returnedEntity = try! FirestoreDecoder().decode(expectedType.self, from: data)
        return returnedEntity
    }

    public func updateCurrentApartment(newApartment: Apartment) {
        userDefaults.set(newApartment.apartmentID, forKey: "selectedApartmentID")
        userDefaults.synchronize()
        currentApartment = newApartment
        self.currentApartmentDelegate?.currentApartmentChanged(newApartment: newApartment)
    }

    // Entity-specific calls
    func startWatchingGroceries() {
        guard let apartment = currentApartment
            else {
                return
        }
        groceriesListener = Firestore.firestore().collection("groceries").whereField("attachedApartmentID", isEqualTo: apartment.apartmentID).addSnapshotListener { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            snapshot.documentChanges.forEach { diff in
                let groceryItem = try! FirebaseDecoder().decode(GroceryItem.self, from: diff.document.data())
                if (diff.type == .added) {
                    self.groceryManagerDelegate?.groceryAdded(addedGrocery: groceryItem)
                }
                if (diff.type == .modified) {
                    self.groceryManagerDelegate?.groceryChanged(changedGrocery: groceryItem)
                }
                if (diff.type == .removed) {
                    self.groceryManagerDelegate?.groceryRemoved(removedGrocery: groceryItem)
                }
                self.bulkUpdateEntityData(modificationType: diff.type, data: [groceryItem.groceryItemID], entity: apartment, keys: ["groceryIDs"])
            }
        }
    }

    func startWatchingApartments() {
        guard let user = currentUser
            else {
                return
        }
        Firestore.firestore().collection("apartments").whereField("userIDs", arrayContains: user.userID).addSnapshotListener { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            snapshot.documentChanges.forEach { diff in
                do {
                    let apartment = try FirebaseDecoder().decode(Apartment.self, from: diff.document.data())
                    if (diff.type == .added) {
                        self.apartmentListDelegate?.apartmentAdded(addedApartment: apartment)
                    }

                    if (diff.type == .modified) {
                        self.apartmentListDelegate?.apartmentChanged(changedApartment: apartment)
                    }

                    if (diff.type == .removed) {
                        self.apartmentListDelegate?.apartmentRemoved(removedApartment: apartment)
                    }
                    self.bulkUpdateEntityData(modificationType: diff.type, data: [apartment.apartmentID], entity: user, keys: ["apartments"])
                } catch {
                    //  self.deleteRawApartment(apartmentID: diff.document["apartmentID"] as? String ?? diff.document["uuid"] as! String)
                }

            }
        }
    }

}

extension EntityManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if(self.currentApartment != nil && self.currentUser != nil) {
                checkIfLocationInRangeOfApartments(location: location)
            }
            lastUserLocation = location
        }
    }
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

// Delegate protocol for groceries
protocol GroceryManagerDelegate {
    func groceryRemoved(removedGrocery: GroceryItem)
    func groceryAdded(addedGrocery: GroceryItem)
    func groceryChanged(changedGrocery: GroceryItem)
}

