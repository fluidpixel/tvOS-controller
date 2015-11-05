//
//  ViewController.swift
//  tvOS-controller
//
//  Created by Paul Jones on 02/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class ViewController: UIViewController, TVCTVSessionDelegate {
    
    @IBOutlet var messageArea: UILabel!
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    
    @IBOutlet var button3: UIButton!
    
    @IBOutlet weak var accelView: SCNView!
    
    @IBOutlet weak var messageView: UITextView!
    let remote = TVCTVSession()
    
    @IBOutlet weak var DrawCanvas : UIImageView!
    //rotation
    var accelData : [Float] = [0.0, 0.0, 0.0, 0.0]
    var planeNode = SCNNode()
    var sphereNode = SCNNode()
    var startorientation = SCNVector4()
    
    // draw
    var lastPoint = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remote.delegate = self
       
        // Do any additional setup after loading the view, typically from a nib.
        
        prepareScene()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func prepareScene(){
        
        let scene = SCNScene()
        accelView.scene = scene
        
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x : -3.0, y: 3.0, z: 25.0)
        
        let ambient = SCNLight()
        ambient.type = SCNLightTypeAmbient
        ambient.color = UIColor(red: 0.5, green: 0.5, blue: 0.2, alpha: 1.0)
        cameraNode.light = ambient
        
        let light = SCNLight()
        light.type = SCNLightTypeSpot
        light.spotInnerAngle = 30.0
        light.spotOuterAngle = 80.0
        light.castsShadow = true
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
        
        let sphere = SCNSphere(radius: 1.0)
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.yellowColor()
        sphere.materials = [sphereMaterial]
        sphereNode = SCNNode(geometry: sphere)
        
        let plane = SCNPlane(width: 20.0, height: 20.0)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.blueColor()
        plane.materials = [planeMaterial]
        planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles = SCNVector3(x: GLKMathDegreesToRadians(-90), y: 0, z: 0)
        planeNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
        startorientation = planeNode.orientation
        
        //physics
        let planeShape = SCNPhysicsShape(geometry: plane, options: nil)
        let planeBody = SCNPhysicsBody(type: .Kinematic, shape: planeShape)
        planeNode.physicsBody = planeBody
        //planeNode.pivot = SCNMatrix4MakeTranslation(25.0, 0.0, 25.0)
        
        let gravity = SCNPhysicsField.radialGravityField()
        gravity.strength = 0
        sphereNode.physicsField = gravity
        
        let sphereShape = SCNPhysicsShape(geometry: sphere, options: nil)
        let sphereBody = SCNPhysicsBody(type: .Static, shape: sphereShape)
        sphereNode.physicsBody = sphereBody
        
        let constraint = SCNLookAtConstraint(target: planeNode)
        constraint.gimbalLockEnabled = true
        cameraNode.constraints = [constraint]
        lightNode.constraints = [constraint]
        
        scene.rootNode.addChildNode(lightNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(sphereNode)
        scene.rootNode.addChildNode(planeNode)

    }
    
    func rotatePlane(values : [Float]?) {
        if values != nil {
            
            let orientation = startorientation
            let quat = GLKQuaternionMultiply(GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w), GLKQuaternionMake(values![0], values![1], values![2], values![3]))
            
            planeNode.orientation = SCNVector4Make(quat.x , quat.y, quat.z, quat.w)
            //planeNode.runAction(SCNAction.rotateToX(CGFloat(values![0]), y: CGFloat(values![1]), z: CGFloat(-values![2]), duration: 0.2))
        }else {
            write("Core motion data is nil")
        }
    }
    
    @IBAction func button1Pressed() {
        sendButtonPressed("Button 1")
        DrawCanvas.hidden = true
        messageView.hidden = false
    }
    
    @IBAction func button2Pressed() {
        sendButtonPressed("Button 2")
        DrawCanvas.hidden = false
        messageView.hidden = true
    }
    @IBAction func button3Pressed() {
        sendButtonPressed("Button 3")
    }
    
    private func sendButtonPressed(buttonText:String) {
        self.write(buttonText)
        remote.broadcastMessage(["ButtonPressed":buttonText], replyHandler: {
            (deviceID:String, reply:[String : AnyObject]) -> Void in
            
            self.write("Reply from \(deviceID) - \(reply)")
            
            }) {
                (error) -> Void in
                self.write("Error \(error)")
        }
    }
    
    private func write(line:String) {
        dispatch_async(dispatch_get_main_queue()) {
            let existingText = self.messageView.text!
            self.messageView.text = "\(existingText)\n\(line)"
        }
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        
        UIGraphicsBeginImageContext(DrawCanvas.frame.size)
        let context = UIGraphicsGetCurrentContext()
        DrawCanvas.image?.drawInRect(CGRect(x : 0 , y: 0, width: DrawCanvas.frame.size.width, height: DrawCanvas.frame.size.height))
        
        CGContextMoveToPoint(context, fromPoint.x, fromPoint.y)
        CGContextAddLineToPoint(context, toPoint.x, toPoint.y)
        
        CGContextSetLineCap(context, CGLineCap.Round)
        CGContextSetLineWidth(context, 5.0)
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0)
        CGContextSetBlendMode(context, CGBlendMode.Normal)
        
        CGContextStrokePath(context)
        
        DrawCanvas.image = UIGraphicsGetImageFromCurrentImageContext()
        DrawCanvas.alpha = 1.0
        UIGraphicsEndImageContext()
        
    }
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String) {
        self.write("Message received: \(message) from: \(fromDevice)")
    }
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void) {
        self.didReceiveMessage(message, fromDevice: fromDevice)
        //detect which form of data is being sent over
        if message.keys.first == "Button" {
            
            switch message.values.first! as! Int {
            case 1:
                button1Pressed()
                break
            case 2:
                button2Pressed()
                break
            case 3:
                button3Pressed()
                break
            default:
                break
            }
            
        }else if message.keys.first == "Accelerometer" {
            
            let temp = message.values.first as! [Float]
            //check for change first
            if (abs(accelData[0] - temp[0]) > 0.01 || abs(accelData[1] - temp[1]) > 0.01 || abs(accelData[2] - temp[2]) > 0.01) && accelData != [0.0,0.0,0.0,0.0] {
                
                print("rotate by  \(temp)")
                rotatePlane(message.values.first as? [Float])
                accelData = message.values.first as! [Float]
            }else if accelData == [0.0,0.0,0.0, 0.0] {
                
                accelData = message.values.first as! [Float]
            }
        } else if message.keys.first == "DrawBegin" {
            
            let temp = message.values.first as! [Float]
            lastPoint = CGPoint(x: CGFloat(temp[0]), y: CGFloat(temp[1]))
            
        } else if message.keys.first == "DrawMove" {
            
            let temp = message.values.first as! [Float]
            let currentPoint = CGPoint(x: CGFloat(temp[0]), y: CGFloat(temp[1]))
            
            drawLineFrom(lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        } else if message.keys.first == "DrawEnd" {
            
            drawLineFrom(lastPoint, toPoint: lastPoint)
        }
        replyHandler(["Reply":false])
    }
    func deviceDidConnect(device: String) {
        self.write("Connected: \(device)")
    }
    func deviceDidDisconnect(device: String) {
        self.write("Disconnected: \(device)")
    }
}

