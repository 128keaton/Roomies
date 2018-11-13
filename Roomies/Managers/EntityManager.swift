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
        super.init()
        self.findUser(userID: firUser.uid, email: firUser.email!) { (user) in
            self.currentUser = user
            if let currentApartmentID = self.userDefaults.string(forKey: "selectedApartmentID") {
                self.findObjectByID(id: currentApartmentID, collectionPath: "apartments", expectedType: Apartment.self) { (returnedData) in
                    if let apartment = returnedData {
                        self.currentApartment = apartment
                        self.currentApartmentDelegate?.currentApartmentChanged(newApartment: apartment)
                    } else {
                        self.currentApartmentDelegate?.noApartmentFound()
                    }
                }
            }
            NotificationCenter.default.post(name: Notification.Name("currentUserSet"), object: nil)
        }
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
                let entityData = try! FirebaseEncoder().encode(apartment) as! [String: Any]
                let apartmentLocation = CLLocation(latitude: apartment.apartmentLatitude, longitude: apartment.apartmentLongitude)

                if(location.distance(from: apartmentLocation) <= 10) {
                    self.bulkUpdateEntityData(modificationType: .added, data: [userID], entityData: entityData, keys: ["usersInRange"])
                } else if(apartment.usersInRange.contains(userID)) {
                    self.bulkUpdateEntityData(modificationType: .removed, data: [userID], entityData: entityData, keys: ["usersInRange"])
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
                self.currentUser = nil
                self.userDelegate?.userAuthorizationExpired()
                completion(self.currentUser)
            } else {
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

            print(entityData)
            
            returnedData(try! FirebaseDecoder().decode(expectedType.self, from: entityData))
        }
    }

    public func persistEntity<T>(_ entity: T) {
        var entityData = [String:Any]()
        
        if(type(of: entity) == Apartment.self){
            entityData = try! FirebaseEncoder().encode(entity as! Apartment) as! [String : Any]
        }
        
        bulkUpdateEntityData(modificationType: .added, data: [], entityData: entityData, keys: [])
    }
    
    public func persistEntity(_ entityData: [String: Any]) {
        bulkUpdateEntityData(modificationType: .added, data: [], entityData: entityData, keys: [])
    }

    public func deleteEntityFromApartment(entityData: [String: Any], collectionKey: String) {
        let entityID = guessEntityID(entityData)
        let entityKey = guessEntityKey(entityData)

        guard let apartmentData = try! FirebaseEncoder().encode(currentApartment) as? [String: Any]
            else {
                return
        }

        bulkUpdateEntityData(modificationType: .removed, data: [entityID], entityData: apartmentData, keys: [collectionKey])
        Firestore.firestore().collection(entityKey).document(entityID).delete()
    }

    public func deleteApartment(_ apartment: Apartment) {
        getUsersForApartment(apartment: apartment) { (users) in
            for user in users {
                let entityData = try! FirestoreEncoder().encode(user) as [String: Any]
                self.bulkUpdateEntityData(modificationType: .removed, data: [apartment.apartmentID], entityData: entityData, keys: ["apartments"])
            }
        }
        Firestore.firestore().collection("apartments").document(apartment.apartmentID).delete()
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
        let entityData = try! FirebaseEncoder().encode(user) as! [String: Any]
        bulkUpdateEntityData(modificationType: .added, data: [], entityData: entityData, keys: [])
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

    func getUsersForApartment(apartment: Apartment, completion: @escaping([AppUser]) -> Void) {
        Firestore.firestore().collection("users").whereField("apartmentIDs", arrayContains: apartment.apartmentID).getDocuments { (snapshot, error) in
            var returnedUsers: [AppUser] = []
            guard let documents = snapshot?.documents
                else {
                    return completion(returnedUsers)
            }
            for document in documents {
                let user = try! FirebaseDecoder().decode(AppUser.self, from: document.data())
                returnedUsers.append(user)
            }
            completion(returnedUsers)
        }
    }

    func addApartmentToUsers(apartment: Apartment, completion: @escaping (Bool) -> Void) {
        if(self.currentUser != nil && !(self.currentUser?.apartments.contains(apartment.apartmentID))!) {
            self.currentUser?.apartments.append(apartment.apartmentID)
        }

        let entityData = try! FirebaseEncoder().encode(apartment) as! [String: Any]
        bulkUpdateEntityData(modificationType: .added, data: apartment.userIDs, entityData: entityData, keys: ["userIDs"])
        bulkUpdateEntityData(modificationType: .added, data: apartment.userNames, entityData: entityData, keys: ["userNames"])

        completion(true)
    }

    private func guessEntityKey(_ entityData: [String: Any]) -> String {
        var key = String()
        if let potentialKey = entityData["databaseKey"] as? String {
            key = potentialKey
        }

        return key
    }

    private func guessEntityID(_ entityData: [String: Any]) -> String {
        print(Array(entityData.keys))
        // FIXME
        for key in Array(entityData.keys) {
            if(key == "apartmentID" || key == "userID" || key == "groceryItemID" || key == "billID"){
                return entityData[key] as! String
            }
        }
        // FUCK
        return UUID().uuidString.lowercased()
    }

    public func bulkUpdateEntityData(modificationType: DocumentChangeType, data: [String], entityData: [String: Any], keys: [String]) {
        var index = 0
        var copiedData = entityData

        let entityKey = guessEntityKey(entityData)
        let entityID = guessEntityID(entityData)

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
            copiedData[key] = exclusiveData
        }
        let documentRef = Firestore.firestore().collection(entityKey).document(entityID)

        documentRef.getDocument { (documentSnapshot, error) in
            if let document = documentSnapshot, document.exists {
                document.setValuesForKeys(copiedData)
            } else {
                Firestore.firestore().collection(entityKey).document(entityID).setData(entityData)
            }
        }
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
            let apartmentData = self.getCurrentApartmentData()
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
                self.bulkUpdateEntityData(modificationType: diff.type, data: [groceryItem.groceryItemID], entityData: apartmentData, keys: ["groceryIDs"])
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

            let userData = self.getCurrentUserData()
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
                    self.bulkUpdateEntityData(modificationType: diff.type, data: [apartment.apartmentID], entityData: userData, keys: ["apartments"])
                } catch {
                    //  self.deleteRawApartment(apartmentID: diff.document["apartmentID"] as? String ?? diff.document["uuid"] as! String)
                }

            }
        }
    }

    public func getCurrentApartmentData() -> [String: Any] {
        var apartmentData = [String: Any]()

        if let apartment = currentApartment {
            apartmentData = try! FirebaseEncoder().encode(apartment) as! [String: Any]
        }
        return apartmentData
    }

    public func getCurrentUserData() -> [String: Any] {
        var userData = [String: Any]()

        if let user = currentUser {
            userData = try! FirebaseEncoder().encode(user) as! [String: Any]
        }
        return userData
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
    func noApartmentFound()
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

