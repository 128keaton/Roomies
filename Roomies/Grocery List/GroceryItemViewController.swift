//
//  GroceryItemViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class GroceryItemViewController: UITableViewController {
    @IBOutlet weak var priorityLabel: UILabel?
    @IBOutlet weak var priorityStepper: UIStepper?
    @IBOutlet weak var nameField: UITextField?
    @IBOutlet weak var categoryField: UITextField?
    
    
    var groceryItem: GroceryItem? = nil
    var groceryListManager: GroceryListManager? = nil
    
    override func viewDidLoad() {
        self.priorityLabel?.text = "Priority: \(groceryItem!.getPriority())"
        self.nameField?.text = groceryItem!.name
        self.categoryField?.text = groceryItem?.category.name
        self.title = groceryItem?.name
        priorityStepper?.value = Double(groceryItem!.priority)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
        groceryItem?.priority = Int(sender.value)
    }
}
