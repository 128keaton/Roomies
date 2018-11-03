//
//  GroceryManager.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import Firebase
import CodableFirebase

class GroceryListManager {
    var apartmentManager: ApartmentManager? = nil
    var currentApartmentID = ""
    var currentApartment: Apartment? = nil
    var delegate: GroceryManagerDelegate? = nil
    var beforeUpdateCount = 0
    var groceriesListener: ListenerRegistration? = nil

    init(apartmentID: String, userManager: UserManager) {
        currentApartmentID = apartmentID
        apartmentManager = ApartmentManager(withUserManager: userManager)
        apartmentManager?.getApartmentForID(apartmentID: currentApartmentID) { (apartment) in
            self.currentApartment = apartment
            self.startWatchingGroceries()
        }
    }

    func startWatchingGroceries() {
        groceriesListener = Firestore.firestore().collection("groceries").whereField("attachedApartmentID", isEqualTo: currentApartmentID).addSnapshotListener { (querySnapshot, error) in
            guard let snapshot = querySnapshot
                else {
                    return
            }

            snapshot.documentChanges.forEach { diff in
                let groceryItem = try! FirebaseDecoder().decode(GroceryItem.self, from: diff.document.data())
                if (diff.type == .added) {
                    self.delegate?.groceryAdded(addedGrocery: groceryItem)
                    self.apartmentManager?.updateApartmentData(modificationType: .add, data: groceryItem.groceryItemID, apartment: self.currentApartment!, key: "groceries")
                }
                if (diff.type == .modified) {
                    self.delegate?.groceryChanged(changedGrocery: groceryItem)
                }
                if (diff.type == .removed) {
                    self.delegate?.groceryRemoved(removedGrocery: groceryItem)
                    self.apartmentManager?.updateApartmentData(modificationType: .remove, data: groceryItem.groceryItemID, apartment: self.currentApartment!, key: "groceries")
                }
            }
        }
    }

    func addGroceryItem(newGroceryItem: GroceryItem) {
        let groceryItemData = try! FirebaseEncoder().encode(newGroceryItem) as! [String: Any]

        self.apartmentManager?.updateApartmentData(modificationType: .add, data: newGroceryItem.groceryItemID, apartment: self.currentApartment!, key: "groceries")
        Firestore.firestore().collection("groceries").document(newGroceryItem.groceryItemID).setData(groceryItemData)
    }

    func removeGroceryItem(removedGroceryItem: GroceryItem) {
        self.apartmentManager?.updateApartmentData(modificationType: .remove, data: removedGroceryItem.groceryItemID, apartment: self.currentApartment!, key: "groceries")
        Firestore.firestore().collection("groceries").document(removedGroceryItem.groceryItemID).delete()
    }


}

protocol GroceryManagerDelegate {
    func groceryRemoved(removedGrocery: GroceryItem)
    func groceryAdded(addedGrocery: GroceryItem)
    func groceryChanged(changedGrocery: GroceryItem)
}
