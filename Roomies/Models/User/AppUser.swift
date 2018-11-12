//
//  User.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class AppUser: ObjectModel {
    var emailAddress: String = String()
    var fullName: String = String()
    var userID: String = String()
    var apartments: [String] = []
    var groceryCategories: [GroceryCategory]? = []
    
    var databaseKey: String = "apartments"
    
    init(emailAddress: String, fullName: String?, userID: String?) {
        self.fullName = fullName!
        self.emailAddress = emailAddress
        self.userID = userID!
        super.init()
    }
    
    convenience init(emailAddress: String, fullName: String?){
        self.init(emailAddress: emailAddress, fullName: fullName, userID: "")
    }
    
    required init(from decoder: Decoder) throws{
        try super.init(from: decoder)
    }
}

enum UserAuthState: Int, Codable {
    case authorized = 0
    case unauthorized = 1
}

