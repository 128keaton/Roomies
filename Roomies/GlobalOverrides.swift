//
//  GlobalOverrides.swift
//  Roomies
//
//  Created by Keaton Burleson on 10/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//
// Global Overrides go here

import Foundation
import UIKit

// BorderRadius on UIView/UIButton
@IBDesignable extension UIView {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}


class TableViewHelper {

    class func emptyMessage(message: String, viewController: UITableViewController) {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        let messageLabel = UILabel(frame: rect)
        messageLabel.text = message
        messageLabel.textColor = UIColor.gray
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.sizeToFit()

        viewController.tableView.backgroundView = messageLabel
        viewController.tableView.separatorStyle = .none
    }
}
