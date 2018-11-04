//
//  AddressLookup.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import CoreLocation

class AddressLookup {
    let geocoder = CLGeocoder()

    init() {

    }


    func getAddressComponentsFromLocation(location: CLLocation?, completionHandler: @escaping ([String])
            -> Void) {
        // Use the last reported location.
        if let lastLocation = location {
            let geocoder = CLGeocoder()

            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                completionHandler: { (placemarks, error) in
                    if error == nil {
                        let firstLocation = placemarks?[0]
                        var dataArray = [String]()

                        if let street = firstLocation?.thoroughfare {
                            if let streetAddress = firstLocation?.subThoroughfare {
                                dataArray.append(street + " " + streetAddress)
                            } else {
                                dataArray.append(street)
                            }
                        }

                        if let cityName = firstLocation?.locality {
                            if let state = firstLocation?.administrativeArea {
                                if let postalCode = firstLocation?.postalCode {
                                    dataArray.append(cityName + ", " + state + " " + postalCode)
                                } else {
                                    dataArray.append(cityName + ", " + state)
                                }
                            } else {
                                dataArray.append(cityName)
                            }

                        }


                        if let country = firstLocation?.country {
                            dataArray.append(country)
                        }

                        completionHandler(dataArray)
                    }
                    else {
                        // An error occurred during geocoding.
                        completionHandler([])
                    }
                })
        }
        else {
            // No location was available.
            completionHandler([])
        }
    }
}
