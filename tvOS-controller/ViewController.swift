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
    @IBOutlet weak var DrawCanvas : UIImageView!
    @IBOutlet weak var messageView: UITextView!
    
    
    @IBOutlet weak var accelView: SCNView!
    @IBOutlet var speed: UILabel!
    
    let remote = TVCTVSession()
    
    var prevSpeed:Int = 0
    
    //scene nodes
    let cameraNode = SCNNode()
    let lightNode = SCNNode()
    var groundNode = SCNNode()

    //update variables
    var acceleration:CGFloat = 0.0
    var brake:CGFloat = 0.0

    var notes:[AnyObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.button1.hidden = true
        self.button2.hidden = true
        self.button3.hidden = true
        
        
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
    deinit {
        print("DEINIT")
        for note in notes {
            NSNotificationCenter.defaultCenter().removeObserver(note)
        }
        notes.removeAll()
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
    
    
    var ticks = 0
    var check = 0
    func renderer(renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: NSTimeInterval) {

//        self.vehicle?.applyEngineForce(self.acceleration, forWheelAtIndex: 2)
//        self.vehicle?.applyEngineForce(self.acceleration, forWheelAtIndex: 3)
//        
//        self.vehicle?.applyBrakingForce(self.brake, forWheelAtIndex: 2)
//        self.vehicle?.applyBrakingForce(self.brake, forWheelAtIndex: 3)
        
        self.vehicle?.applyEngineForce(self.acceleration, forWheelAtIndex: 0)
        self.vehicle?.applyEngineForce(self.acceleration, forWheelAtIndex: 1)
        
        self.vehicle?.applyBrakingForce(self.brake, forWheelAtIndex: 0)
        self.vehicle?.applyBrakingForce(self.brake, forWheelAtIndex: 1)

        let intSpeed = Int((self.vehicle?.speedInKilometersPerHour ?? 0.0) * 100.0 + 0.5)
        if prevSpeed != intSpeed {
            let text = "\(CGFloat(intSpeed) * 0.01) km/h"
            dispatch_async(dispatch_get_main_queue(), {self.speed.text = text})
            prevSpeed = intSpeed
        }
        
        if let car = self.chassis?.presentationNode {
            if ++ticks == 30 {
                if car.worldTransform.m22 <= 0.1 {
                    if ++check >= 3 {
                        //self.chassis?.position = SCNVector3(0.0, 0.0, 0.0)
                        
                        self.chassis?.rotation = SCNVector4(0.0, 0.0, 0.0, 0.0)
                        self.chassis?.physicsBody?.resetTransform()
                        check = 0
                    }
                }
                else {
                    check = 0
                }
                ticks = 0
            }
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
        camera.zFar = 1000.0
        cameraNode.camera = camera
        
        let ambientLight = SCNLight()
        ambientLight.type = SCNLightTypeAmbient
        ambientLight.color = UIColor(red: 0.25, green: 0.25, blue: 0.35, alpha: 1.0)
        cameraNode.light = ambientLight

        
        let light = SCNLight()
        light.type = SCNLightTypeDirectional
        light.castsShadow = true
        light.zFar = 10.0
        lightNode.light = light
        
        self.chassis = configureCar()
        self.chassis?.position = SCNVector3(x: 0.0, y: 0.0, z: 0.0)
        
        
        // Place some random objects on the scene
        
        let rng = GKARC4RandomSource()
        
        let xy = GKRandomDistribution(randomSource: rng, lowestValue: -200, highestValue: 200)
        let sz = GKRandomDistribution(randomSource: rng, lowestValue: 0, highestValue: 199)
        let obj = GKRandomDistribution(randomSource: rng, lowestValue: 1, highestValue: 4)
        
        let colours = [UIColor.redColor(), UIColor.greenColor(), UIColor.blueColor(), UIColor.yellowColor(), UIColor.orangeColor(), UIColor.magentaColor(), UIColor.cyanColor()]
        
        let colRNG = GKRandomDistribution(randomSource: rng, lowestValue: 0, highestValue: colours.count - 1)
        
        for _ in 0..<30 {
            
            var geometry:SCNGeometry
            var physics:SCNPhysicsBody
            
            switch obj.nextInt() {
            case 1:
                let size = CGFloat(sz.nextUniform()) * 20.0 + 5.0
                geometry = SCNBox(width: size, height: size, length: size, chamferRadius: size * 0.2)
                physics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
            case 2:
                let sizeA = CGFloat(sz.nextUniform()) * 15.0
                let sizeB = CGFloat(sz.nextUniform()) * 5.0
                geometry = SCNTorus(ringRadius: sizeA + sizeB, pipeRadius: sizeB)
                physics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
            case 3:
                let sizeA = CGFloat(sz.nextUniform()) * 5.0
                let sizeB = CGFloat(sz.nextUniform()) * 5.0
                geometry = SCNCone(topRadius: 0.0, bottomRadius: sizeA + 5.0, height: sizeA + sizeB + 5.0)
                physics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: [SCNPhysicsShapeTypeKey:SCNPhysicsShapeTypeConvexHull]))
                //physics.angularDamping = 0.9
            case 4:
                geometry = SCNCapsule(capRadius: CGFloat(sz.nextUniform()) * 15.0 + 5.0, height: CGFloat(sz.nextUniform()) * 15.0 + 5.0)
                physics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
            default:
                geometry = SCNSphere(radius: 3.0)
                physics = SCNPhysicsBody(type: .Dynamic, shape: SCNPhysicsShape(geometry: geometry, options: nil))
            }
            
            
            let node = SCNNode(geometry: geometry)
            
            var min = SCNVector3Zero
            var max = SCNVector3Zero
            geometry.getBoundingBoxMin(&min, max: &max)
            geometry.firstMaterial?.diffuse.contents = "Tile"
            geometry.firstMaterial?.diffuse.contentsTransform
            geometry.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(20.0, 20.0, 20.0)
            geometry.firstMaterial?.diffuse.wrapS = .Repeat
            geometry.firstMaterial?.diffuse.wrapT = .Repeat
            geometry.firstMaterial?.diffuse.minificationFilter = .Linear
            geometry.firstMaterial?.diffuse.mipFilter = .Linear

            geometry.firstMaterial?.emission.contents = colours[colRNG.nextInt()]

            geometry.firstMaterial?.doubleSided = true
            
            node.position = SCNVector3(CGFloat(xy.nextUniform()) * 150.0, -CGFloat(min.y) * 2.0, CGFloat(xy.nextUniform()) * 150.0)
            node.physicsBody = physics
            
            node.physicsBody?.mass = 20.0
            accelView.scene!.rootNode.addChildNode(node)

            
        }
        
        
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
        groundMaterial.diffuse.maxAnisotropy = 8.0
        let physicsShape = SCNPhysicsShape(geometry: SCNFloor(), options: nil)
        let body = SCNPhysicsBody(type: .Static, shape: physicsShape)
        ground.materials = [groundMaterial]
        groundNode = SCNNode(geometry: ground)
        groundNode.physicsBody = body
        
        groundNode.position = SCNVector3(x: 0, y: -0.5, z: 0)
        
        
        
        
        let cameraConstraint = SCNLookAtConstraint(target: self.chassis!)
        cameraConstraint.gimbalLockEnabled = true

        cameraNode.constraints = [cameraConstraint]
        cameraNode.position = SCNVector3(0.5, 10.0, -20.0)
        
        self.chassis!.addChildNode(cameraNode)
        
        let lightConstraint = SCNLookAtConstraint(target: self.chassis!)
        
        lightConstraint.gimbalLockEnabled = true
        lightNode.constraints = [lightConstraint]
        lightNode.position = SCNVector3(0.5, 10.0, -20.0)
        
        
        self.chassis!.addChildNode(lightNode)
        
        //accelView.scene!.rootNode.addChildNode(lightNode)

        accelView.scene!.rootNode.addChildNode(groundNode)
        
        accelView.showsStatistics = true
        
    }
    
    
    @IBAction func button1Pressed() {}
    @IBAction func button2Pressed() {}
    @IBAction func button3Pressed() {}
    
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
        print("Unknown message received from: \(fromDevice)\n\(message)\n")
    }
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void) {
        
        if let accel = message["Speed"] as? CGFloat {
            
            
            if accel > 0.0 {
                self.accelerate(accel * 1500.0)
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

        replyHandler(["Reply": speed])
        
    }
    
    
    func deviceDidConnect(device: String) {
        print("Connected: \(device)")
    }
    func deviceDidDisconnect(device: String) {
        print("Disconnected: \(device)")
    }

}
