//
//  Item.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class Item {
    var uuid: UUID
    var name: String
    
    init(initialName: String) {
        // set UUID
            // SOURCE: https://stackoverflow.com/questions/24428250/generate-a-uuid-on-ios-from-swift
        self.uuid = UUID()
        self.name = initialName
    }
}
