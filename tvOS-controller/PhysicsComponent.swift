//
//  PhysicsComponent.swift
//  tvOS-controller
//
//  Created by Lauren Brown on 12/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import SceneKit

//TODO: for proper game object and update integration

class PhysicsComponent {
    
    //MARK: variables
    var initialVelocity = SCNVector3(0,0,0)
    var currentVelocity = SCNVector3(0,0,0)
    var acceleration : Float = 0.0
    var mass : Float = 0.0
    var position = SCNVector3(0, 0, 0)
    var orientation = SCNQuaternion()
    
    //MARK: Constants
    let maxAccel : Float = 10.0
    let maxSpeed : Float = 60.0
    
    init() {
        
    }
    
    init(v1 : SCNVector3, mass : Float) {
        self.currentVelocity  = v1
        self.mass = mass
    }
    
    func update(delta: Float) {
        //todo link this up
    }
    
    func UpdateAcceleration(accel : Int){
        if acceleration + Float(accel) <= maxAccel {
            acceleration += Float(accel)
        } else {
            acceleration = maxAccel
        }
        
    }
    
    
}

struct GameObject {
    //data attached to each game object in the world
    var sceneNode = SCNNode()
    let physicsNode = PhysicsComponent()
    //AI component?
    //any game logic
    var ID : Int = 0
    //device ID to be used for multiplayer
    var playerID : String = ""
}