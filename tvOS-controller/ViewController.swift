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
import GameController
import GameplayKit

class ViewController: UIViewController, TVCTVSessionDelegate, SCNSceneRendererDelegate  {
    
    @IBOutlet var messageArea: UILabel!
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    
    @IBOutlet var button3: UIButton!
    
    @IBOutlet weak var accelView: SCNView!
    
    @IBOutlet weak var messageView: UITextView!
    let remote = TVCTVSession()
    
    @IBOutlet weak var DrawCanvas : UIImageView!
    
    @IBOutlet var speed: UILabel!
    var prevSpeed:Int = 0
    
    var gameObjects = [GameObject]()
    var timer = NSTimer()

    var vectorToMoveBy = SCNVector3(0, 0, 1)
    var firstRun = true
    var initialTime = 0.0
    //testing
    let angle = sin(M_PI_4 / 2.0)
    
    //scene nodes
    let cameraNode = SCNNode()
    let lightNode = SCNNode()
    var groundNode = SCNNode()
    var carNode = SCNNode()
    //boxes
    var boxNode = SCNNode()
    var boxNode2 = SCNNode()
    
    //update variables
    //var accel : Float = 0.0
    //var speed : Float = 0.0
    var previousOrientation = SCNQuaternion()
    //var glkRepresentation = GLKQuaternion()
    var slerp = 0.0
    var isSlerping = false
    
    //y, p, r variables
    var intialYPR : [Float] = [0.0,0.0,0.0]
    var currentYPR : [Float] = [0.0,0.0,0.0]
    
    // draw
    var lastPoint = CGPoint.zero
    
    
    var acceleration:CGFloat = 0.0
    var brake:CGFloat = 0.0
    
    
    var notes:[AnyObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.remote.delegate = self
        accelView.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        prepareScene()
        accelView.play(nil)
        
        notes.append(NSNotificationCenter.defaultCenter().addObserverForName(GCControllerDidConnectNotification, object: nil, queue: nil,
            usingBlock: {
            [weak self] (note) -> Void in
                if let newController = note.object as? GCController {
                    self?.controllerDidConnect(newController)
                }
        }))
        notes.append(NSNotificationCenter.defaultCenter().addObserverForName(GCControllerDidDisconnectNotification, object: nil, queue: nil,
            usingBlock: {
                [weak self] (note) -> Void in
                if let oldController = note.object as? GCController {
                    self?.controllerDidDisconnect(oldController)
                }
        }))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Handle Game Controller Notifications
    func controllerDidConnect(controller:GCController) {
        controller.microGamepad?.valueChangedHandler = self.microGamePadHandler
        
        controller.microGamepad?.buttonA.valueChangedHandler = self.buttonAPressed
        controller.microGamepad?.buttonX.valueChangedHandler = self.buttonXPressed
        
    }
    func controllerDidDisconnect(controller:GCController) {
    }
    
    
    // MARK: SCNSceneRendererDelegate
    func renderer(renderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        
        //called first, any pre-render game logic here
    }
    
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {

        self.vehicle?.applyEngineForce(self.acceleration, forWheelAtIndex: 2)
        self.vehicle?.applyEngineForce(self.acceleration, forWheelAtIndex: 3)
        
        self.vehicle?.applyBrakingForce(self.brake, forWheelAtIndex: 2)
        self.vehicle?.applyBrakingForce(self.brake, forWheelAtIndex: 3)

        let intSpeed = Int((self.vehicle?.speedInKilometersPerHour ?? 0.0) * 100.0 + 0.5)
        if prevSpeed != intSpeed {
            let text = "\(CGFloat(intSpeed) * 0.01) km/h"
            dispatch_async(dispatch_get_main_queue(), {self.speed.text = text})
            prevSpeed = intSpeed
        }
        
    }
    

    
    
    var vehicle:SCNPhysicsVehicle?
    var chassis:SCNNode?
//    var reactor:SCNParticleSystem?
//    var reactorDefaultBirthRate:CGFloat?
    func configureCar() -> SCNNode! {
        
        if let scene = self.accelView.scene {
            
            
            let carScene:SCNScene = SCNScene(named: "gameAssets.scnassets/rc_car")!
            
            let chassisNode:SCNNode = carScene.rootNode.childNodeWithName("rccarBody", recursively: false)!
            chassisNode.position = SCNVector3Make(0, 10, 30)
            chassisNode.rotation = SCNVector4Make(0, 1, 0, F_PI)
            
            let body:SCNPhysicsBody = SCNPhysicsBody.dynamicBody()
            body.allowsResting = false
            body.mass = 80
            body.restitution = 0.1
            body.friction = 0.5
            body.rollingFriction = 0
            
            chassisNode.physicsBody = body
            
            scene.rootNode.addChildNode(chassisNode)
            
//            let pipeNode = chassisNode.childNodeWithName("pipe", recursively: true)
//            self.reactor = SCNParticleSystem(named: "reactor", inDirectory: nil)
//            self.reactorDefaultBirthRate = self.reactor?.birthRate
//            self.reactor?.birthRate = 0
//            pipeNode?.addParticleSystem(self.reactor!)
            
            //add wheels
            let wheel0Node = chassisNode.childNodeWithName("wheelLocator_FL", recursively:true)!
            let wheel1Node = chassisNode.childNodeWithName("wheelLocator_FR", recursively:true)!
            let wheel2Node = chassisNode.childNodeWithName("wheelLocator_RL", recursively:true)!
            let wheel3Node = chassisNode.childNodeWithName("wheelLocator_RR", recursively:true)!
            
            let wheel0 = SCNPhysicsVehicleWheel(node: wheel0Node)
            let wheel1 = SCNPhysicsVehicleWheel(node: wheel1Node)
            let wheel2 = SCNPhysicsVehicleWheel(node: wheel2Node)
            let wheel3 = SCNPhysicsVehicleWheel(node: wheel3Node)
            
            //var minMax = [SCNVector3](2, SCNVector3Zero)
            
            var min = SCNVector3Zero
            var max = SCNVector3Zero
            wheel0Node.getBoundingBoxMin(&min, max: &max)
            let wheelHalfWidth = 0.5 * (max.x - min.x)
            
            wheel0.connectionPosition = wheel0Node.convertPosition(SCNVector3Zero, toNode: chassisNode) + SCNVector3(wheelHalfWidth, 0.0, 0.0)
            wheel1.connectionPosition = wheel1Node.convertPosition(SCNVector3Zero, toNode: chassisNode) - SCNVector3(wheelHalfWidth, 0.0, 0.0)
            wheel2.connectionPosition = wheel2Node.convertPosition(SCNVector3Zero, toNode: chassisNode) + SCNVector3(wheelHalfWidth, 0.0, 0.0)
            wheel3.connectionPosition = wheel3Node.convertPosition(SCNVector3Zero, toNode: chassisNode) - SCNVector3(wheelHalfWidth, 0.0, 0.0)
            
            self.vehicle = SCNPhysicsVehicle(chassisBody: chassisNode.physicsBody!, wheels: [wheel0, wheel1, wheel2, wheel3])
            
            scene.physicsWorld.addBehavior(vehicle!)
            
            return chassisNode;

        }
        else {
            return nil
        }
    }
    
    
    func prepareScene(){
        
        accelView.scene = SCNScene()
        //accelView.scene!.physicsWorld.gravity = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
        //camera
        let camera = SCNCamera()
        cameraNode.camera = camera
        
        
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
        
        self.chassis = configureCar()
        self.chassis?.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
        
        
        // Place some random objects on the scene
        
        let rng = GKARC4RandomSource()
        
        let xy = GKRandomDistribution(randomSource: rng, lowestValue: -200, highestValue: 200)
        let sz = GKRandomDistribution(randomSource: rng, lowestValue: 0, highestValue: 199)
        let obj = GKRandomDistribution(randomSource: rng, lowestValue: 1, highestValue: 3)
        
        let colours = [UIColor.redColor(), UIColor.greenColor(), UIColor.blueColor(), UIColor.yellowColor(), UIColor.orangeColor()]
        let colRNG = GKRandomDistribution(randomSource: rng, lowestValue: 0, highestValue: colours.count - 1)
        
        for _ in 0..<20 {
            
            var geometry:SCNGeometry
            
            switch obj.nextInt() {
            case 1:
                let size = CGFloat(sz.nextUniform()) * 30.0
                geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size * 0.2)
            case 2:
                let sizeA = CGFloat(sz.nextUniform()) * 15.0
                let sizeB = CGFloat(sz.nextUniform()) * 5.0
                geometry = SCNTorus(ringRadius: sizeA + sizeB, pipeRadius: sizeB)
            case 3:
                let sizeA = CGFloat(sz.nextUniform()) * 5.0
                let sizeB = CGFloat(sz.nextUniform()) * 5.0
                geometry = SCNCone(topRadius: 0.0, bottomRadius: sizeA, height: sizeA + sizeB)
            default:
                geometry = SCNSphere(radius: 3.0)
                
            }
            
            
            let node = SCNNode(geometry: geometry)
            
            var min = SCNVector3Zero
            var max = SCNVector3Zero
            geometry.getBoundingBoxMin(&min, max: &max)
            
            geometry.firstMaterial?.diffuse.contents = colours[colRNG.nextInt()]
            
            node.position = SCNVector3(CGFloat(xy.nextUniform()) * 100.0, -CGFloat(min.y) * 2.0, CGFloat(xy.nextUniform()) * 100.0)
            node.physicsBody = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
            
            node.physicsBody?.mass = 10.0
            accelView.scene!.rootNode.addChildNode(node)

            
        }
        
        
        
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
        
        accelView.scene!.rootNode.addChildNode(boxNode)
        accelView.scene!.rootNode.addChildNode(boxNode2)
        
        //ground
        let ground = SCNFloor()
        ground.reflectivity = 0.5
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = "Tile"
        groundMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(10.0, 10.0, 10.0)
        groundMaterial.diffuse.wrapS = .Repeat
        groundMaterial.diffuse.wrapT = .Repeat
        groundMaterial.diffuse.minificationFilter = .Linear
        groundMaterial.diffuse.mipFilter = .Linear
        //groundMaterial.diffuse.magnificationFilter = .Linear
        groundMaterial.diffuse.maxAnisotropy = 8.0
        
        
        let physicsShape = SCNPhysicsShape(geometry: SCNFloor(), options: nil)
        let body = SCNPhysicsBody(type: .Static, shape: physicsShape)
        ground.materials = [groundMaterial]
        groundNode = SCNNode(geometry: ground)
        groundNode.physicsBody = body
        
        groundNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
        previousOrientation = groundNode.orientation
        
        //constraints
        lightNode.constraints = [SCNLookAtConstraint(target: carNode)]
        
        
        let cameraConstraint = SCNLookAtConstraint(target: self.chassis!)
        cameraConstraint.gimbalLockEnabled = true

        cameraNode.constraints = [cameraConstraint]
        cameraNode.position = SCNVector3(0.5, 10.0, -20.0)
        self.chassis!.addChildNode(cameraNode)
        
        accelView.scene!.rootNode.addChildNode(lightNode)

        accelView.scene!.rootNode.addChildNode(groundNode)
        
        
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
    
    func microGamePadHandler(mgp:GCMicroGamepad, element:GCControllerElement) -> Void {
        print("\(mgp.controller?.playerIndex): \(element)")
        
        if let directionPad = element as? GCControllerDirectionPad {
            
            self.steer(-directionPad.xAxis.value * 0.6)
            

        }
    }
    func buttonAPressed(button:GCControllerButtonInput, value:Float, pressed:Bool) {
        if pressed {
            self.accelerate(CGFloat(value) * 1500.0)
        }
        else {
            self.accelerate(CGFloat(0.0))
        }
    }
    func buttonXPressed(button:GCControllerButtonInput, value:Float, pressed:Bool) {
        self.brake( CGFloat(value) * 5.0 )
    }

    
    
    // MARK: Car Controls
    @nonobjc
    func accelerate(amount:Float) {
        self.acceleration = CGFloat(amount)
    }
    @nonobjc
    func brake(amount:Float) {
        self.acceleration = 0.0
        self.brake = CGFloat(amount)
    }
    
    @nonobjc
    func steer(amount:Float) {
        let steer = CGFloat(amount)
        self.vehicle?.setSteeringAngle(steer, forWheelAtIndex: 0)
        self.vehicle?.setSteeringAngle(steer, forWheelAtIndex: 1)
    }
    
    @nonobjc
    func accelerate(amount:CGFloat) {
        self.acceleration = amount
    }
    @nonobjc
    func brake(amount:CGFloat) {
        self.acceleration = 0.0
        self.brake = amount
    }
    
    @nonobjc
    func steer(steer:CGFloat) {
        self.vehicle?.setSteeringAngle(steer, forWheelAtIndex: 0)
        self.vehicle?.setSteeringAngle(steer, forWheelAtIndex: 1)
    }
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String) {
        self.write("Message received: \(message) from: \(fromDevice)")
    }
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void) {
        
        if let accel = message["Speed"] as? CGFloat {
            
            
            if accel > 0.0 {
                self.accelerate(accel * 200.0)
            }
            else if accel < 0.0 {
                self.brake( -accel * 5.0)
            }
            else {
                self.brake(CGFloat(0.0))
            }
            
            replyHandler(["Speed": accel])
            
            return
            
        }
        if let steer = message["Steering"] as? CGFloat {
            replyHandler(["Steering": steer])
            self.steer(steer)
            return
        }
        
        
        
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
            
        }
        else if message.keys.first == "DrawBegin" {
            
            let temp = message.values.first as! [Float]
            lastPoint = CGPoint(x: CGFloat(temp[0]), y: CGFloat(temp[1]))
            
        }
        else if message.keys.first == "DrawMove" {
            
            let temp = message.values.first as! [Float]
            let currentPoint = CGPoint(x: CGFloat(temp[0]), y: CGFloat(temp[1]))
            
            drawLineFrom(lastPoint, toPoint: currentPoint)
            lastPoint = currentPoint
        }
        else if message.keys.first == "DrawEnd" {
            
            drawLineFrom(lastPoint, toPoint: lastPoint)
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
