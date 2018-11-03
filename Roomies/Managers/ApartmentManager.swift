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

class ApartmentManager{
    var appUser: AppUser? = nil
    private var userManager: UserManager? = nil
    
    init(){
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        appUser = userManager!.currentUser
    }
    
    func persistApartment(apartment: Apartment){
        let apartmentData = try! FirestoreEncoder().encode(apartment)
        Firestore.firestore().collection("apartments").document(apartment.uuid.uuidString).setData(apartmentData) { (error) in
            if(error != nil){
                print(error!.localizedDescription)
            }
            
            var apartments: [UUID] = []
            if(self.appUser?.apartments != nil){
                apartments = (self.appUser?.apartments)!
            }
            
            apartments.append(apartment.uuid)
            self.appUser?.apartments = apartments
            
            let userData = try! FirestoreEncoder().encode(self.appUser)
            
            Firestore.firestore().collection("users").document(self.appUser!.userID!).updateData(["apartments":userData["apartments"]!])
        }
        

    }
}
