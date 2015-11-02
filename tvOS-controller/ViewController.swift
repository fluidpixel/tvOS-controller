//
//  ViewController.swift
//  tvOS-controller
//
//  Created by Paul Jones on 02/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import UIKit

class ViewController: UIViewController, TVCTVSessionDelegate {
    
    @IBOutlet var messageArea: UILabel!
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    
    @IBOutlet var button3: UIButton!
    
    
    let remote = TVCTVSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remote.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func button1Pressed() {
        sendButtonPressed("Button 1")
    }
    
    @IBAction func button2Pressed() {
        sendButtonPressed("Button 2")
        
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
            let existingText = self.messageArea.text!
            self.messageArea.text = "\(existingText)\n\(line)"
        }
    }
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String) {
        self.write("Message received: \(message) from: \(fromDevice)")
    }
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void) {
        self.didReceiveMessage(message, fromDevice: fromDevice)
        replyHandler(["Reply":false])
    }
    func deviceDidConnect(device: String) {
        self.write("Connected: \(device)")
    }
    func deviceDidDisconnect(device: String) {
        self.write("Disconnected: \(device)")
    }
}

