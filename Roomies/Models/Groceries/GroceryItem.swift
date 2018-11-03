//
//  Grocery.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class GroceryItem: Codable {
    var price: Double
    var name: String
    var category: GroceryCategory

    init(price: Double, name: String, category: GroceryCategory?){
        self.price = price
        self.name = name
        if(category == nil){
            self.category = GroceryCategory(name: "Uncategorized")
        }
        self.category = category!
    }
}
