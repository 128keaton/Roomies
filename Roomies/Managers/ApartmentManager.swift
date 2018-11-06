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
import CoreLocation

class ApartmentManager {
    var currentUser: AppUser? = nil
    var currentUserID = ""
    var delegate: ApartmentManagerDelegate? = nil
    var currentApartmentDelegate: CurrentApartmentManagerDelegate? = nil

    private var userManager: UserManager? = nil

    let defaults = UserDefaults.standard

    init(withUserManager: UserManager) {
        self.userManager = withUserManager
        self.currentUserID = (self.userManager?.currentUser?.userID)!
        self.currentUser = self.userManager?.currentUser
    }

    func checkIfUserInRangeOfApartments(userID: String, userLocation: CLLocation) {
        Firestore.firestore().collection("apartments").whereField("userIDs", arrayContains: self.currentUserID).getDocuments { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }
            for document in snapshot.documents {
                let apartment = try! FirebaseDecoder().decode(Apartment.self, from: document.data())
                let apartmentLocation = CLLocation(latitude: apartment.apartmentLatitude, longitude: apartment.apartmentLongitude)
                if(userLocation.distance(from: apartmentLocation) <= 10) {
                    self.updateApartmentData(modificationType: .add, data: userID, apartment: apartment, key: "usersInRange")
                } else if(apartment.usersInRange.contains(userID)) {
                    self.updateApartmentData(modificationType: .remove, data: userID, apartment: apartment, key: "usersInRange")
                }
            }
        }
    }

    func startWatchingApartments() {
        Firestore.firestore().collection("apartments").whereField("userIDs", arrayContains: self.currentUserID).addSnapshotListener { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            snapshot.documentChanges.forEach { diff in
                do {
                    let apartmentItem = try FirebaseDecoder().decode(Apartment.self, from: diff.document.data())
                    if (diff.type == .added) {
                        self.delegate?.apartmentAdded(addedApartment: apartmentItem)
                        self.userManager?.updateUserData(modificationType: .add, data: apartmentItem.apartmentID, userID: self.currentUserID, key: "apartments")
                    }
                    
                    if (diff.type == .modified) {
                        self.delegate?.apartmentChanged(changedApartment: apartmentItem)
                        self.userManager?.updateUserData(modificationType: .update, data: apartmentItem.apartmentID, userID: self.currentUserID, key: "apartments")
                    }
                    
                    if (diff.type == .removed) {
                        self.delegate?.apartmentRemoved(removedApartment: apartmentItem)
                        self.userManager?.updateUserData(modificationType: .remove, data: apartmentItem.apartmentID, userID: self.currentUserID, key: "apartments")
                    }
                } catch {
                    self.deleteRawApartment(apartmentID: diff.document["apartmentID"] as? String ?? diff.document["uuid"] as! String)
                }
            }
        }
    }

    public func startWatchingApartment(apartmentID: String) {
        Firestore.firestore().collection("apartments").whereField("apartmentID", isEqualTo: apartmentID).addSnapshotListener { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            snapshot.documentChanges.forEach { diff in
                do {
                    let apartmentItem = try FirebaseDecoder().decode(Apartment.self, from: diff.document.data())
                    if (diff.type == .modified) {
                        self.currentApartmentDelegate?.currentApartmentUpdated(updatedApartment: apartmentItem)
                    }
                    if (diff.type == .removed) {
                        self.currentApartmentDelegate?.currentApartmentRemoved(removedApartment: apartmentItem)
                        self.userManager?.updateUserData(modificationType: .remove, data: apartmentItem.apartmentID, userID: self.currentUserID, key: "apartments")
                    }
                } catch {
                    self.deleteRawApartment(apartmentID: diff.document["apartmentID"] as? String ?? diff.document["uuid"] as! String)
                }
            }
        }
    }


    func addApartmentToUsers(apartment: Apartment, completion: @escaping (Bool) -> Void) {
        if(self.currentUser != nil && !(self.currentUser?.apartments.contains(apartment.apartmentID))!) {
            self.currentUser?.apartments.append(apartment.apartmentID)
        }

        for user in apartment.userIDs {
            self.userManager?.updateUserData(modificationType: .add, data: apartment.apartmentID, userID: user, key: "apartments")
      //      self.updateApartmentData(modificationType: .add, data: user, apartment: apartment, key: "userIDs")
        }
        completion(true)
    }

    func removeApartmentFromUser(apartment: Apartment, user: AppUser) {
        self.removeApartmentFromUser(apartment: apartment, userID: user.userID, fullName: user.fullName) { (didRemove) in
            print("Was able to remove \(user) from \(apartment): \(didRemove)")
        }
    }

    func removeApartmentFromUser(apartment: Apartment, userID: String, fullName: String, completion: @escaping (Bool) -> Void) {
        bulkUpdateApartmentData(modificationType: .remove, data: [userID, fullName], apartment: apartment, keys: ["userIDs", "userNames"])
        self.userManager?.updateUserData(modificationType: .remove, data: apartment.apartmentID, userID: userID, key: "apartments")
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
        for user in apartment.userIDs {
            self.userManager?.updateUserData(modificationType: .remove, data: apartment.apartmentID, userID: user, key: "apartments")
            Firestore.firestore().collection("apartments").document(apartment.apartmentID).delete()
        }
    }


    private func deleteRawApartment(apartmentID: String) {
        Firestore.firestore().collection("apartments").document(apartmentID).delete()
    }

    public func bulkUpdateApartmentData(modificationType: DataModificationType, data: [String], apartment: Apartment, keys: [String]) {
        var apartmentData = try! FirestoreEncoder().encode(apartment)
        let apartmentID = apartment.apartmentID
        var index = 0

        for key in keys {
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

    public func updateApartmentData(modificationType: DataModificationType, data: [String: [String: Any]], apartment: Apartment, key: String, id: String) {

        var apartmentData = try! FirestoreEncoder().encode(apartment)
        let apartmentID = apartment.apartmentID
        var exclusiveData = apartmentData[key] as! [String: [String: Any]]

        switch modificationType {
        case .remove:
            exclusiveData = exclusiveData.filter { $0.key != id }
            break
        case .add:
            if(!exclusiveData.keys.contains(id)) {
                exclusiveData[id] = data[id]
            }
            break
        case .update:
            exclusiveData = exclusiveData.filter { $0.key != id }
            exclusiveData[key] = data[key]
            break
        }

        apartmentData[key] = exclusiveData
        Firestore.firestore().collection("apartments").document(apartmentID).updateData(apartmentData)
    }

    public func getApartmentForID(apartmentID: String, completion: @escaping (Apartment) -> Void) {
        Firestore.firestore().collection("apartments").document(apartmentID).getDocument { (document, error) in
            if(error != nil) {
                print(error!.localizedDescription)
            }

            if(document?.data() != nil) {
                completion(try! FirestoreDecoder().decode(Apartment.self, from: document!.data()!))
            }
        }
    }

}

protocol ApartmentManagerDelegate {
    func apartmentRemoved(removedApartment: Apartment)
    func apartmentAdded(addedApartment: Apartment)
    func apartmentChanged(changedApartment: Apartment)
}

protocol CurrentApartmentManagerDelegate {
    func currentApartmentRemoved(removedApartment: Apartment)
    func currentApartmentUpdated(updatedApartment: Apartment)
}
