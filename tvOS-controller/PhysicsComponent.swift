//
//  PhysicsComponent.swift
//  tvOS-controller
//
//  Created by Lauren Brown on 12/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import SceneKit

struct GameObject {
    //data attached to each game object in the world
    init() {
        
    }
    
    var sceneNode = SCNNode()
    var physicsVehicle = SCNPhysicsVehicle()
    var colourID : Int = 0
    var points : Int = 0
    var kills : Int = 0
    var playerLastKilledBy : String? = nil
    //AI component?
    //any game logic
    var ID : Int = 0
    //device ID to be used for multiplayer
    var playerID : String? = nil
    
    func GetColour(i : Int) -> UIColor {
        
        switch i {
        case 0:
            return UIColor.blackColor()
        case 1:
            return UIColor.lightGrayColor()
        case 2:
            return UIColor.redColor()
        case 3:
            return UIColor.greenColor()
        case 4:
            return UIColor.blueColor()
        case 5:
            return UIColor.yellowColor()
        case 6:
            return UIColor.magentaColor()
        case 7:
            return UIColor.orangeColor()
        case 8:
            return UIColor.purpleColor()
        default:
            return UIColor.whiteColor()
        }
    }
}