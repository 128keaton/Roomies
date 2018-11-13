//
//  Grocery.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class GroceryItem: Codable {
    var name: String
    var category: GroceryCategory? = nil
    var priority = 0
    var groceryItemID = UUID().uuidString
    var attachedApartmentID: String
    var databaseKey: String = "groceries"
    
    init(name: String, category: GroceryCategory?, priority: Int, apartmentID: String) {
        self.name = name
        
        if(category == nil) {
           // self.category = GroceryCategory(name: "Uncategorized")
        } else {
          //  self.category = category!
        }

        self.attachedApartmentID = apartmentID
        self.priority = priority
    }
    
    func getPriority() -> String {
        switch self.priority {
        case 1:
            return "❗️"
        case 2:
            return "❗️❗️"
        default:
            return "❗️❗️❗️"
        }
    }
}
