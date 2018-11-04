//
//  UITableViewBillCell.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/4/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit

class UITableBillCell: UITableViewCell{
    @IBOutlet weak var billTitleLabel: UILabel?
    @IBOutlet weak var billDueLabel: UILabel?
    @IBOutlet weak var billAmountLabel: UILabel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            var frame = newValue
            frame.origin.x += 15
            frame.size.width -= 2 * 15
            
            super.frame = frame
        }
    }

}
