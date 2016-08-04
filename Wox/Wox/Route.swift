//
//  Route.swift
//  Wox
//
//  Created by Matthew Bordas on 11/24/15.
//  Copyright © 2015 Undecided. All rights reserved.
//

import Foundation
import MapKit
import UIKit

// A single polyline
class Route {
    
    var steps = [CLLocationCoordinate2D]()
    
    init(filename: String) {
        
        let filePath = NSBundle.mainBundle().pathForResource(filename, ofType: nil)!
        do {
            let docstring = try String(contentsOfFile: filePath, encoding: NSUTF8StringEncoding)
            let rows = docstring.componentsSeparatedByString("\r")
            print(rows.count)
            print(rows[0])
            
            for col in rows {
                if col != "\n" {
                    let pair = col.componentsSeparatedByString(",")
                    let points = "{\(pair[0]),\(pair[1])}"
                    let p = CGPointFromString(points)
                    steps += [CLLocationCoordinate2DMake(CLLocationDegrees(p.x), CLLocationDegrees(p.y))]
                }
            }
        }
        catch {
            print("FUCK")
        }
    }
}
