//
//  ApartmentListViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD
import CodableFirebase

class ApartmentListViewController: UITableViewController {
    var entityManager = (UIApplication.shared.delegate as! AppDelegate).entityManager!
    var currentUser: AppUser? = nil
    var currentApartment: Apartment? = nil
    var apartmentViewController: ApartmentViewController? = nil
    var userApartments: [Apartment] = []

    override func viewDidLoad() {
        entityManager.apartmentListDelegate = self
        entityManager.startWatchingApartments()
        if let currentApartment = entityManager.currentApartment {
            self.currentApartment = currentApartment
        }

        if let user = entityManager.currentUser {
            currentUser = user
        }

        MBProgressHUD.showAdded(to: self.view, animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MBProgressHUD.hide(for: self.view, animated: true)
        if(userApartments.count == 0) {
            TableViewHelper.emptyMessage(message: "You have no other apartments", viewController: self)
            return 0
        } else {
            self.tableView.backgroundView = nil
        }
        return userApartments.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "textCell")
        cell?.textLabel?.text = userApartments[indexPath.row].apartmentName
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let apartment = userApartments[indexPath.row]
        self.tableView.deselectRow(at: indexPath, animated: true)
        entityManager.updateCurrentApartment(newApartment: apartment)
        dismissSelf()
    }

    @IBAction func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        let apartment = userApartments[indexPath.row]
        if(currentUser?.userID == apartment.ownerUserID) {
            return "Delete"
        }
        return "Leave"
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let apartment = userApartments[indexPath.row]
            let entityData = try! FirebaseEncoder().encode(apartment) as! [String:Any]
            
            if(currentUser?.userID == apartment.ownerUserID) {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                entityManager.deleteApartment(apartment)
            } else {
                entityManager.bulkUpdateEntityData(modificationType: .removed, data: [(currentUser?.userID)!], entityData: entityData, keys: ["userIDs"])
                entityManager.bulkUpdateEntityData(modificationType: .removed, data: [(currentUser?.fullName)!], entityData: entityData, keys: ["userNames"])
            }
        }
    }

}

extension ApartmentListViewController: ApartmentListManagerDelegate {
    func apartmentAdded(addedApartment: Apartment) {
        if(addedApartment.apartmentID != currentApartment?.apartmentID) {
            self.userApartments.append(addedApartment)
            let indexRow = self.userApartments.firstIndex { (apartment) -> Bool in
                return addedApartment.apartmentID == apartment.apartmentID
            }
            self.tableView.insertRows(at: [IndexPath(row: indexRow!, section: 0)], with: .automatic)
        }
    }
    func apartmentChanged(changedApartment: Apartment) {
        if(changedApartment.apartmentID != currentApartment?.apartmentID) {
            let indexRow = self.userApartments.firstIndex { (apartment) -> Bool in
                return changedApartment.apartmentID == apartment.apartmentID
            }
            self.userApartments[indexRow!] = changedApartment
            self.tableView.reloadRows(at: [IndexPath(row: indexRow!, section: 0)], with: .automatic)
        }
    }
    func apartmentRemoved(removedApartment: Apartment) {
        let indexRow = self.userApartments.firstIndex { (apartment) -> Bool in
            return removedApartment.apartmentID == apartment.apartmentID
        }
        self.userApartments = self.userApartments.filter { $0.apartmentID != removedApartment.apartmentID }
        self.tableView.deleteRows(at: [IndexPath(row: indexRow!, section: 0)], with: .automatic)
    }
}
