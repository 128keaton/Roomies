//
//  ApartmentListViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class ApartmentListViewController: UITableViewController{
    let apartmentManager = ApartmentManager()
    var apartments: [Apartment] = []
    
    override func viewDidLoad() {
        apartmentManager.delegate = self
        apartmentManager.fetchApartments()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apartments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "textCell")
        cell?.textLabel?.text = apartments[indexPath.row].apartmentName
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let apartment = apartments[indexPath.row]
        print(apartment.apartmentName)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
}

extension ApartmentListViewController: ApartmentManagerDelegate{
    func apartmentsRetrieved() {
        self.apartments = apartmentManager.fetchedApartments
        self.tableView.reloadData()
    }
}
