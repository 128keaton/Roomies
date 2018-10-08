//
//  GroceryList.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

protocol Listable: Codable {
}

class GroceryList: Listable {
//    var groceryItems: Array<GroceryItem>?
    var groceryListID: String = "Default" /// the root name of the grocery list
    
//    init(initialGroceryItems: Array<GroceryItem>) {
//        self.groceryItems = initialGroceryItems
//        self.groceryListID = "Default"
//    }
    
}
