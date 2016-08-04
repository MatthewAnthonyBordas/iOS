//
//  Pin.swift
//  Wox
//
//  Created by Matthew Bordas on 11/24/15.
//  Copyright © 2015 Undecided. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Pin: NSObject, MKAnnotation {
    let title: String?
    let locationName: String?
    let coordinate: CLLocationCoordinate2D
    var score = 0
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        
        super.init()
    }
    
    var subtitle: String? {
        return locationName
    }
    
}