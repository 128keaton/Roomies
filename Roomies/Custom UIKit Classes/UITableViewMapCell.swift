//
//  UITableViewMapCell.swift
//  Roomies
//
//  Created by Keaton Burleson on 11/2/18.
//  Copyright © 2018 Keaton Burleson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class UITableViewMapCell: UITableViewCell {
    @IBOutlet var mapView: MKMapView?
    @IBOutlet var addressLineOne: UILabel?
    @IBOutlet var addressLineTwo: UILabel?
    @IBOutlet var addressLineThree: UILabel?
    @IBOutlet var distanceLabel: UILabel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addressLineOne?.text = ""
        addressLineTwo?.text = ""
        addressLineThree?.text = ""
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addressLineOne?.text = ""
        addressLineTwo?.text = ""
        addressLineThree?.text = ""
    }

    func addAddressData(addressData: [String]) {
        if(addressData.count == 3) {
            addressLineOne?.text = addressData[0]
            addressLineTwo?.text = addressData[1]
            addressLineThree?.text = addressData[2]
        } else {
            addressLineOne?.text = ""
            addressLineTwo?.text = ""
            addressLineThree?.text = ""
        }
    }

    func setDistance(distance: Double) {
        distanceLabel?.text = "\(distance)mi"
    }

    func addMapPoint(annotation: MKPointAnnotation) {
        let center = annotation.coordinate

        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006))
        self.mapView?.addAnnotation(annotation)
        self.mapView?.setRegion(region, animated: true)
        self.mapView?.isUserInteractionEnabled = false
    }
}
