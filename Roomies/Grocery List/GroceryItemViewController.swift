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
    var entityManager = (UIApplication.shared.delegate as! AppDelegate).entityManager!
    
    override func viewDidLoad() {
        self.priorityLabel?.text = "Priority: \(groceryItem!.getPriority())"
        self.nameField?.text = groceryItem!.name
        self.categoryField?.text = groceryItem?.category!.name
        self.title = groceryItem?.name
        priorityStepper?.value = Double(groceryItem!.priority)
        
        self.nameField?.delegate = self
        self.categoryField?.delegate = self
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
        changeToSaveButton()
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
    
    func changeToSaveButton(){
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(validateAndSave))
        self.navigationItem.leftBarButtonItem = saveButton
    }
    
    @objc func validateAndSave(){
        if(self.nameField?.text == "") {
            displayAlert(message: "The name field cannot be empty", title: "Invalid name")
            return
        }
        

        if(self.categoryField!.text != nil){
            groceryItem?.category = GroceryCategory(name: (self.categoryField?.text)!)
        }else if(self.categoryField?.text == nil){
            groceryItem?.category = GroceryCategory(name: "Uncategorized")
        }
        
        entityManager.updateEntity(entity: groceryItem!)
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension GroceryItemViewController: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        changeToSaveButton()
    }
}
