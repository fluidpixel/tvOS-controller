//
//  Extensions.swift
//  tvOS-controller
//
//  Created by Paul Jones on 17/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import SceneKit
import GLKit


extension SCNQuaternion {
    
    /**
     Checks for empty/all zero quaternions
     
     - Returns: returns true if Quaternion is all zero
     */
    func isZero() -> Bool {
        if self.x == 0.0 && self.y == 0.0 && self.z == 0.0 && self.w == 0.0 {
            return true
        } else {
            return false
        }
    }
    
}

extension SCNVector3 {
    
    func multiplyByMatrix4(mat4: SCNMatrix4) -> SCNVector3 {
        
        return SCNVector3(
            self.x * mat4.m11 + self.y * mat4.m21 + self.z * mat4.m31,
            self.x * mat4.m12 + self.y * mat4.m22 + self.z * mat4.m32,
            self.x * mat4.m13 + self.y * mat4.m23 + self.z * mat4.m33)
    }
    
    func magnitudeSquared() -> Float {
        return ((self.x * self.x) + (self.y * self.y) + (self.z + self.z))
    }
}

extension GLKQuaternion {
    
    
    /**
     Finds the angle between two quaternions
     
     - Returns: returns the angle in radians
     
     */
    func AngleFromQuaternion(quat : GLKQuaternion) -> Float {
        let inv = GLKQuaternionInvert(self)
        
        let result = GLKQuaternionMultiply(quat, inv)
        
        let angle = acosf(result.w) * 2.0
        
        if angle > Float(M_PI_2) {
            
            return (Float(M_PI) - angle)
        } else {
            return angle
        }
        
    }
}


