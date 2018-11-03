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
    var currentUser: AppUser? = nil
    var currentApartment: Apartment? = nil
    var currentApartmentID = "" {
        didSet {
            fetchApartmentData(apartmentID: currentApartmentID)
        }
    }

    var userSearchController: UserSearchViewController? = nil
    var createApartmentButton: UIButton? = nil
    var currentHUD: MBProgressHUD? = nil

    var apartmentManager: ApartmentManager? = nil
    let userDefaults = UserDefaults.standard

    override func viewDidLoad() {
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if(user != nil){
                self.currentHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
                self.userManager = UserManager(firUser: user!)
                self.userManager?.getCurrentUser(completion: { (user) in
                    self.currentUser = user
                    self.getSelectedApartmentID()
                    self.apartmentManager = ApartmentManager(withUserManager: self.userManager!)
                    self.apartmentManager?.currentApartmentDelegate = self
                    self.apartmentManager?.startWatchingApartment(apartmentID: self.currentApartmentID)
                    (UIApplication.shared.delegate as! AppDelegate).userManager = self.userManager
                })
                
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(getSelectedApartmentID), name: Notification.Name(rawValue: "showNewApartment"), object: nil)
    }

    func fetchApartmentData(apartmentID: String) {
        Firestore.firestore().collection("apartments").document(apartmentID).getDocument { document, error in
            if document?.data() != nil {
                let document = document!

                let apartment = try! FirestoreDecoder().decode(Apartment.self, from: document.data()!)
                self.currentApartment = apartment
                self.tableView.reloadData()

                self.navigationItem.title = apartment.apartmentName
                let mapCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! UITableViewMapCell
                mapCell.addMapPoint(annotation: apartment.getApartmentPlacemark())
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

    func updateApartmentID(newApartmentID: String?) {
        if(newApartmentID != nil) {
            userDefaults.set(newApartmentID!, forKey: "selectedApartmentID")
            userDefaults.synchronize()
            self.currentApartmentID = newApartmentID!
            
        } else {
            self.currentHUD?.hide(animated: true)
            addCreateApartmentButton()
        }
    }

    @objc func getSelectedApartmentID() {
        var apartmentID = userDefaults.string(forKey: "selectedApartmentID")

        if(apartmentID == nil) {
            apartmentID = self.currentUser?.apartments.first
            updateApartmentID(newApartmentID: apartmentID)
        } else {
            self.currentApartmentID = apartmentID!
        }
    }

    func showUserSearch() {
        userSearchController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userSearch") as? UserSearchViewController
        userSearchController!.delegate = self
        userSearchController?.currentUserID = (self.userManager?.currentUser?.userID)!
        userSearchController?.presentSelfIn(viewController: self.parent!)
    }

    @objc func addApartment() {
        if(self.currentUser != nil || self.userManager?.currentUser != nil) {
            self.currentUser = self.userManager?.currentUser
            self.performSegue(withIdentifier: "addApartment", sender: self)
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if(indexPath.section == 1 && self.currentApartment?.users[indexPath.row] != self.currentApartment?.baseUser) {
            return true
        }
        return false
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let userToRemoveID = self.currentApartment?.users[indexPath.row]
            let userToRemoveName = self.currentApartment?.userNames[indexPath.row]

            self.apartmentManager?.removeApartmentFromUser(apartment: self.currentApartment!, userID: userToRemoveID!, fullName: userToRemoveName!) { (didRemove) in
                if(didRemove) {
                    self.fetchApartmentData(apartmentID: (self.currentApartment?.apartmentID)!)
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "addApartment") {
            let newApartmentViewController = segue.destination.children.first! as! NewApartmentViewController
            newApartmentViewController.userManager = self.userManager
        } else if (segue.identifier == "showApartments") {
            let apartmentListController = segue.destination.children.first! as! ApartmentListViewController
            apartmentListController.apartmentViewController = self
            apartmentListController.userManager = self.userManager
            apartmentListController.currentApartmentID = self.currentApartmentID
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
        DispatchQueue.main.async {
            self.getSelectedApartmentID()
        }
    }
}

extension ApartmentViewController: CurrentApartmentManagerDelegate{
    func currentApartmentRemoved(removedApartment: Apartment) {
        self.currentApartment = nil
        self.currentApartmentID = ""
        userDefaults.set(nil, forKey: "selectedApartmentID")
        userDefaults.synchronize()
        self.tableView.reloadData()
    }
    func currentApartmentUpdated(updatedApartment: Apartment) {
        let previousApartment = self.currentApartment!
        self.currentApartment = updatedApartment
        if(previousApartment.users != currentApartment!.users){
            self.tableView.reloadSections([1], with: .automatic)
        }
        
        if(previousApartment.apartmentLongitude != currentApartment?.apartmentLongitude || previousApartment.apartmentLatitude != currentApartment?.apartmentLatitude){
            self.tableView.reloadSections([0], with: .automatic)
        }
        
        if(previousApartment.apartmentName != currentApartment?.apartmentName){
            self.navigationItem.title = currentApartment?.apartmentName
            self.tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
        }
        
    }
}
extension ApartmentViewController: UserSearchViewControllerDelegate {
    func didSelectUser(userID: String, fullName: String) {
        let apartment = currentApartment!
        apartment.userNames.append(fullName)
        apartment.users.append(userID)

        self.apartmentManager?.addApartmentToUsers(apartment: apartment) { (_) in
            self.tableView.reloadSections([1], with: .automatic)
        }
    }
}