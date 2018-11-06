//
//  ObjectModel.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/5/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import CodableFirebase

class ObjectModel: Codable {
    func addRelationshipForKey(key: String, object: ObjectModel, objectKey: String) -> ObjectModel {
        let rawObject = try! FirebaseEncoder().encode(self) as! [String: Any]
        if(rawObject["databaseKey"] == nil) {
            fatalError("You done fucked up a a ron")
        }
        return try! FirebaseDecoder().decode(type(of: self), from: rawObject)
    }
}
