//
//  User.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class AppUser: Codable {
    var emailAddress: String = String()
    var fullName: String = String()
    var userID: String = String()
    var apartments: [String] = []
    var groceryCategories: [GroceryCategory]? = []
    
    var databaseKey: String = "users"
    var profilePictureURL: URL? 
    
    init(emailAddress: String, fullName: String?, userID: String?) {
        self.fullName = fullName!
        self.emailAddress = emailAddress
        self.userID = userID!
    }
    
    // STRUCT USE ONLY
    convenience init(emailAddress: String, fullName: String?){
        self.init(emailAddress: emailAddress, fullName: fullName, userID: "")
    }
}

