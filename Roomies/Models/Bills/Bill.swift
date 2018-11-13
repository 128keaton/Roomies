//
//  Bill.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class Bill: ObjectModel{
    var amount: Decimal = 0.0
    var title: String = ""
    var billID = UUID().uuidString
    var attachedApartmentID: String = ""
    var dueBy: Date = Date()
    
    init(amount: Decimal, title: String, attachedApartmentID: String, dueBy: Date) {
        self.amount = amount
        self.title = title
        self.attachedApartmentID = attachedApartmentID
        self.dueBy = dueBy
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
       try! super.init(from: decoder)
    }
    
}
