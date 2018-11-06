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

class EntityManager{
    
    public func bulkUpdateEntityData(modificationType: DataModificationType, data: [String], apartment: Apartment, keys: [String]) {
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
