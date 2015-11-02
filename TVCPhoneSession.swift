//
//  RemoteSender.swift
//  tvOSController
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import UIKit


let ERROR_SEND_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -100, userInfo: [NSLocalizedDescriptionKey:"Failed To Send Message"])

let ERROR_REPLY_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -200, userInfo: [NSLocalizedDescriptionKey:"No Message In Reply"])

@available(iOS 9.0, *)
protocol TVCPhoneSessionDelegate : class {

    func didConnect()
    func didDisconnect()
    
    func didReceiveBroadcast(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void)
    func didReceiveBroadcast(message: [String : AnyObject])
    
    func didReceiveMessage(message: [String : AnyObject])
    func didReceiveMessage(message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void)
    
}



@available(iOS 9.0, *)
@objc
public class TVCPhoneSession : NSObject, NSNetServiceBrowserDelegate, NSNetServiceDelegate, GCDAsyncSocketDelegate {
    
    weak var delegate:TVCPhoneSessionDelegate?

    internal let coServiceBrowser = NSNetServiceBrowser()
    internal var dictSockets:[String:GCDAsyncSocket] =  [:]
    internal var arrDevices:Set<NSNetService> = []

    internal var replyGroups:[Int:dispatch_group_t] = [:]
    internal var replyMessages:[Int:[String:AnyObject]] = [:]
    internal var replyIdentifierCounter:Int = 0

    public var connected:Bool {
        return self.selectedSocket != nil
    }
    
    public func sendMessage(message: [String : AnyObject], replyHandler: (([String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        
        if let selSock = self.selectedSocket {
            if let rh = replyHandler {
                let replyKey = ++replyIdentifierCounter
                let group = dispatch_group_create()
                replyGroups[replyKey] = group
                
                dispatch_group_enter(group)
                dispatch_group_notify(group, dispatch_get_main_queue()) {
                    if let reply = self.replyMessages.removeValueForKey(replyKey) {
                        rh(reply)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                
                selSock.sendMessageObject(Message(type: .Message, replyID: replyKey, contents: message))
                
            }
            else {
                selSock.sendMessageObject(Message(type: .Message, contents: message))
            }
        }
        else {
            errorHandler?(ERROR_SEND_FAILED)
        }
        
    }
    
    var selectedSocket:GCDAsyncSocket? {
        if let coService = self.arrDevices.first?.name {
            return self.dictSockets[coService]
        }
        return nil
    }


    override init() {
        super.init()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
    }
    
    func connectWithServer(service:NSNetService) -> Bool {
        if let coSocket = self.dictSockets[service.name] where coSocket.isConnected() {
            return true
        }
        let coSocket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        
        if let addrs = service.addresses {
            for address in addrs {
                do {
                    try coSocket.connectToAddress(address)
                    self.dictSockets[service.name] = coSocket
                    return true
                }
                catch let error as NSError {
                    print ("Can't connect to \(address)\n\(error)")
                }
            }
        }
        return false

    }
    
    // MARK: NSNetServiceBrowserDelegate
    public func netServiceBrowserDidStopSearch(browser: NSNetServiceBrowser) {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
        print("Browsing Stopped")
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.searchForServicesOfType(SERVICE_NAME, inDomain: "local.")
        print("Browsing Stopped")
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didRemoveService service: NSNetService, moreComing: Bool) {
        self.arrDevices.remove(service)
    }
    public func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
        self.arrDevices.insert(service)
        service.delegate = self
        service.resolveWithTimeout(30.0)
        
//        for timer in (1...5).map( { dispatch_time(DISPATCH_TIME_NOW, Int64($0 * NSEC_PER_SEC)) } ) {
//            dispatch_after(timer, dispatch_get_main_queue()) {
//                self.selectedSocket?.sendMessageObject(Message(type: .TEST))
//            }
//        }
        
    }
    
    
    // MARK: NSNetServiceDelegate
    public func netService(sender: NSNetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.delegate = self
    }
    public func netServiceDidResolveAddress(sender: NSNetService) {
        self.connectWithServer(sender)
    }
    

    // MARK: GCDAsyncSocketDelegate
    public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        sock.readDataWithTimeout(-1.0, tag: 0)
        
        sock.sendMessageObject(Message(type: .SendingDeviceID))
        
        delegate?.didConnect()
    }
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        delegate?.didDisconnect()
        
        // clearout pending replies and generate errors for them
        replyMessages.removeAll()
        let groups = replyGroups.map { $0.1 }
        replyGroups.removeAll()
        for group in groups {
            dispatch_group_leave(group)
        }
    }

    // curried function to send the user's reply to the sender
    // calling with the first set of arguments returns another function which the user then calls
    private func sendReply(sock: GCDAsyncSocket, _ replyID:Int)(reply:[String:AnyObject]) {
        sock.sendMessageObject(Message(type: .Reply, replyID: replyID, contents: reply))
    }
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        sock.readDataWithTimeout(-1.0, tag: 0)
        
        if let message = Message(data: data) {
            switch message.type {
            case .Reply:
                if let replyID = message.replyID, let group = replyGroups.removeValueForKey(replyID) {
                    if let reply = message.contents {
                        replyMessages[replyID] = reply
                    }
                    dispatch_group_leave(group)
                }
                else {
                    print("Unable to process reply. Reply received for unknown originator or duplicate reply")
                    // error
                }
                
            case .Broadcast:
                if let contents = message.contents {
                    if let replyID = message.replyID {
                        self.delegate?.didReceiveBroadcast(contents, replyHandler: sendReply(sock, replyID))
                    }
                    else {
                        self.delegate?.didReceiveBroadcast(contents)
                    }
                }
                else {
                    print("Unhandled Broadcast Received: \(message.type)")
                }
                
            case .Message:
                if let contents = message.contents {
                    if let replyID = message.replyID {
                        self.delegate?.didReceiveMessage(contents, replyHandler: sendReply(sock, replyID))
                    }
                    else {
                        self.delegate?.didReceiveMessage(contents)
                    }
                }
                else {
                    print("Unhandled Message Received: \(message.type)")
                }
                
            case .RequestDeviceID:
                sock.sendMessageObject(Message(type: .SendingDeviceID))
            default:
                print("Unhandled Message Received: \(message.type)")
            }
        }
        else {
            print("Unknown Data: \(data)")
            if let testString = String(data: data, encoding: NSUTF8StringEncoding) {
                print("       UTF8 : \(testString)")
            }
            else if let testString = String(data: data, encoding: NSWindowsCP1250StringEncoding) {
                print("     CP1250 : \(testString)")
            }
        }
        
    }

    
}




