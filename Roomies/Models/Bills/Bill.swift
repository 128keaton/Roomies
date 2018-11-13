//
//  Bill.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class Bill: Codable{
    var amount: Decimal
    var title: String
    var billID = UUID().uuidString.lowercased()
    var attachedApartmentID: String
    var dueBy: Date
    var databaseKey = "bills"
    
    init(amount: Decimal, title: String, attachedApartmentID: String, dueBy: Date) {
        self.amount = amount
        self.title = title
        self.attachedApartmentID = attachedApartmentID
        self.dueBy = dueBy
    }
}
