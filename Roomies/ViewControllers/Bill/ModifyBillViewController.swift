//
//  ModifyBillViewController.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/20/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class ModifyBillViewController: UITableViewController {
    var bill: Bill? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        if bill == nil{
            bill = Bill.init(amount: 0.00, title: String(), attachedApartmentID: String(), dueBy: Date())
        }
    }
    
    
    func updateSplitLabel(){
        
    }
}
