//
//  User.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class AppUser: Codable {
    var emailAddress: String
    var fullName: String
    var userID: String
    var apartments: [UUID] = []
    
    init(emailAddress: String, fullName: String?, userID: String?) {
        self.fullName = fullName!
        self.emailAddress = emailAddress
        self.userID = userID!
    }
    
    convenience init(emailAddress: String, fullName: String?){
        self.init(emailAddress: emailAddress, fullName: fullName, userID: "")
    }
}

enum UserAuthState: Int, Codable {
    case authorized = 0
    case unauthorized = 1
}

