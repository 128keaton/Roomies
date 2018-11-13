//
//  AddGroceryListItemController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class AddGroceryListItemController: UITableViewController {
    @IBOutlet weak var priorityLabel: UILabel?
    @IBOutlet weak var priorityStepper: UIStepper?
    @IBOutlet weak var nameField: UITextField?
    @IBOutlet weak var categoryField: UITextField?

    var currentPriority = 1
    var entityManager = (UIApplication.shared.delegate as! AppDelegate).entityManager!
    
    @IBAction func validateValues() {
        if(self.nameField?.text == "") {
            displayAlert(message: "The name field cannot be empty", title: "Invalid name")
            return
        }
        
        var category: GroceryCategory? = nil
        if(self.categoryField!.text != nil){
            category = GroceryCategory(name: (self.categoryField?.text)!)
        }
        
        let currentApartmentID = UserDefaults.standard.string(forKey: "selectedApartmentID")
        let groceryItem = GroceryItem(name: (nameField?.text)!, category: category, priority: currentPriority, apartmentID: currentApartmentID!)
        
        entityManager.persistEntity(groceryItem)
        dismissSelf()
    }

    @IBAction func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }

    func displayAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func stepperValueChanged(sender: UIStepper) {
        switch sender.value {
        case 1:
            priorityLabel?.text = "Priority: ❗️"
            break
        case 2:
            priorityLabel?.text = "Priority: ❗️❗️"
            break
        default:
            priorityLabel?.text = "Priority: ❗️❗️❗️"
            break
        }
        currentPriority = Int(sender.value)
    }
}
