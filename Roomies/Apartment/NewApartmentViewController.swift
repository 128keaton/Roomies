//
//  NewApartmentViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MBProgressHUD

class NewApartmentViewController: UITableViewController {
    var currentApartmentLocation: CLLocation?
    
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.distanceFilter = 10.0
        _locationManager.requestWhenInUseAuthorization()

        return _locationManager
    }()

    let apartmentManager = ApartmentManager()
    let geocoder = CLGeocoder()

    @IBOutlet var apartmentAddressField: UITextField?
    @IBOutlet var apartmentNameField: UITextField?

    @IBAction func useCurrentLocation(sender: UIButton) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation() // start location manager
        }
    }

    @IBAction func validateResponses() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if(currentApartmentLocation != nil && apartmentNameField?.text != "") {
            let apartment = Apartment(apartmentLocation: (currentApartmentLocation?.coordinate)!, apartmentName: (apartmentNameField?.text)!, baseUser: self.apartmentManager.appUser!)
            apartmentManager.persistApartment(apartment: apartment)
            
            self.dismiss(animated: true, completion: nil)
            
        } else if (apartmentAddressField?.text != "" && apartmentNameField?.text != "") {
            validateAddress(addressString: (apartmentAddressField?.text!)!)
        } else if(apartmentAddressField?.text == "" && currentApartmentLocation == nil) {
             displayAlert(message: "Please input a valid address or use your current location", title: "Invalid Address")
        } else {
            displayAlert(message: "Please input an apartment name", title: "Invalid Name")
        }
        MBProgressHUD.hide(for: self.view, animated: true)
    }


    @IBAction func addRoommates(sender: UIButton) {

    }

    private func didAddRoommate() {

    }

    func updateAddressField(address: String) {
        locationManager.stopUpdatingLocation()
        apartmentAddressField?.text = address
    }

    func validateAddress(addressString: String) {
        geocoder.geocodeAddressString(addressString) { (placemarks, error) in
            if(placemarks?.first?.location != nil) {
                self.currentApartmentLocation = placemarks!.first?.location
                self.validateResponses()
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
                self.displayAlert(message: "Please input a valid address", title: "Invalid Address")
            }
        }
    }

    func displayAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }

}

extension NewApartmentViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count >= 1 {
            currentApartmentLocation = locations.last!
            geocoder.reverseGeocodeLocation(currentApartmentLocation!, completionHandler:
                        { (placemarks, error) in
                        if (error != nil)
                        {
                            self.displayAlert(message: "Unable to determine your address, please input manually", title: "Address Failure")
                        }
                        let pm = placemarks! as [CLPlacemark]

                        if pm.count > 0 {
                            let pm = placemarks![0]

                            var addressString: String = ""
                            if pm.subLocality != nil {
                                addressString = addressString + pm.subLocality! + ", "
                            }
                            if pm.thoroughfare != nil {
                                addressString = addressString + pm.thoroughfare! + ", "
                            }
                            if pm.locality != nil {
                                addressString = addressString + pm.locality! + ", "
                            }
                            if pm.country != nil {
                                addressString = addressString + pm.country! + ", "
                            }
                            if pm.postalCode != nil {
                                addressString = addressString + pm.postalCode! + " "
                            }


                            self.updateAddressField(address: addressString)
                        }
                })
        }
    }


}
