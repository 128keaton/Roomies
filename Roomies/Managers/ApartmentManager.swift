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
    var appUser: AppUser? = nil
    private var fetchedApartments: [Apartment] = [] {
        didSet {
            if fetchedApartments.count == expectedApartmentCount {
                didFetchApartments = true
            }
        }
    }

    var delegate: ApartmentManagerDelegate? = nil

    private var userManager: UserManager? = nil

    private var expectedApartmentCount = 0

    private var didFetchApartments = false {
        didSet {
            delegate?.apartmentsRetrieved()
        }
    }

    init() {
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        appUser = userManager!.currentUser
    }

    func accessStoredApartments(exclude: Bool = true) -> [Apartment] {
        let userDefaults = UserDefaults.standard
        let currentApartmentUUID = userDefaults.string(forKey: "selectedApartmentUUID")

        if(exclude && currentApartmentUUID != nil) {
            return fetchedApartments.filter { $0.uuid != UUID(uuidString: currentApartmentUUID!)! }
        }
        return fetchedApartments
    }

    func fetchApartments() {
        let currentUser = userManager?.currentUser!
        expectedApartmentCount = (currentUser?.apartments.count)!

        for uuid in (currentUser?.apartments)! {
            Firestore.firestore().collection("apartments").document(uuid.uuidString).getDocument { (document, error) in
                if(error != nil) {
                    print(error!.localizedDescription)
                }
                if(document?.data() == nil) {
                    self.expectedApartmentCount -= 1
                    self.userManager?.removeApartmentFromUser(apartment: nil, user: currentUser, uuid: uuid)
                } else {
                    let apartment = try! FirestoreDecoder().decode(Apartment.self, from: document!.data()!)
                    self.fetchedApartments.append(apartment)
                }
            }
        }
    }

    func addApartmentToUsers(apartment: Apartment, completion: @escaping (Bool) -> Void) {
        Firestore.firestore().collection("apartments").document(apartment.uuid.uuidString).updateData(["users": apartment.users, "userNames":apartment.userNames]) { (error) in
            if(error != nil) {
                print(error!.localizedDescription)
            }
        }

        for userUUID in apartment.users {
            Firestore.firestore().collection("users").document(userUUID).getDocument(completion: { (document, error) in
                if let document = document {
                    let roommateUser = try! FirestoreDecoder().decode(AppUser.self, from: document.data()!)
                    self.userManager?.addApartmentToUser(apartment: apartment, user: roommateUser)
                } else {
                    print("Document does not exist")
                }
            })
        }
        completion(true)
    }

    func removeApartmentFromUser(apartment: Apartment, uuid: String, fullName: String, completion: @escaping (Bool) -> Void) {
        var apartmentUsers: [String] = []
        var apartmentUserNames: [String] = []

        // God I'm so tired
        if(apartment.users.count > 0 && (apartment.users.contains(uuid))) {
            apartmentUsers = apartment.users
            apartmentUsers = apartmentUsers.filter { $0 != uuid }
        }

        if(apartment.userNames.count > 0 && (apartment.userNames.contains(fullName))) {
            apartmentUserNames = apartment.userNames
            apartmentUserNames = apartmentUserNames.filter { $0 != fullName }
        }

        apartment.users = apartmentUsers
        apartment.userNames = apartmentUserNames

        Firestore.firestore().collection("apartments").document(apartment.uuid.uuidString).updateData(["users": apartmentUsers]) { (error) in
            if(error != nil) {
                print(error!.localizedDescription)
                completion(false)
            }

            Firestore.firestore().collection("users").document(uuid).getDocument(completion: { (document, error) in
                if let document = document {
                    let roommateUser = try! FirestoreDecoder().decode(AppUser.self, from: document.data()!)
                    self.userManager?.removeApartmentFromUser(apartment: apartment, user: roommateUser, uuid: nil)
                    completion(true)
                } else {
                    print("Document does not exist")
                    completion(false)
                }
            })

        }
    }

    func persistApartment(apartment: Apartment) {
        let apartmentData = try! FirestoreEncoder().encode(apartment)
        Firestore.firestore().collection("apartments").document(apartment.uuid.uuidString).setData(apartmentData) { (error) in
            if(error != nil) {
                print(error!.localizedDescription)
            }

            self.addApartmentToUsers(apartment: apartment, completion: { (_) in
                //
            })
        }

    }
}

protocol ApartmentManagerDelegate {
    func apartmentsRetrieved()
}
