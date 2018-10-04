//
//  GroceryManager.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class GroceryListManager {
    var groceryList: Array<GroceryItem>?
    
    func groceryWasPurchased(by: AppUser, for: Apartment, with price: Double) {
        // log the transaction
        // cross the item off of the list
    }
    
    // MARK: - CRUD Functions
    // SOURCE: https://firebase.google.com/docs/database/ios/read-and-write
    func createGroceryItem() {
        // post request to firebase
        
    }
    
    func updateGroceryItem() {}
    
    func deleteGroceryItem(item: GroceryItem) {
        // delete request to firebase
        
    }
    
    init() {
        self.groceryList = nil
    }
}
