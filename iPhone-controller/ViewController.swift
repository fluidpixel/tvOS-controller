//
//  ViewController.swift
//  iPhone-controller
//
//  Created by Paul Jones on 02/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TVCPhoneSessionDelegate {
    
    let remote = TVCPhoneSession()

    @IBOutlet var messageArea:UILabel!
    
    @IBAction func button1Pressed() {
        send("Button 1 Pressed")
    }
    @IBAction func button2Pressed() {
        send("Button 2 Pressed")
    }
    @IBAction func button3Pressed() {
        send("Button 3 Pressed")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remote.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    private func send(text:String) {
        self.write(text)
        self.remote.sendMessage(["Button":text], replyHandler: { (reply) -> Void in
            self.write("Reply received: \(reply)")
            }) { (error) -> Void in
                 self.write("ERROR : \(error)")
        }
    }
    private func write(text:String) {
        dispatch_async(dispatch_get_main_queue()) {
            let existingText = self.messageArea.text!
            self.messageArea.text = "\(existingText)\n\(text)"
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

