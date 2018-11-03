//
//  Apartment.swift
//  Roomies
//
//  Created by Josh Hatcher on 10/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class Apartment: Codable {
    var apartmentLatitude: Double
    var apartmentLongitude: Double
    
    var apartmentName: String
    var baseUser: String
    var users: [String]? = []
    var uuid = UUID()
    
    init(apartmentLocation: CLLocationCoordinate2D, apartmentName: String, baseUser: AppUser) {
        self.apartmentLatitude = apartmentLocation.latitude
        self.apartmentLongitude = apartmentLocation.longitude
        
        self.users = [baseUser.userID!]
        self.baseUser = baseUser.userID!
        self.apartmentName = apartmentName
    }
    
    func getApartmentPlacemark() -> MKPointAnnotation{
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(self.apartmentLatitude, self.apartmentLongitude)
        return annotation
    }
    
}
