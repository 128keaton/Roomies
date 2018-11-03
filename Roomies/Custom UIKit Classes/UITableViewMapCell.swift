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

class UITableViewMapCell: UITableViewCell{
    @IBOutlet var mapView: MKMapView?
    var annotation: MKPointAnnotation?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addMapPoint(){
        let center = annotation?.coordinate
        let region = MKCoordinateRegion(center: center!, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        self.mapView?.addAnnotation(annotation!)
        self.mapView?.setRegion(region, animated: true)
    }
}
