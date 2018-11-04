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
    var addressData = [String]()
    var userSearchController: UserSearchViewController? = nil
    var currentUserID = ""
    var currentUserFullName = ""
    
    var userManager: UserManager? = nil

    // hack because reload adds more fields
    var alreadyAddedAddressCell = false
    var alreadyAddedNameCell = false

    var roommateIDs: [String] = []
    var roommates: [String] = [] {
        didSet {
            reloadRoommateRows()
        }
    }

    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.distanceFilter = 10.0
        _locationManager.requestWhenInUseAuthorization()

        return _locationManager
    }()

    var apartmentManager: ApartmentManager? = nil
    let geocoder = CLGeocoder()

    var apartmentAddressField: UITextField?
    var apartmentNameField: UITextField?

    override func viewDidLoad() {
        apartmentManager = ApartmentManager(withUserManager: userManager!)
        currentUserFullName = userManager?.currentUser!.fullName ?? (userManager?.currentUser?.emailAddress)!
    }

    @objc func useCurrentLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.startUpdatingLocation() // start location manager
        }
    }

    @IBAction func validateResponses() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        if(currentApartmentLocation != nil && apartmentNameField?.text != ""){
            let name = apartmentNameField?.text
            let address = apartmentAddressField?.text
            let location = currentApartmentLocation?.coordinate
            let ownerUser = self.userManager?.currentUser!
            
            let apartment = Apartment(apartmentAddress: address!, apartmentLocation: location!, apartmentName: name!, ownerUser: ownerUser!)
            
            apartment.addressComponents = self.addressData
            apartment.userIDs.append(contentsOf: self.roommateIDs)
            apartment.userNames.append(contentsOf: self.roommates)
            
            apartmentManager?.persistApartment(apartment: apartment)
            MBProgressHUD.hide(for: self.view, animated: true)
            setDefaultApartmentAndDismiss(defaultApartmentID: apartment.apartmentID)
        } else if (apartmentAddressField?.text != "" && apartmentNameField?.text != "") {
            validateAddress(addressString: (apartmentAddressField?.text!)!)
        } else if(apartmentAddressField?.text == "" && currentApartmentLocation == nil) {
            displayAlert(message: "Please input a valid address or use your current location", title: "Invalid Address")
        } else {
            displayAlert(message: "Please input an apartment name", title: "Invalid Name")
        }
        MBProgressHUD.hide(for: self.view, animated: true)
    }

    func setDefaultApartmentAndDismiss(defaultApartmentID: String) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(defaultApartmentID, forKey: "selectedApartmentID")
        userDefaults.synchronize()

        NotificationCenter.default.post(name: Notification.Name(rawValue: "showNewApartment"), object: nil)
        
        dismissSelf()
    }

    @IBAction func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 2 && indexPath.row == 0) {
            showUserSearch()
        }

        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    func showUserSearch() {
        userSearchController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userSearch") as? UserSearchViewController
        userSearchController!.delegate = self
        userSearchController?.currentUserIDs = roommateIDs
        userSearchController?.presentSelfIn(viewController: self)
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "basicCell")!
        let deviceWidth = UIScreen.main.bounds.width

        if(indexPath.section == 0) {
            // Information section
            switch indexPath.row {
            case 0:
                // FIXME hack
                if(!alreadyAddedNameCell) {
                    apartmentNameField = UITextField(frame: CGRect(x: 12, y: 0, width: deviceWidth - 12, height: cell.frame.height))
                    apartmentNameField?.placeholder = "Apartment Name"
                    apartmentNameField?.borderStyle = .none

                    cell.addSubview(apartmentNameField!)
                }

                alreadyAddedNameCell = true
                break;
            case 1:
                // FIXME hack
                if(!alreadyAddedAddressCell) {
                    let currentLocationButton = UIButton(frame: CGRect(x: deviceWidth - 58, y: 0, width: 50, height: cell.frame.height))
                    currentLocationButton.addTarget(self, action: #selector(NewApartmentViewController.useCurrentLocation), for: .touchUpInside)
                    currentLocationButton.setImage(UIImage(named: "location"), for: .normal)
                    currentLocationButton.tintColor = self.view.tintColor

                    apartmentAddressField = UITextField(frame: CGRect(x: 12, y: 0, width: deviceWidth - 66, height: cell.frame.height))
                    apartmentAddressField?.placeholder = "Apartment Address"
                    apartmentAddressField?.borderStyle = .none

                    cell.addSubview(apartmentAddressField!)
                    cell.addSubview(currentLocationButton)
                }

                alreadyAddedAddressCell = true
                break;
            default:
                break;
            }
        } else if(indexPath.section == 1) {
            if(roommates.count > 0) {
                cell = self.tableView.dequeueReusableCell(withIdentifier: "textCell")!
                cell.textLabel?.text = roommates[indexPath.row]
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = UIColor.black
            }
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "textCell")
            cell.textLabel?.text = "Add a Roommate"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = self.view.tintColor
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0) {
            return "Information"
        } else if (section == 1 && roommates.count > 0) {
            return "Roommates"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return roommates.count
        default:
            return 1
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func reloadRoommateRows() {
        // FIXME
        self.tableView.reloadData()
    }

}

extension NewApartmentViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("\(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count >= 1 {
            currentApartmentLocation = locations.last!
            AddressLookup().getAddressComponentsFromLocation(location: currentApartmentLocation!) { (addressData) in
                self.apartmentAddressField?.text = addressData.joined(separator: " ")
                self.addressData = addressData
            }
            locationManager.delegate = (UIApplication.shared.delegate as! AppDelegate)
        }
    }


}

extension NewApartmentViewController: UserSearchViewControllerDelegate {
    func didSelectUser(userID: String, fullName: String) {
        self.userManager?.findUserByID(userID: userID, returnedUser: { (roommateUser) in
            self.roommateIDs.append(userID)
            self.roommates.append(roommateUser?.fullName ?? (roommateUser?.emailAddress)!)
        })
    }
}
