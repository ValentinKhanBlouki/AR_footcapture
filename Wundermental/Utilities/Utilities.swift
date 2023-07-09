//
//  Utilities.swift
//  Wundermental
//
//  Created by Nicolas Walter on 20.05.23.
//

import Foundation
import SceneKit

// Convenience accessors for Asset Catalog named colors.
extension UIColor {
    static let WYellow = UIColor(named: "WYellow")!
    static let WGrey = UIColor(named: "WGrey")!
    static let WBlue = UIColor(named: "WBlue")!
    static let WGreen = UIColor(named: "WGreen")!
    static let WGreenDark = UIColor(named: "WGreenDark")!
    static let WLightBlue = UIColor(named: "WLightBlue")!
    static let WLightRed = UIColor(named: "WLightRed")!
}

class Instructions {
    static let placeDome = Message("Tap to place the dome. Tap again or hold to change the position. Pinch to increase/decrease the size. Press Next to continue.", title: "Place Dome")
    
    static let scanObject = Message("Move around the dome until every surface is yellow to scan the object.", title: "Scan Object")
    
    static let detailPhotos = Message("Now take some detail photos (e.g. the woundsurface)", title: "Detail Photos")
    
    static let finish = Message("Good job! You finished the scan. You can tap on the share button to send it to other devices or start a new scan.", title: "Finish & Share")
}

class Errors {
    static let domeNotPlace = Message("Please place the dome before you continue", title: "No Dome placed")
    
    static let domePlaceNoSurface = Message("Object could not be placed, try again.", title: "No surface found")
    
}
