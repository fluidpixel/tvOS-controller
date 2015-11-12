//
//  CarNode.swift
//  tvOS-controller
//
//  Created by Paul Jones on 12/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import SceneKit
//AudiCoupe.dae

let CG_PI = CGFloat(M_PI)
let F_PI = Float(M_PI)

func + (l:SCNVector3, r:SCNVector3) -> SCNVector3 {
    return SCNVector3(l.x + r.x, l.y + r.y, l.z + r.z)
}
func - (l:SCNVector3, r:SCNVector3) -> SCNVector3 {
    return SCNVector3(l.x - r.x, l.y - r.y, l.z - r.z)
}



