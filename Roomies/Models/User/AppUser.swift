//
//  User.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation

class AppUser: Codable {
    var emailAddress: String?
    var fullName: String?
    var userID: String?
    var authState: UserAuthState? = .unauthorized
    
    init(emailAddress: String, fullName: String?) {
        self.fullName = fullName
        self.emailAddress = emailAddress
    }
}

enum UserAuthState: Int, Codable {
    case authorized = 0
    case unauthorized = 1
}
