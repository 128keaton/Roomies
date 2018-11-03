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

class ApartmentListViewController: UITableViewController {
    let apartmentManager = ApartmentManager()

    var currentUserID = ""
    var apartmentViewController: ApartmentViewController? = nil
    var userApartments: [Apartment] = []

    override func viewDidLoad() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        currentUserID = (apartmentManager.currentUser?.userID)!
        apartmentManager.delegate = self
        apartmentManager.fetchApartments()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        updateCurrentApartment(newApartmentID: apartment.apartmentID)
        dismissSelf()
    }

    func updateCurrentApartment(newApartmentID: String) {
        apartmentViewController?.updateApartmentID(newApartmentID: newApartmentID)
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
        if(currentUserID == apartment.baseUser) {
            return "Delete"
        }
        return "Leave"
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let apartment = userApartments[indexPath.row]
            if(currentUserID == apartment.baseUser) {
                MBProgressHUD.showAdded(to: self.view, animated: true)
                apartmentManager.deleteApartment(apartment: apartment)
                apartmentManager.delegate = self
                apartmentManager.fetchApartments()
            } else {
                apartmentManager.removeApartmentFromUser(apartment: apartment, user: apartmentManager.currentUser!)
            }
        }
    }

}

extension ApartmentListViewController: ApartmentManagerDelegate {
    func apartmentsRetrieved() {
        let updatedUserApartments = apartmentManager.accessStoredApartments(exclude: true)
        var indexPaths: [IndexPath] = []
        for i in 0...self.userApartments.count {
            let indexPath = IndexPath(row: i, section: 0)
            indexPaths.append(indexPath)
        }

        self.userApartments = updatedUserApartments
        if(updatedUserApartments.count != 0) {
            self.tableView.insertRows(at: indexPaths, with: .automatic)
        } else {
            self.tableView.reloadData()
        }

        MBProgressHUD.hide(for: self.view, animated: true)
    }
}
