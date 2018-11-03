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
    var fetchedApartments: [Apartment] = [] {
        didSet{
            if fetchedApartments.count == expectedApartmentCount  {
                didFetchApartments = true
            }
        }
    }
    
    var delegate: ApartmentManagerDelegate? = nil
    
    private var userManager: UserManager? = nil
    
    private var expectedApartmentCount = 0
    
    private var didFetchApartments = false{
        didSet{
          delegate?.apartmentsRetrieved()
        }
    }
    
    init() {
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        appUser = userManager!.currentUser
    }

    func fetchApartments(){
        let currentUser = userManager?.currentUser!
        expectedApartmentCount = (currentUser?.apartments.count)!
        
        for uuid in (currentUser?.apartments)!{
            Firestore.firestore().collection("apartments").document(uuid.uuidString).getDocument { (document, error) in
                if(error != nil) {
                    print(error!.localizedDescription)
                }
                let apartment =  try! FirestoreDecoder().decode(Apartment.self, from: document!.data()!)
                self.fetchedApartments.append(apartment)
                
            }
        }
    }
    
    func addApartmentToUUID(apartment: Apartment, uuid: String, completion: @escaping (Bool) -> Void) {
        var apartmentUsers: [String] = []
        
        // God I'm so tired
        if((apartment.users != nil) && (apartment.users?.count)! > 0 && !(apartment.users?.contains(uuid))!){
            apartmentUsers = apartment.users!
            apartmentUsers.append(uuid)
        }else if((apartment.users != nil) && (apartment.users?.count)! > 0){
             apartmentUsers = apartment.users!
        }
        
        apartment.users = apartmentUsers


        Firestore.firestore().collection("apartments").document(apartment.uuid.uuidString).updateData(["users": apartmentUsers]) { (error) in
            if(error != nil) {
                print(error!.localizedDescription)
                completion(false)
            }
            
            Firestore.firestore().collection("users").document(uuid).getDocument(completion: { (document, error) in
                if let document = document {
                    let roommateUser = try! FirestoreDecoder().decode(AppUser.self, from: document.data()!)
                    self.userManager?.addApartmentToUser(apartment: apartment, user: roommateUser)
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

            self.userManager?.addApartmentToUser(apartment: apartment, user: self.appUser!)
        }

    }
}

protocol ApartmentManagerDelegate{
    func apartmentsRetrieved()
}
