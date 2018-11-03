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

class ApartmentViewController: UITableViewController {
    var userManager: UserManager? = nil
    var appUser: AppUser? = nil
    var currentApartment: Apartment? = nil
    var currentApartmentUUID = "" {
        didSet {
            fetchApartmentData(apartmentID: UUID(uuidString: currentApartmentUUID)!)
        }
    }


    var userSearchController: UserSearchViewController? = nil

    let apartmentManager = ApartmentManager()

    override func viewDidLoad() {
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        userManager?.delegate = self
        MBProgressHUD.showAdded(to: self.view, animated: true)
        userManager?.recheckAuth()

        NotificationCenter.default.addObserver(self, selector: #selector(getSelectedApartmentUUID), name: Notification.Name(rawValue: "showNewApartment"), object: nil)
    }

    func fetchApartmentData(apartmentID: UUID) {
        Firestore.firestore().collection("apartments").document(apartmentID.uuidString).getDocument { document, error in
            if document?.data() != nil {
                let document = document!

                let apartment = try! FirestoreDecoder().decode(Apartment.self, from: document.data()!)
                self.currentApartment = apartment
                self.tableView.reloadData()

                self.title = apartment.apartmentName
                let mapCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! UITableViewMapCell
                mapCell.addMapPoint(annotation: apartment.getApartmentPlacemark())

                MBProgressHUD.hide(for: self.view, animated: true)
            } else {
                self.performSegue(withIdentifier: "addApartment", sender: self)
            }
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

    override func numberOfSections(in tableView: UITableView) -> Int {
        // One for information, one for roommates, one for add roommates button
        return 3
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.currentApartment != nil) {
            switch section {
            case 0:
                return 2
            case 1:
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
            return 195
        } else if(indexPath.section == 1 || indexPath.section == 2 || (indexPath.section == 0 && indexPath.row == 1)) {
            // Roommates cells and name cell
            return 65
        }

        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0) {
            return "Information"
        } else if (section == 1) {
            return "Roommates"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 2) {
            return -1
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 2 && indexPath.row == 0) {
            self.showUserSearch()
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    @objc func getSelectedApartmentUUID() {
        let userDefaults = UserDefaults.standard
        var apartmentUUID = userDefaults.string(forKey: "selectedApartmentUUID")

        if(apartmentUUID == nil) {
            apartmentUUID = self.appUser?.apartments.last?.uuidString
            userDefaults.set(apartmentUUID!, forKey: "selectedApartmentUUID")
            userDefaults.synchronize()
        }

        self.currentApartmentUUID = apartmentUUID!
    }

    func showUserSearch() {
        userSearchController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userSearch") as? UserSearchViewController
        userSearchController!.delegate = self
        userSearchController?.currentUserUUID = self.appUser!.userID
        userSearchController?.presentSelfIn(viewController: self.parent!)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "addApartment") {
            let newApartmentViewController = segue.destination.children.first! as! NewApartmentViewController
            newApartmentViewController.currentUserUUID = self.appUser!.userID
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        guard let apartment = currentApartment
            else {
                return cell
        }

        if(indexPath.section == 0) {
            // Information section
            switch indexPath.row {
            case 0:
                cell = self.tableView.dequeueReusableCell(withIdentifier: "mapCell") as! UITableViewMapCell
                break
            case 1:
                cell = self.tableView.dequeueReusableCell(withIdentifier: "infoCell")!
                cell.textLabel?.text = "Apartment Name"
                cell.detailTextLabel?.text = currentApartment?.apartmentName
                break
            default:
                break
            }
        } else if(indexPath.section == 1) {
            if(apartment.userNames.count > 0) {
                cell = self.tableView.dequeueReusableCell(withIdentifier: "infoCell")!
                cell.textLabel?.text = apartment.userNames[indexPath.row]
                cell.detailTextLabel?.text = ""
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
    func userHasBeenAuthenticated() {
        self.appUser = self.userManager?.currentUser
        self.getSelectedApartmentUUID()
    }
}

extension ApartmentViewController: UserSearchViewControllerDelegate {
    func didSelectUser(uuid: String, fullName: String) {
        let apartment = currentApartment!
        apartment.userNames.append(fullName)
        apartment.users.append(uuid)
        
        self.apartmentManager.addApartmentToUsers(apartment: apartment) { (_) in
            self.tableView.reloadData()
        }
    }
}
