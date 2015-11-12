//
//  ViewController.swift
//  iPhone-controller
//
//  Created by Paul Jones on 02/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import UIKit
import CoreMotion
import SceneKit

class ViewController: UIViewController, TVCPhoneSessionDelegate {
    
    let remote = TVCPhoneSession()
    let motion = CMMotionManager()
    
    var buttonEnabled = 0
    var speedSquared : Float = 0.0

    @IBOutlet weak var speed: UILabel!
    @IBOutlet var TouchPad: UIPanGestureRecognizer!
    @IBOutlet var messageArea:UILabel!
    
    @IBOutlet weak var AccelerateButton: UIButton!
    @IBOutlet weak var BreakButton: UIButton!
    
    //for touchpad-to canvas on tv
    var point = CGPoint.zero
    var swiped = false
    
    @IBOutlet weak var textMessage: UITextView!
    
    
    @IBAction func button1Pressed() {
        send("Button", text: 1)
        buttonEnabled = 1
        
        //set up accelerometer readings
        
        if motion.deviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 0.5
            motion.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { (data: CMDeviceMotion?, error :NSError?) -> Void in
                if error == nil && data != nil {
                    
                    let temp = data!.attitude
                    
                    let accel : [Float] = [Float(temp.pitch), Float(temp.yaw), Float(temp.roll)]
                    self.send("Accelerometer", text: accel)
                }else {
                    self.write((error?.localizedDescription)!)
                }
            })
        }

    }

    @IBAction func button2Pressed() {
        send("Button", text: 2)
        buttonEnabled = 2
        motion.stopDeviceMotionUpdates()

    }
    @IBAction func button3Pressed() {
        send("Button", text: 3)
        buttonEnabled = 3
        motion.stopDeviceMotionUpdates()

    }
    //Button tap controls
    @IBAction func OnAccelerateTapped(sender: UIButton) {
        //Note: Touch inside disables the time the same way touch outside does,
        //      so the user can hold the button to gain acceleration
        // 1  - accelerate
        // 0  - release
        // -1 - break
        send("Speed", text: 0)
    }
    
    @IBAction func OnAccelerateReleased(sender: UIButton) {
        send("Speed", text: 0)
        
    }
    
    @IBAction func AcceleratePressed(sender: UIButton) {
        send("Speed", text: 1)
    }
    

    @IBAction func OnBreakTapped(sender: UIButton) {
        send("Speed", text: 0)
    }
    
    @IBAction func BreakPressed(sender: UIButton) {
        send("Speed", text: -1)
    }
    
    @IBAction func OnBreakReleased(sender: UIButton) {
        send("Speed", text: 0)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = false

        if touches.first != nil {
            let touch = touches.first!
            if buttonEnabled == 2 {
            point = touch.locationInView(self.view)
            
            send("DrawBegin", text: [point.x, point.y])
            }
        }
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        swiped = true
        
        if touches.first != nil {
            let touch = touches.first!
            if buttonEnabled == 2 {
                let currentPoint : CGPoint = touch.locationInView(view)
                send("DrawMove", text: [currentPoint.x, currentPoint.y])
                point = currentPoint
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if !swiped {
            if buttonEnabled == 2 {
                send("DrawEnd", text: [point.x, point.y])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remote.delegate = self
        self.view?.multipleTouchEnabled = true
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let value = UIInterfaceOrientation.LandscapeLeft.rawValue
        UIDevice.currentDevice().setValue(value, forKey: "orientation")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    private func send(identifier: String, text:AnyObject) {
        self.write("\(text)")
        self.remote.sendMessage([identifier:text], replyHandler: { (reply) -> Void in
            self.write("Reply received: \(reply)")
            
            if var tempSpeed = reply["Reply"] as? Float {
                tempSpeed = sqrt(tempSpeed)
                self.speed.text = "\(tempSpeed)mph"
            }
            
            }) { (error) -> Void in
                 self.write("ERROR : \(error)")
        }
    }
    private func write(text:String) {
        dispatch_async(dispatch_get_main_queue()) {
            let existingText = self.textMessage.text!
            self.textMessage.text = "\(existingText)\n\(text)"
        }
    }
    
    func didConnect() {
        self.write("Connected")
    }
    func didDisconnect() {
        self.write("Disconnected")
    }
    func didReceiveBroadcast(message: [String : AnyObject]) {
        self.write("Broadcast received: \(message)")
    }
    func didReceiveBroadcast(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        self.didReceiveBroadcast(message)
        replyHandler(["Reply":0])
    }
    func didReceiveMessage(message: [String : AnyObject]) {
        self.write("Message received: \(message)")
    }
    func didReceiveMessage(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        self.didReceiveMessage(message)
        replyHandler(["Reply":0])
    }
    
}

