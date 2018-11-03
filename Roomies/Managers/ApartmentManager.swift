//
//  ApartmentManager.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class ApartmentManager {
    var currentUser: AppUser? = nil
    var delegate: ApartmentManagerDelegate? = nil
    
    private var userManager: UserManager? = nil
    private var expectedApartmentCount = 0
    private var didFetchApartments = false {
        didSet {
            delegate?.apartmentsRetrieved()
        }
    }
    
    private var fetchedApartments: [Apartment] = [] {
        didSet {
            if fetchedApartments.count == expectedApartmentCount {
                didFetchApartments = true
            }
        }
    }

    init() {
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        currentUser = userManager!.currentUser
    }

    func accessStoredApartments(exclude: Bool = true) -> [Apartment] {
        let userDefaults = UserDefaults.standard
        let currentApartmentID = userDefaults.string(forKey: "selectedApartmentID")

        if(exclude && currentApartmentID != nil) {
            return fetchedApartments.filter { $0.apartmentID != currentApartmentID! }
        }
        return fetchedApartments
    }

    func fetchApartments() {
        let currentUser = userManager?.currentUser!
        expectedApartmentCount = (currentUser?.apartments.count)! - 1

        for apartmentID in (currentUser?.apartments)! {
            Firestore.firestore().collection("apartments").document(apartmentID).getDocument { (document, error) in
                if(error != nil) {
                    print(error!.localizedDescription)
                }
                if(document?.data() == nil) {
                    self.expectedApartmentCount -= 1
                    self.userManager?.updateUserData(modificationType: .remove, data: apartmentID, user: nil, key: "apartments")
                } else if(self.expectedApartmentCount != 0){
                    let apartment = try! FirestoreDecoder().decode(Apartment.self, from: document!.data()!)
                    self.fetchedApartments.append(apartment)
                }else{
                    self.fetchedApartments = []
                }
            }
        }
    }

    func addApartmentToUsers(apartment: Apartment, completion: @escaping (Bool) -> Void) {
        if(self.currentUser != nil && !(self.currentUser?.apartments.contains(apartment.apartmentID))!){
            self.currentUser?.apartments.append(apartment.apartmentID)
        }
        
        for user in apartment.users {
            self.userManager?.updateUserData(modificationType: .add, data: apartment.apartmentID, firebaseID: user, key: "apartments")
            self.updateApartmentData(modificationType: .add, data: user, apartment: apartment, key: "users")
        }
        completion(true)
    }

    func removeApartmentFromUser(apartment: Apartment, user: AppUser){
        self.removeApartmentFromUser(apartment: apartment, userID: user.userID, fullName: user.fullName) { (didRemove) in
            print("Was able to remove \(user) from \(apartment): \(didRemove)")
        }
    }
    
    func removeApartmentFromUser(apartment: Apartment, userID: String, fullName: String, completion: @escaping (Bool) -> Void) {        
        bulkUpdateApartmentData(modificationType: .remove, data: [userID, fullName], apartment: apartment, keys: ["users", "userNames"])
        self.userManager?.updateUserData(modificationType: .remove, data: apartment.apartmentID, firebaseID: userID, key: "apartments")
        completion(true)
    }

    func persistApartment(apartment: Apartment) {
        let apartmentData = try! FirestoreEncoder().encode(apartment)
        Firestore.firestore().collection("apartments").document(apartment.apartmentID).setData(apartmentData) { (error) in
            if(error != nil) {
                print(error!.localizedDescription)
            }

            self.addApartmentToUsers(apartment: apartment, completion: { (didAddApartment) in
                if(didAddApartment) {
                    print("Apartment added to users")
                } else {
                    print("Unable to add apartment to users")
                }
            })
        }

    }

    func deleteApartment(apartment: Apartment) {
        for user in apartment.users {
            self.userManager?.updateUserData(modificationType: .remove, data: apartment.apartmentID, firebaseID: user, key: "apartments")
            Firestore.firestore().collection("apartments").document(apartment.apartmentID).delete()
        }
    }

    public func bulkUpdateApartmentData(modificationType: DataModificationType, data: [String], apartment: Apartment, keys: [String]){
        var apartmentData = try! FirestoreEncoder().encode(apartment)
        let apartmentID = apartment.apartmentID
        var index = 0
        
        for key in keys{
            var exclusiveData = apartmentData[key] as! [String]
            
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
            apartmentData[key] = exclusiveData
        }
        
        Firestore.firestore().collection("apartments").document(apartmentID).updateData(apartmentData)
    }
    
    public func updateApartmentData(modificationType: DataModificationType, data: String, apartment: Apartment, key: String) {
        self.bulkUpdateApartmentData(modificationType: modificationType, data: [data], apartment: apartment, keys: [key])
    }
}

protocol ApartmentManagerDelegate {
    func apartmentsRetrieved()
}
