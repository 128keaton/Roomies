//
//  ObjectModel.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/5/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import CodableFirebase

class ObjectModel: Codable{

    func addRelationshipForKey(key: String, object: ObjectModel, objectKey: String) -> ObjectModel{
        let rawObject =  try! FirebaseEncoder().encode(self)
        print(type(of: self))
        return try! FirebaseDecoder().decode(type(of: self), from: rawObject)
    }
}
