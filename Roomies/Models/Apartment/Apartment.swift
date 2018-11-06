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

class Apartment: ObjectModel {
    var apartmentLatitude: Double = Double()
    var apartmentLongitude: Double = Double()
    var apartmentAddress: String = String()
    var addressComponents = [String]()
    
    var apartmentName: String = String()
    var ownerUserID: String = String()
    
    var userIDs: [String] = []
    var userNames: [String] = []
    var usersInRange: [String] = []
    
    var apartmentID = UUID().uuidString.lowercased()
    var groceryIDs: [String] = []
    var billIDs: [String] = []
    
    var databaseKey: String = "apartments"
    
    init(apartmentAddress: String, apartmentLocation: CLLocationCoordinate2D, apartmentName: String, ownerUser: AppUser) {
        self.apartmentLatitude = apartmentLocation.latitude
        self.apartmentLongitude = apartmentLocation.longitude
        self.apartmentAddress = apartmentAddress
        
        
        self.userIDs = [ownerUser.userID]
        self.userNames = [ownerUser.fullName]
        self.ownerUserID = ownerUser.userID
        
        self.apartmentName = apartmentName
        super.init()
    }
    
    required init(from decoder: Decoder) throws{
       try super.init(from: decoder)
    }
    
    func getApartmentPlacemark() -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(self.apartmentLatitude, self.apartmentLongitude)
        return annotation
    }
    
    func getLocation() -> CLLocation{
        return CLLocation(latitude: self.apartmentLatitude, longitude: self.apartmentLongitude)
    }
    
    enum CodingKeys : String, CodingKey {
        case page
        case totalPages = "total_pages"
        case perPage = "per_page"
        case totalRecords = "total_records"
    }
}
