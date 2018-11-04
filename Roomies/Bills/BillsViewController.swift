//
//  BillsViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class BillsViewController: UITableViewController {
    var billManager: BillManager? = nil
    var bills = [Bill]()
    var apartmentID = ""
    
    override func viewWillAppear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager!

        if(userDefaults.string(forKey: "selectedApartmentID") != apartmentID) {
            bills = []
            self.tableView.reloadData()
            apartmentID = userDefaults.string(forKey: "selectedApartmentID")!
            billManager = BillManager(apartmentID: apartmentID, userManager: userManager)
        }

        billManager?.delegate = self
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if(bills.count == 0) {
            TableViewHelper.emptyMessage(message: "You have no bills", viewController: self)
            return 0
        } else {
            self.tableView.backgroundView = nil
        }
        return bills.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "billCell") as? UITableBillCell
        let bill = bills[indexPath.section]
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd"
        
        cell?.billTitleLabel?.text = bill.title
        cell?.billAmountLabel?.text = "\((numberFormatter.string(from: (bill.amount as NSNumber))!))"
        cell?.layer.cornerRadius = 4
        cell?.clipsToBounds = true
        
        if(bill.dueBy == Date()){
            cell?.billDueLabel?.text = "Due today"
        }else if(Date() > bill.dueBy){
            cell?.backgroundColor = UIColor(red: 0.9, green: 0.1, blue: 0.0, alpha: 0.8)
            cell?.billDueLabel?.text = "Past due (\(dateFormatter.string(from: bill.dueBy)))"
        }else{
             cell?.backgroundColor = UIColor(red: 0.1, green: 0.9, blue: 0.0, alpha: 0.8)
            cell?.billDueLabel?.text = "Due on \(dateFormatter.string(from: bill.dueBy))"
        }
        
        cell?.billTitleLabel?.textColor = UIColor.white
        cell?.billDueLabel?.textColor = UIColor.white
        cell?.billAmountLabel?.textColor = UIColor.white
        
        return cell!
    }

    @IBAction func addTestData() {
        let bill = Bill(amount: 4.20, title: "Test Bill", attachedApartmentID: self.apartmentID, dueBy: Date())
        self.billManager?.addBill(newBill: bill)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete) {
            billManager?.removeBill(removedBill: bills[indexPath.section])
        }
    }
}
extension BillsViewController: BillManagerDelegate {
    func billAdded(addedBill: Bill) {
        self.bills.append(addedBill)
        let indexSection = self.bills.firstIndex { (bill) -> Bool in
            return bill.billID == addedBill.billID
        }

        self.tableView.insertSections([indexSection!], with: .automatic)
    }

    func billChanged(changedBill: Bill) {
        let indexSection = self.bills.firstIndex { (bill) -> Bool in
            return bill.billID == changedBill.billID
        }
        self.bills[indexSection!] = changedBill
        self.tableView.reloadSections([indexSection!], with: .automatic)
    }

    func billRemoved(removedBill: Bill) {
        let indexSection = self.bills.firstIndex { (bill) -> Bool in
            return bill.billID == removedBill.billID
        }
        self.bills = self.bills.filter { $0.billID != removedBill.billID }
        self.tableView.deleteSections([indexSection!], with: .automatic)
    }
}
