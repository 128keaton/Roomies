//
//  Grocery.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class GroceryItem: Item {
    var price: Double
    // var averagePrice { ... calculated value
    var brandName: String?
    
    init(initialName: String, initialPrice: Double) {
        self.price = initialPrice
        super.init(initialName: initialName)
    }
}
