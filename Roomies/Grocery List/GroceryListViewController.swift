//
//  GroceryListViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class GroceryListViewController: UITableViewController {
    var groceryListManager: GroceryListManager? = nil
    var groceryItems = [GroceryItem]()
    var apartmentID = ""
    var apartmentIDChanged = false
    
    override func viewDidLoad() {
        MBProgressHUD.showAdded(to: self.view, animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        let userManager = (UIApplication.shared.delegate as! AppDelegate).userManager!

        if(userDefaults.string(forKey: "selectedApartmentID") != apartmentID) {
            groceryItems = []
            self.tableView.reloadData()
            apartmentID = userDefaults.string(forKey: "selectedApartmentID")!
            groceryListManager = GroceryListManager(apartmentID: apartmentID, userManager: userManager)
        }
        
        groceryListManager?.delegate = self
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groceryCell")
        let grocery = groceryItems[indexPath.row]

        cell?.detailTextLabel?.text = grocery.getPriority()
        cell?.textLabel?.text = grocery.name

        return cell!
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "addItem"){
            let addListController = (segue.destination.children.first! as! AddGroceryListItemController)
            addListController.groceryListManager = self.groceryListManager
        }else if(segue.identifier == "goToItem"){
            let selectedItem = self.groceryItems[(self.tableView.indexPathForSelectedRow?.row)!]
            (segue.destination as! GroceryItemViewController).groceryItem = selectedItem
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(groceryItems.count == 0) {
            MBProgressHUD.hide(for: self.view, animated: true)
            TableViewHelper.emptyMessage(message: "You have nothing on your shopping list", viewController: self)
            return 0
        } else {
            self.tableView.backgroundView = nil
        }
        return groceryItems.count
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete) {
            groceryListManager?.removeGroceryItem(removedGroceryItem: groceryItems[indexPath.row])
        }
    }
}

extension GroceryListViewController: GroceryManagerDelegate {
    func groceryAdded(addedGrocery: GroceryItem) {
        self.groceryItems.append(addedGrocery)
        let indexRow = self.groceryItems.firstIndex { (groceryItem) -> Bool in
            return groceryItem.groceryItemID == addedGrocery.groceryItemID
        }
        
        self.tableView.insertRows(at: [IndexPath(row: indexRow!, section: 0)], with: .automatic)
    }
    func groceryChanged(changedGrocery: GroceryItem) {
        let indexRow = self.groceryItems.firstIndex { (groceryItem) -> Bool in
            return groceryItem.groceryItemID == changedGrocery.groceryItemID
        }
        self.groceryItems[indexRow!] = changedGrocery
        self.tableView.reloadRows(at: [IndexPath(row: indexRow!, section: 0)], with: .automatic)
    }
    func groceryRemoved(removedGrocery: GroceryItem) {
        let indexRow = self.groceryItems.firstIndex { (groceryItem) -> Bool in
            return groceryItem.groceryItemID == removedGrocery.groceryItemID
        }
        self.groceryItems = self.groceryItems.filter { $0.groceryItemID != removedGrocery.groceryItemID }
        self.tableView.deleteRows(at: [IndexPath(row: indexRow!, section: 0)], with: .automatic)
    }
}