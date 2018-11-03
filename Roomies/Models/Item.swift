//
//  Item.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class Item: Codable {
    var uuid: UUID
        // the ID here can either be unique (then it would be necessary to hold a database with every user item, then users could have a frequent item DB, track the prices across stores, etc.)
        // OR the id can just be a name
    var name: String = "DefaultItem"
//    var brandName: String?
    var price: Double = -1.0
    
    init(initialName: String, initialPrice: Double) {
        // set UUID
            // SOURCE: https://stackoverflow.com/questions/24428250/generate-a-uuid-on-ios-from-swift
        self.uuid = UUID()
        self.name = initialName
        self.price = initialPrice
    }
}
