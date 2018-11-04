//
//  UITableViewStatCell.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/3/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class UITableViewStatCell: UITableViewCell {
    @IBOutlet weak var billsNumber: UILabel?
    @IBOutlet weak var roommatesNumber: UILabel?
    @IBOutlet weak var groceryListNumber: UILabel?

    @IBOutlet weak var billNumberTitle: UILabel?
    @IBOutlet weak var roommatesNumberTitle: UILabel?
    @IBOutlet weak var groceryListNumberTitle: UILabel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setBillNumber(bills: Int) {
        if(bills > 1) {
            billsNumber?.text = String(describing: bills)
            billNumberTitle?.text = "Bills"
        } else if(bills == 1) {
            billsNumber?.text = String(describing: 1)
            billNumberTitle?.text = "Bill"
        } else if (bills <= 0) {
            billsNumber?.text = String(describing: 0)
            billNumberTitle?.text = "Bills"
        }
    }

    func setRoommatesNumber(roommates: Int) {
        if(roommates > 1) {
            roommatesNumber?.text = String(describing: roommates)
            roommatesNumberTitle?.text = "Roommates"
        } else if(roommates == 1) {
            roommatesNumber?.text = String(describing: 1)
            roommatesNumberTitle?.text = "Roommate"
        }else if (roommates <= 0) {
            roommatesNumber?.text = String(describing: 0)
            roommatesNumberTitle?.text = "Roommates"
        }
    }

    func setGroceriesNumber(groceries: Int) {
        if(groceries > 1) {
            groceryListNumber?.text = String(describing: groceries)
            groceryListNumberTitle?.text = "Groceries"
        } else if(groceries == 1) {
            groceryListNumber?.text = String(describing: 1)
            groceryListNumberTitle?.text = "Grocery"
        }else if (groceries <= 0) {
            groceryListNumber?.text = String(describing: 0)
            groceryListNumberTitle?.text = "Groceries"
        }
    }

}
