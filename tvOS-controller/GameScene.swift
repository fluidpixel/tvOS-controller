////
////  GameScene.swift
////  tvOS-controller
////
////  Created by Lauren Brown on 06/11/2015.
////  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
////
//
//import Foundation
//import UIKit
//import SceneKit
//
//class GameScene : UIViewController, TVCTVSessionDelegate {
//    
//    @IBOutlet weak var Scene: SCNView!
//    let remote = TVCTVSession()
//    let world = SCNScene()
//
//    //scene nodes
//    let cameraNode = SCNNode()
//    let lightNode = SCNNode()
//    var planeNode = SCNNode()
//    var sphereNode = SCNNode()
//    
//    var startOrientation : [Float] =
//    
//    var firstRun = true
//    var initialTime = 0.0
//    //testing
//    let angle = sin(M_PI_4 / 2.0)
//    
//    //update variables
//    var previousOrientation = SCNQuaternion()
//    var glkRepresentation = GLKQuaternion()
//    var slerp = 0.0
//    var isSlerping = false
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        
//        setUpScene()
//        //Scene.delegate = self
//        remote.delegate = self
//        //initial loading of objects
//    }
//    
//
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    func setUpScene() {
//        
//        
//        if Scene != nil {
//            let scene = SCNScene()
//            Scene.scene = scene
//            
//            if Scene.scene!.paused != true {
//                let camera = SCNCamera()
//                let cameraNode = SCNNode()
//                cameraNode.camera = camera
//                cameraNode.position = SCNVector3(x : -3.0, y: 3.0, z: 25.0)
//                
//                let ambient = SCNLight()
//                ambient.type = SCNLightTypeAmbient
//                ambient.color = UIColor(red: 0.5, green: 0.5, blue: 0.2, alpha: 1.0)
//                cameraNode.light = ambient
//                
//                let light = SCNLight()
//                light.type = SCNLightTypeSpot
//                light.spotInnerAngle = 30.0
//                light.spotOuterAngle = 80.0
//                light.castsShadow = true
//                let lightNode = SCNNode()
//                lightNode.light = light
//                lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
//                
//                let sphere = SCNSphere(radius: 1.0)
//                let sphereMaterial = SCNMaterial()
//                sphereMaterial.diffuse.contents = UIColor.yellowColor()
//                sphere.materials = [sphereMaterial]
//                sphereNode = SCNNode(geometry: sphere)
//                
//                let plane = SCNPlane(width: 20.0, height: 20.0)
//                let planeMaterial = SCNMaterial()
//                planeMaterial.diffuse.contents = UIColor.blueColor()
//                plane.materials = [planeMaterial]
//                planeNode = SCNNode(geometry: plane)
//                planeNode.eulerAngles = SCNVector3(x: GLKMathDegreesToRadians(-90), y: 0, z: 0)
//                planeNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
//                startorientation = planeNode.orientation
//                
//                //physics
//                let planeShape = SCNPhysicsShape(geometry: plane, options: nil)
//                let planeBody = SCNPhysicsBody(type: .Kinematic, shape: planeShape)
//                planeNode.physicsBody = planeBody
//                //planeNode.pivot = SCNMatrix4MakeTranslation(25.0, 0.0, 25.0)
//                
//                let gravity = SCNPhysicsField.radialGravityField()
//                gravity.strength = 0
//                sphereNode.physicsField = gravity
//                
//                let sphereShape = SCNPhysicsShape(geometry: sphere, options: nil)
//                let sphereBody = SCNPhysicsBody(type: .Static, shape: sphereShape)
//                sphereNode.physicsBody = sphereBody
//                
//                let constraint = SCNLookAtConstraint(target: planeNode)
//                constraint.gimbalLockEnabled = true
//                cameraNode.constraints = [constraint]
//                lightNode.constraints = [constraint]
//                
//                scene.rootNode.addChildNode(lightNode)
//                scene.rootNode.addChildNode(cameraNode)
//                scene.rootNode.addChildNode(sphereNode)
//                scene.rootNode.addChildNode(planeNode)
//            }
//        }
//    }
//    
//
//    
//    //MARK: message functionality
//    func didReceiveMessage(message: [String : AnyObject], fromDevice: String) {
//        print("Received message: \(message) - from Device: \(fromDevice)")
//    }
//    
//    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void) {
//        //handle stuff here
//        
//        didReceiveMessage(message, fromDevice: fromDevice)
//        
//        if message.keys.first == "Accelerometer" {
//            
//            
//            let tempValue = message.values.first as! [Float]
//            
//            //check for change first
//            if (abs(previousOrientation.x - tempValue[0]) > 0.01 || abs(previousOrientation.y - tempValue[1]) > 0.01 || abs(previousOrientation.z - tempValue[2]) > 0.01) && !previousOrientation.isZero() {
//                
//                    glkRepresentation = GLKQuaternionMake(tempValue[0], tempValue[1], tempValue[2], tempValue[3])
//                    print("rotate by  \(tempValue)")
//                    previousOrientation = SCNVector4(x: tempValue[0], y: tempValue[1], z: tempValue[2], w: tempValue[3])
//                    isSlerping = true
//
//            }else if previousOrientation.isZero() {
//                
//                previousOrientation = SCNVector4(x: tempValue[0], y: tempValue[1], z: tempValue[2], w: tempValue[3])
//            }
//        }
//        
//    }
//    
//    func deviceDidConnect(device: String) {
//        print("Connected to: \(device)")
//    }
//    
//    func deviceDidDisconnect(device: String) {
//        print("Disconnected from: \(device)")
//    }
//    
//}
//
