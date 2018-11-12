//
//  ApartmentViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import CodableFirebase
import MBProgressHUD
import CoreLocation

class ApartmentViewController: UITableViewController {
    var userSearchController: UserSearchViewController? = nil
    var createApartmentButton: UIButton? = nil
    var currentHUD: MBProgressHUD? = nil
    var entityManager: EntityManager? = nil
    var currentApartment: Apartment? = nil{
        didSet{
            self.fetchApartmentData(apartmentID: (currentApartment?.apartmentID)!)
        }
    }
    
    override func viewDidLoad() {
        currentHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if(user != nil) {
                self.entityManager = (UIApplication.shared.delegate as! AppDelegate).entityManager
                guard let apartment = self.entityManager?.currentApartment!
                    else{
                        return
                }
                self.currentApartment = apartment
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(getSelectedApartmentID), name: Notification.Name(rawValue: "showNewApartment"), object: nil)
    }

    func fetchApartmentData(apartmentID: String) {
        Firestore.firestore().collection("apartments").document(apartmentID).getDocument { document, error in
            if document?.data() != nil {
                let document = document!
                self.tableView.reloadData()
            } else {
                self.addApartment()
            }
            self.currentHUD?.hide(animated: true)
        }
    }

    func reloadRoommateRows() {
        var indexPaths: [IndexPath] = []
        guard let apartment = currentApartment
            else {
                return
        }

        for indexRow in 0...apartment.userNames.count {
            indexPaths.append(IndexPath(row: indexRow, section: 1))
        }

        self.tableView.insertRows(at: indexPaths, with: .automatic)
    }

    func addCreateApartmentButton() {
        let deviceWidth = UIScreen.main.bounds.width
        let deviceHeight = UIScreen.main.bounds.height

        let createApartmentButtonWrapper = UIView(frame: CGRect(x: 0, y: 0, width: deviceWidth, height: deviceHeight))
        createApartmentButton = UIButton(frame: CGRect(x: 24, y: deviceHeight / 2, width: deviceWidth - 48, height: 60))

        createApartmentButton?.backgroundColor = self.view.tintColor
        createApartmentButton?.setTitle("Create Apartment", for: .normal)
        createApartmentButton?.titleLabel?.textAlignment = .center
        createApartmentButton?.layer.cornerRadius = 4
        createApartmentButton?.layer.masksToBounds = true
        createApartmentButton?.addTarget(self, action: #selector(addApartment), for: .touchUpInside)

        createApartmentButtonWrapper.addSubview(createApartmentButton!)
        self.tableView.backgroundView = createApartmentButtonWrapper
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if(self.currentApartment == nil) {
            return 0
        }
        self.tableView.backgroundView = nil
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.currentApartment != nil) {
            switch section {
            case 0:
                return 1
            case 1:
                return 1
            case 2:
                guard let apartment = currentApartment
                    else {
                        return 0
                }
                return apartment.userNames.count
            default:
                return 1
            }
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.section == 0 && indexPath.row == 0) {
            // Map cell
            return 300
        } else if(indexPath.section == 1) {
            return 85
        } else if(indexPath.section == 2 || (indexPath.section == 0 && indexPath.row == 1)) {
            // Roommates cells and name cell
            return 55
        }

        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0) {
            return "Map"
        } else if (section == 1) {
            return "Information"
        } else if(section == 2) {
            return "Household"
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func getSelectedApartmentID() {
      // FIXME
    }

    @IBAction func showUserSearch() {
        userSearchController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userSearch") as? UserSearchViewController
        userSearchController!.delegate = self
        userSearchController?.currentUserIDs = (currentApartment?.userIDs)!
        userSearchController?.presentSelfIn(viewController: self.parent!)
    }

    @objc func addApartment() {
        if(self.currentUser != nil || self.userManager?.currentUser != nil) {
            self.currentUser = self.userManager?.currentUser
            self.performSegue(withIdentifier: "addApartment", sender: self)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if(indexPath.section == 2 && self.currentApartment?.userIDs[indexPath.row] != self.currentApartment?.ownerUserID) {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let userToRemoveID = self.currentApartment?.userIDs[indexPath.row]
            let userToRemoveName = self.currentApartment?.userNames[indexPath.row]

            self.apartmentManager?.removeApartmentFromUser(apartment: self.currentApartment!, userID: userToRemoveID!, fullName: userToRemoveName!) { (didRemove) in
                if(didRemove) {
                    self.fetchApartmentData(apartmentID: (self.currentApartment?.apartmentID)!)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showApartments") {
            let apartmentListController = segue.destination.children.first! as! ApartmentListViewController
            apartmentListController.apartmentViewController = self
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        guard let apartment = currentApartment
            else {
                return cell
        }

        if(indexPath.section == 0 && indexPath.row == 0) {
            // Map section
            let mapCell = self.tableView.dequeueReusableCell(withIdentifier: "mapCell") as! UITableViewMapCell
            mapCell.addAddressData(addressData: apartment.addressComponents)
            if let distance = getUserDistanceFromApartment(){
                mapCell.setDistance(distance: distance)
            }
            mapCell.addMapPoint(annotation: apartment.getApartmentPlacemark())
            cell = mapCell
        } else if(indexPath.section == 1 && indexPath.row == 0) {
            let statCell = self.tableView.dequeueReusableCell(withIdentifier: "statCell")! as! UITableViewStatCell

            statCell.setBillNumber(bills: apartment.billIDs.count)
            statCell.setGroceriesNumber(groceries: apartment.groceryIDs.count)
            statCell.setRoommatesNumber(roommates: (apartment.userIDs.count - 1))

            cell = statCell
        } else if(indexPath.section == 2) {
            if(apartment.userNames.count > 0) {
                cell = self.tableView.dequeueReusableCell(withIdentifier: "infoCell")!
                cell.textLabel?.text = apartment.userNames[indexPath.row]

                if(apartment.userIDs[indexPath.row] == self.currentUser?.userID) {
                    cell.detailTextLabel?.text = "(you)"
                    cell.detailTextLabel?.textColor = UIColor.gray
                } else {
                    cell.detailTextLabel?.text = ""
                }

                if(apartment.usersInRange.contains(apartment.userIDs[indexPath.row])) {
                    cell.textLabel?.textColor = self.view.tintColor
                } else {
                    cell.textLabel?.textColor = UIColor.gray
                }
            }
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "buttonCell")
            cell.textLabel?.text = "Add a Roommate"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = self.view.tintColor
        }
        return cell
    }
}

extension ApartmentViewController: UserManagerDelegate {
    func userAuthorizationExpired() {
        // remove the fucking user
    }
    
    func userHasBeenAuthenticated() {
        DispatchQueue.main.async {
            self.getSelectedApartmentID()
        }
    }
}

extension ApartmentViewController: CurrentApartmentManagerDelegate {
    func currentApartmentChanged(newApartment: Apartment) {
        self.currentApartment = newApartment
        self.tableView.reloadData()
    }
    
    func currentApartmentRemoved(removedApartment: Apartment) {
        self.currentApartment = nil
        self.tableView.reloadData()
    }
    
    func currentApartmentUpdated(updatedApartment: Apartment) {
        let previousApartment = self.currentApartment!
        self.currentApartment = updatedApartment

        if(previousApartment.addressComponents != currentApartment!.addressComponents) {
            self.tableView.reloadSections([0], with: .automatic)
        }

        if(previousApartment.apartmentName != currentApartment?.apartmentName) {
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
        }

        if(previousApartment.userIDs != currentApartment?.userIDs || previousApartment.usersInRange != currentApartment?.usersInRange) {
            self.tableView.reloadSections([0,2], with: .automatic)
        }

        if(previousApartment.groceryIDs != currentApartment?.groceryIDs || previousApartment.userIDs != currentApartment?.userIDs || previousApartment.billIDs != currentApartment?.billIDs) {
            self.tableView.reloadSections([1], with: .automatic)
        }

    }
}
extension ApartmentViewController: UserSearchViewControllerDelegate {
    func didSelectUser(userID: String, fullName: String) {
        let apartment = currentApartment!
        apartment.userNames.append(fullName)
        apartment.userIDs.append(userID)

        entityManager?.addApartmentToUsers(apartment: apartment, completion: { (_) in
            self.tableView.reloadSections([2], with: .automatic)
        })
    }
}
