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
    var roommates: [String] = []

    override func viewDidLoad() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if(user != nil){
                self.userManager = (UIApplication.shared.delegate as! AppDelegate).userManager
                self.appUser = self.userManager?.currentUser
                
                // FIX ME
                if((self.appUser?.apartments.count)! > 0){
                    self.fetchApartmentData(apartmentID: (self.appUser?.apartments.first)!)
                }
            }
        }
    }

    func fetchApartmentData(apartmentID: UUID) {
        print(apartmentID.uuidString)
        Firestore.firestore().collection("apartments").document(apartmentID.uuidString).getDocument { document, error in
            if let document = document {
                let apartment = try! FirestoreDecoder().decode(Apartment.self, from: document.data()!)
                print(apartment)
                self.currentApartment = apartment
                self.tableView.reloadData()
                
                self.title = apartment.apartmentName
                
                var loopCounter = 0
                
                for user in apartment.users!{
                    let indexPath = IndexPath(row: loopCounter, section: 1)
                    self.userManager?.getUserNameFor(userID: user, returnedUserName: { (userName) in
                        self.roommates.append(userName!)
                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                        loopCounter += 1
                    })
                }
                MBProgressHUD.hide(for: self.view, animated: true)

            } else {
                print("Document does not exist")
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // One for information, one for roommates
        return 2
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.currentApartment != nil){
            switch section{
            case 0:
                return 2
            default:
                return (self.currentApartment?.users?.count)! + 1
            }
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.row == 1 && indexPath.section == 0){
            // Map cell
            return 195
        }else if(indexPath.section == 1){
            // Roommates cells
            return 65
        }
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "Information"
        }
        return "Roommates"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = UITableViewCell()
        if(indexPath.section == 0) {
            // Information section
            switch indexPath.row {
            case 0:
                cell = self.tableView.dequeueReusableCell(withIdentifier: "infoCell")!
                cell.textLabel?.text = "Apartment Name"
                cell.detailTextLabel?.text = currentApartment?.apartmentName
                break;
            case 1:
                cell = self.tableView.dequeueReusableCell(withIdentifier: "mapCell") as! UITableViewMapCell
                (cell as! UITableViewMapCell).annotation = currentApartment?.getApartmentPlacemark()
                (cell as! UITableViewMapCell).addMapPoint()
                break;
            default:
                break;
            }
        } else {
            if(roommates.count > 0){
                cell = self.tableView.dequeueReusableCell(withIdentifier: "infoCell")!
                cell.textLabel?.text = roommates[indexPath.row]
                cell.detailTextLabel?.text = ""
            }
            if (indexPath.row > roommates.count){
                let addRoommateButton = UIButton(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 65))
                addRoommateButton.setTitle("Add Roommate", for: .normal)
                addRoommateButton.setTitleColor(addRoommateButton.tintColor, for: .normal)
                cell = UITableViewCell(style: .default, reuseIdentifier: "buttonCell")
                cell.addSubview(addRoommateButton)
            }
          
        }
        return cell
    }
}
