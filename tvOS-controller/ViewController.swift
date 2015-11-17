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

class ViewController: UIViewController, TVCTVSessionDelegate, SCNSceneRendererDelegate  {
    
    @IBOutlet var messageArea: UILabel!
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    
    @IBOutlet var button3: UIButton!
    
    @IBOutlet weak var accelView: SCNView!
    
    @IBOutlet weak var messageView: UITextView!
    let remote = TVCTVSession()
    
    @IBOutlet weak var DrawCanvas : UIImageView!
    
    var gameObjects = [GameObject]()
    var timer = NSTimer()
    
    //vehicles
    var vehicle: SCNPhysicsVehicle?

    var vectorToMoveBy = SCNVector3(0, 0, 1)
    var firstRun = true
    var initialTime = 0.0
    var numberOfPlayers = 4
    //testing
    let angle = sin(M_PI_4 / 2.0)
    
    //scene nodes
    let cameraNode = SCNNode()
    let lightNode = SCNNode()
    var groundNode = SCNNode()
    var carNode = SCNNode()
    var trackNode = SCNNode()
    //boxes
    var boxNode = SCNNode()
    var boxNode2 = SCNNode()
    
    //update variables
    var accel : Float = 0.0
    var speed : Float = 0.0
    var previousOrientation = SCNQuaternion()
    var glkRepresentation = GLKQuaternion()
    var slerp = 0.0
    var isSlerping = false
    
    //y, p, r variables
    var intialYPR : [Float] = [0.0,0.0,0.0]
    var currentYPR : [Float] = [0.0,0.0,0.0]
    
    // draw
    var lastPoint = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.remote.delegate = self
        accelView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        prepareScene()
        accelView.play(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        //called first, any pre-render game logic here
    }
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {
        
        //physics updates here
        
        //print(time)
        if firstRun {
            //time zero
            updateCar(0.0)
            initialTime = time
            firstRun = false
        } else {
            updateCar((time - initialTime))
            initialTime = time
        }
    }
    
    func updateCar(delta: NSTimeInterval) {
        
        //move car in the direction it is currently facing

        carNode.runAction(SCNAction.moveByX(CGFloat(vectorToMoveBy.x * Float(delta) * (accel)), y: 0.0, z: CGFloat(vectorToMoveBy.z * Float(delta) * (accel)), duration: delta))
        speed = vectorToMoveBy.magnitudeSquared()
        cameraNode.position = SCNVector3(carNode.position.x + 10, carNode.position.y + 10, carNode.position.z)
//        if isSlerping {
//            slerp += delta
//            
//            var slerpAmount = slerp / 1.0
//            
//            if slerpAmount > 1.0 {
//                slerpAmount = 1.0
//                isSlerping = false
//            }
//            
           // let tempGLK = GLKQuaternionMake(carNode.orientation.x, carNode.orientation.y, carNode.orientation.z, carNode.orientation.w)
            
           // let result = GLKQuaternionSlerp(tempGLK, glkRepresentation, Float(slerpAmount))
            
            //carNode.orientation.y = result.y
            
            //let angle = tempGLK.AngleFromQuaternion(result)
        
            let angle = (currentYPR[0]) //pitch
            
            carNode.runAction((SCNAction.rotateByAngle(CGFloat(angle * Float(delta)), aroundAxis: SCNVector3(0, 1, 0), duration: delta)), completionHandler: { () -> Void in
                self.intialYPR = self.currentYPR
            })
            
            let matrix = SCNMatrix4MakeRotation((angle  * Float(delta)), 0, 1, 0)
            
            vectorToMoveBy = vectorToMoveBy.multiplyByMatrix4(matrix)
        
           // intialYPR = [carNode.eulerAngles.x, carNode.eulerAngles.y, carNode.eulerAngles.z]

            //let temp = GLKQuaternionRotateVector3(result, GLKVector3(v: (vectorToMoveBy.x, vectorToMoveBy.y, vectorToMoveBy.z)))
            //vectorToMoveBy = SCNVector3(temp.x, temp.y, temp.z)
            
       // }
    }
    
    func prepareScene(){
        
        accelView.scene = SCNScene()
        accelView.scene!.physicsWorld.gravity = SCNVector3(x: 0.0, y: -9.8, z: 0.0)
        //camera
        let camera = SCNCamera()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(-10.0, 10.0, 10.0)
        
        let ambientLight = SCNLight()
        ambientLight.type = SCNLightTypeAmbient
        ambientLight.color = UIColor(red: 0.5, green: 0.5, blue: 0.0, alpha: 1.0)
        cameraNode.light = ambientLight
        
        //light
        
        let light = SCNLight()
        light.type = SCNLightTypeDirectional
        light.castsShadow = true
        
        lightNode.light = light
        lightNode.position = SCNVector3(x: 1.5, y: 1.5, z: 1.5)
        
//        //object
//        let carScene : SCNScene = SCNScene(named: "gameAssets.scnassets/AudiCoupe.dae")!
//        
//        if let tempNode = carScene.rootNode.childNodeWithName("Car", recursively: true){
//            carNode = tempNode
//            carNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
//            if carNode.geometry == nil {
//                carNode.geometry = SCNBox(width: 1.0, height: 1.0, length: 2.0, chamferRadius: 0.0)
//            }
//            let physicsShape = SCNPhysicsShape(geometry: carNode.geometry!, options: nil)
//            let physicsBody = SCNPhysicsBody(type: .Dynamic, shape: physicsShape)
//            carNode.physicsBody = physicsBody
//            
//            accelView.scene!.rootNode.addChildNode(carNode)
//            
//            //let axisNode = SCNNode()
//        }else {
//            print("Could not load car")
//        }
        
        //add some placed boxes
        let box = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.redColor()
        box.materials = [boxMaterial]
        boxNode.position = SCNVector3(x: 5.0, y: 0.0, z: 5.0)
        let physicsBox = SCNPhysicsShape(geometry: box, options: nil)
        let boxBody = SCNPhysicsBody(type: .Static, shape: physicsBox)
        boxNode = SCNNode(geometry: box)
        boxNode.physicsBody = boxBody
        boxNode2 = boxNode
        boxNode2.position = SCNVector3(x: 1.0, y: 0.0, z: 1.0)
        
        //accelView.scene!.rootNode.addChildNode(boxNode)
        //accelView.scene!.rootNode.addChildNode(boxNode2)
        
        //track
        setupTrack()
        setupPlayers()
        
        //ground
        let ground = SCNFloor()
        ground.reflectivity = 0
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIColor.blueColor()
        let physicsShape = SCNPhysicsShape(geometry: SCNFloor(), options: nil)
        let body = SCNPhysicsBody(type: .Static, shape: physicsShape)
        ground.materials = [groundMaterial]
        groundNode = SCNNode(geometry: ground)
        groundNode.physicsBody = body
        
        groundNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
        previousOrientation = groundNode.orientation
        
        accelView.scene!.rootNode.addChildNode(cameraNode)
        accelView.scene!.rootNode.addChildNode(lightNode)

        accelView.scene!.rootNode.addChildNode(groundNode)
        
        
    }
    
    func setupPlayers() {
        //four 'players'
        for (var i = 0; i < numberOfPlayers; i++) {
            if let carScene : SCNScene = SCNScene(named: "gameAssets.scnassets/rc_car.dae") {
                
                if let chassisNode : SCNNode = carScene.rootNode.childNodeWithName("rccarBody", recursively: false) {
                    
                    chassisNode.position = SCNVector3Make(Float(i * 10), 10.0, 0)
                    chassisNode.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
                    
                    
                    if chassisNode.geometry?.materials != nil {
                        chassisNode.geometry!.materials[0].diffuse.contents = setPlayerColours(i)
                    }
                    
                    let body : SCNPhysicsBody = SCNPhysicsBody.dynamicBody()
                    body.allowsResting = false
                    body.mass = 80
                    body.restitution = 0.1
                    body.friction = 0.5
                    body.rollingFriction = 0
                    
                    chassisNode.physicsBody = body
                    accelView.scene!.rootNode.addChildNode(chassisNode)
                    
                    //wheels
                    
                    if let wheelNode1 : SCNNode = chassisNode.childNodeWithName("wheelLocator_FL", recursively: true) {
                        if let wheelNode2 : SCNNode = chassisNode.childNodeWithName("wheelLocator_FR", recursively: true) {
                            if let wheelNode3 : SCNNode = chassisNode.childNodeWithName("wheelLocator_RL", recursively: true) {
                                if let wheelNode4 : SCNNode = chassisNode.childNodeWithName("wheelLocator_RR", recursively: true) {
                                    
                                    let wheel1 = SCNPhysicsVehicleWheel(node: wheelNode1)
                                    let wheel2 = SCNPhysicsVehicleWheel(node: wheelNode2)
                                    let wheel3 = SCNPhysicsVehicleWheel(node: wheelNode3)
                                    let wheel4 = SCNPhysicsVehicleWheel(node: wheelNode4)
                                    
                                    var min = SCNVector3Zero
                                    var max = SCNVector3Zero
                                    
                                    wheelNode1.getBoundingBoxMin(&min, max: &max)
                                    let wheelHalfWidth : Float = (Float(0.5) * (max.x - min.x))
                                    
                                    wheel1.connectionPosition =
                                        wheelNode1.convertPosition(SCNVector3Zero, toNode: chassisNode) + SCNVector3(wheelHalfWidth, 0.0, 0.0)
                                    wheel2.connectionPosition =
                                        wheelNode2.convertPosition(SCNVector3Zero, toNode: chassisNode) - SCNVector3(wheelHalfWidth, 0.0, 0.0)
                                    wheel3.connectionPosition =
                                        wheelNode3.convertPosition(SCNVector3Zero, toNode: chassisNode) + SCNVector3(wheelHalfWidth, 0.0, 0.0)
                                    wheel4.connectionPosition =
                                        wheelNode4.convertPosition(SCNVector3Zero, toNode: chassisNode) - SCNVector3(wheelHalfWidth, 0.0, 0.0)
                                    
                                    let vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!, wheels: [wheel1, wheel2, wheel3, wheel4])
                                    
                                    accelView.scene?.physicsWorld.addBehavior(vehicle)
                                    
                                    self.vehicle = vehicle
                                    
                                    var gameobject = GameObject()
                                    gameobject.sceneNode = chassisNode
                                    gameobject.ID = i
                                    gameobject.physicsVehicle = vehicle
                                    
                                    gameObjects.append(gameobject)
                                    
                                    //constraints
                                    
                                    let constraint = SCNLookAtConstraint(target: gameObjects[0].sceneNode)
                                    
                                    cameraNode.constraints = [constraint]
                                    lightNode.constraints = [constraint]
                                    
                                }
                            }
                        }
                    }
                }
     
            }
        }
        
    }
    
    func setupTrack() {
        if let trackScene : SCNScene = SCNScene(named: "gameAssets.scnassets/BasicTrack.dae") {
            if let tempNode  = trackScene.rootNode.childNodeWithName("BezierCircle", recursively: true) {
                trackNode = tempNode
                
                trackNode.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
                //trackNode.scale = SCNVector3(5, 1, 5)
                let geometry = trackNode.geometry
                let shape = SCNPhysicsShape(geometry: geometry!, options: nil)
                
                let body = SCNPhysicsBody(type: .Kinematic, shape: shape)
                
                trackNode.physicsBody = body
                
                accelView.scene?.rootNode.addChildNode(trackNode)
            }
            
            
        }
    }
    
    func setPlayerColours( i : Int) -> UIColor {
        switch i {
        case 0:
            return UIColor.redColor()
        case 1:
            return UIColor.yellowColor()
        case 2:
            return UIColor.greenColor()
        case 3:
            return UIColor.blueColor()
        default:
            return UIColor.blackColor()
        }
    }
    
    @IBAction func button1Pressed() {
        sendButtonPressed("Button 1")
        DrawCanvas.hidden = true
       // messageView.hidden = false
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
        var foundPlayerFromDevice = -1
        //link device to player
        for (var i = 0; i < gameObjects.count && foundPlayerFromDevice == -1; i++ ){
            
            if gameObjects[i].playerID == nil { //no device ID
                gameObjects[i].playerID = fromDevice
                foundPlayerFromDevice = i
            } else if gameObjects[i].playerID == fromDevice {
                foundPlayerFromDevice = i
            }
        }
        
        print("Device \(fromDevice) is attached to Player \(foundPlayerFromDevice)")
        
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
            
            
            let tempValue = message.values.first as! [Float]
            
            //check for change first
            
            //quaternions
            if tempValue.count == 4 {
            if (abs(previousOrientation.x - tempValue[0]) > 0.01 || abs(previousOrientation.y - tempValue[1]) > 0.01 || abs(previousOrientation.z - tempValue[2]) > 0.01) && !previousOrientation.isZero() {
                
                glkRepresentation = GLKQuaternionMake(tempValue[0], tempValue[1], tempValue[2], tempValue[3])
                print("rotate by  \(tempValue)")
                previousOrientation = SCNVector4(x: tempValue[0], y: tempValue[1], z: tempValue[2], w: tempValue[3])
                isSlerping = true
                
            }else if previousOrientation.isZero() {
                
                previousOrientation = SCNVector4(x: tempValue[0], y: tempValue[1], z: tempValue[2], w: tempValue[3])
                }
            }
            
            //yaw/pitch/roll
            if tempValue.count == 3 {
                if (abs(intialYPR[0] - tempValue[0]) > 0.01 || abs(intialYPR[1] - tempValue[1]) > 0.01 || abs(intialYPR[2] - tempValue[2]) > 0.01) && intialYPR != [0.0, 0.0,0.0]{
                
                    print("pitch : \(tempValue[0]), yaw: \(tempValue[1]), roll: \(tempValue[2])")
                    
                    currentYPR = tempValue
                    
                } else if intialYPR == [0.0, 0.0,0.0]{
                    intialYPR = tempValue
                    currentYPR = tempValue
                }
                
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
        }else if message.keys.first == "Speed" {
            
            //increase acceleration
            let value = (message.values.first as! Float)
            accel += value
            //this will be redone when integrated w/ the physics
            if message.values.first as! Int == 0 {
                
            }else if accel < -50 {
                accel = -50
            } else if accel > 50 {
                accel = 50
            }
            
            //timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: Selector("OnTimerFired"), userInfo: nil, repeats: true)
            
        }
        replyHandler(["Reply": speed])
    }
    func deviceDidConnect(device: String) {
        self.write("Connected: \(device)")
    }
    func deviceDidDisconnect(device: String) {
        self.write("Disconnected: \(device)")
    }
    
    private func OnTimerFired(accelerating : Bool) {
        
    }
}

func +(l: SCNVector3, r:SCNVector3) -> SCNVector3 {
    return SCNVector3(l.x + r.x, l.y + r.y, l.z + r.z)
}

func -(l: SCNVector3, r:SCNVector3) -> SCNVector3 {
    return SCNVector3(l.x - r.x, l.y - r.y, l.z - r.z)
}

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


