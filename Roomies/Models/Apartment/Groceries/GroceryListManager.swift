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
    var managedGroceryLists: Array<GroceryList>?
    private var defaultGroceryPath = "groceries"
    
//    private var userDefinedGroceryPath: String?
    
    func groceryItemWasPurchased(by: AppUser, for: Apartment, with price: Double) {
        // log the transaction
        // cross the item off of the list
    }
    
    // ---------------------------------------------------------------------
    
    func deleteGroceryItemOnBackend(item: GroceryItem) {
        // delete request to firebase
    }
    
    func updateGroceryListOnBackend() {}
    
    /// Create a blank grocery list on the backend, return a grocery list object
    func createOnBackend(completion: @escaping (Bool) -> Void) {
        let transientGroceryList = GroceryList()
        let encodedGroceryList = try! FirestoreEncoder().encode(transientGroceryList)
    Firestore.firestore().collection(self.defaultGroceryPath).document(transientGroceryList.groceryListID).setData(encodedGroceryList) { (error) in
            if(error != nil) {
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    init(groceryListsToManage: Array<GroceryList>?) {
        self.managedGroceryLists = groceryListsToManage
    }
}

enum GroceryListOperation: String {
    case addItem = "add-item"
    case deleteItem = "delete-item"
    case updateItem = "update-item"
}
