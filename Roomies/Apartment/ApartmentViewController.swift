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
    var roommates: [String] = [] {
        didSet{
            reloadRoommateRows()
        }
    }
    var userSearchController: UserSearchViewController? = nil

    let apartmentManager = ApartmentManager()

    override func viewDidLoad() {
        userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
        userManager?.delegate = self
        MBProgressHUD.showAdded(to: self.view, animated: true)
        userManager?.recheckAuth()
    }

    func fetchApartmentData(apartmentID: UUID) {
        Firestore.firestore().collection("apartments").document(apartmentID.uuidString).getDocument { document, error in
            if let document = document {
                let apartment = try! FirestoreDecoder().decode(Apartment.self, from: document.data()!)
        
                self.currentApartment = apartment
                self.tableView.reloadData()

                self.title = apartment.apartmentName
                let mapCell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! UITableViewMapCell
                mapCell.addMapPoint(annotation: apartment.getApartmentPlacemark())
                
                for user in apartment.users! {
                    self.userManager?.getUserNameFor(userID: user, returnedUserName: { (userName) in
                        self.roommates.append(userName!)
                    })
                }
                MBProgressHUD.hide(for: self.view, animated: true)

            } else {
                print("Document does not exist")
            }
        }
    }

    func reloadRoommateRows(){
      /*  var indexPaths: [IndexPath] = []
        for indexRow in 0...roommates.count{
            indexPaths.append(IndexPath(row: indexRow, section: 1))
        }
        
        self.tableView.insertRows(at: indexPaths, with: .automatic)*/
        self.tableView.reloadData()
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
                return self.roommates.count
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
        }else if (section == 1){
            return "Roommates"
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 2){
            return -1
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 2 && indexPath.row == 0){
            self.showUserSearch()
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    func showUserSearch() {
        userSearchController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "userSearch") as? UserSearchViewController
        userSearchController!.delegate = self
        userSearchController?.currentUserUUID = self.appUser!.userID!
        userSearchController?.presentSelfIn(viewController: self.parent!)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "addApartment"){
            let newApartmentViewController = segue.destination.children.first! as! NewApartmentViewController
            newApartmentViewController.currentUserUUID = self.appUser!.userID!
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
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
        } else if(indexPath.section == 1){
            if(roommates.count > 0) {
                cell = self.tableView.dequeueReusableCell(withIdentifier: "infoCell")!
                cell.textLabel?.text = roommates[indexPath.row]
                cell.detailTextLabel?.text = ""
            }
        }else{
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

        // FIX ME
        if((self.appUser?.apartments.count)! > 0) {
            self.fetchApartmentData(apartmentID: (self.appUser?.apartments.first)!)
        }
    }
}

extension ApartmentViewController: UserSearchViewControllerDelegate {
    func didSelectUser(uuid: String, emailAddress: String) {
        self.apartmentManager.addApartmentToUUID(apartment: self.currentApartment!, uuid: uuid, completion: { (success) -> Void in
            if(success == true){
                self.tableView.reloadData()
            }
        })
    }
}
