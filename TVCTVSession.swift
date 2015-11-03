//
//  RemoteReceiver.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

let ERROR_SEND_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -100, userInfo: [NSLocalizedDescriptionKey:"Failed To Send Message"])

let ERROR_REPLY_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -200, userInfo: [NSLocalizedDescriptionKey:"No Message In Reply"])


@available(tvOS 9.0, *)
@objc
protocol TVCTVSessionDelegate : NSObjectProtocol {
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String)
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void)

    func deviceDidConnect(device: String)
    func deviceDidDisconnect(device: String)
    
}

@available(tvOS 9.0, *)
@objc
public class TVCTVSession : NSObject, NSNetServiceDelegate, GCDAsyncSocketDelegate, NSNetServiceBrowserDelegate {
    weak var delegate:TVCTVSessionDelegate?

    internal var service:NSNetService!
    internal var socket:GCDAsyncSocket!
    internal var devSock:[GCDAsyncSocket:String?] = [:]
    
    internal var replyGroups:[Int:dispatch_group_t] = [:]
    internal var replyMessages:[Int:(String, [String:AnyObject])] = [:]
    internal var replyIdentifierCounter:Int = 0
    
    internal let delegateQueue = dispatch_get_main_queue()
    
    public var connectedDevices:Set<String> {
        let values = devSock.values.flatMap { $0 }
        return Set<String>(values)
    }
            
    public func broadcastMessage(message: [String : AnyObject], replyHandler: ((String, [String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        if let rh = replyHandler {
            for sock in devSock.keys {
                let replyID = ++replyIdentifierCounter
                let group = dispatch_group_create()
                dispatch_group_enter(group)
                replyGroups[replyID] = group
                
                dispatch_group_notify(group, dispatch_get_main_queue()) {
                    if let params = self.replyMessages[replyID] {
                        rh(params)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                sock.writeData(Message(type: .Broadcast, replyID: replyID, contents: message).data, withTimeout: -1.0, tag: 0)
            }
        }
        else {
            for sock in devSock.keys {
                sock.writeData(Message(type: .Broadcast, contents: message).data, withTimeout: -1.0, tag: 0)
            }
        }        
    }
    
    public func sendMessage(deviceID:String, message: [String : AnyObject], replyHandler: ((String, [String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        
        let socklist = devSock.filter { $0.1 == deviceID }
        
        if let sock = socklist.first?.0 {
            if let rh = replyHandler {
                
                let replyID = ++replyIdentifierCounter
                let group = dispatch_group_create()
                dispatch_group_enter(group)
                replyGroups[replyID] = group
                
                dispatch_group_notify(group, dispatch_get_main_queue()) {
                    if let params = self.replyMessages[replyID] {
                        rh(params)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                sock.sendMessageObject(Message(type: .Message, replyID: replyID, contents: message))
            }
            else {
                sock.sendMessageObject(Message(type: .Message, contents: message))
            }
        }
        else {
            // TODO: Error! device not connected
            errorHandler?(ERROR_SEND_FAILED)
        }
    }
    
    private func dispatchReply(replyHandler: ((String, [String : AnyObject]) -> Void)?, errorHandler: ((NSError) -> Void)?) -> Int {
        
        let replyID = ++replyIdentifierCounter
        let group = dispatch_group_create()
        dispatch_group_enter(group)
        replyGroups[replyID] = group
        
        dispatch_group_notify(group, dispatch_get_main_queue()) {
            if let params = self.replyMessages[replyID] {
                replyHandler?(params)
            }
            else {
                errorHandler?(ERROR_REPLY_FAILED)
            }
        }
        
        return replyID
        
    }
    
    override init() {
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        
        try! self.socket.acceptOnPort(0)
        self.service = NSNetService(domain: "local.", type: SERVICE_NAME, name: NET_SERVICE_NAME, port: Int32(self.socket.localPort()))
        self.service.delegate = self
        self.service.publish()

    }
    
    // MARK: GCDAsyncSocketDelegate
    public func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {

        if let oldValue = devSock.updateValue(nil, forKey: newSocket), let oldDevice = oldValue {
            self.delegate?.deviceDidDisconnect(oldDevice)
        }
        
        newSocket.sendMessageObject(Message(type: .RequestDeviceID))

        newSocket.readDataWithTimeout(-1.0, tag: 0)
        
    }
    
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        if let oldDevice = devSock.removeValueForKey(sock), let dev = oldDevice {
            self.delegate?.deviceDidDisconnect(dev)
            print("Device Disconnected \(dev) from socket \(sock)")
        }
        else {
            print("Socket Disconnected \(sock)")
        }

        if self.devSock.count == 0 {
            // restart connections
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
            
            // Beware the double optional!
            // devSock.updateValue(...) returns the value which was replaced but this can be nil. Some(Some(...)) or Some(None)
            // If no value was replced the method returns a double optional ?? which must be unwrapped twice
            if let oldValue = devSock.updateValue(message.senderDeviceID, forKey: sock), let oldDevice = oldValue {
                if oldDevice != message.senderDeviceID {
                    print("\(oldDevice) Unexpected device on socket")
                    self.delegate?.deviceDidDisconnect(oldDevice)
                    self.delegate?.deviceDidConnect(message.senderDeviceID)
                }
            }
            else {
                print("\(message.senderDeviceID) New Device")
                self.delegate?.deviceDidConnect(message.senderDeviceID)
            }
            
            switch message.type {
            case .Message:
                if let replyID = message.replyID {
                    self.delegate?.didReceiveMessage(message.contents ?? [:], fromDevice: message.senderDeviceID, replyHandler: sendReply(sock, replyID) )
                }
                else {
                    self.delegate?.didReceiveMessage(message.contents ?? [:], fromDevice: message.senderDeviceID)
                }
            case .Reply:
                if let replyID = message.replyID, let group = replyGroups.removeValueForKey(replyID) {
                    
                    if let contents = message.contents {
                        replyMessages[replyID] = (message.senderDeviceID, contents)
                    }
                    
                    dispatch_group_leave(group)
                    
                }
            case .SendingDeviceID:
                // already handled
                break
            case .RequestDeviceID:
                print("Device ID Requested")
                //sock.sendMessageObject(Message(type: SendingDeviceID, targetDeviceID: message.senderDeviceID)
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



//internal var arrServices:[NSNetService] = []
//internal var coServiceBrowser:NSNetServiceBrowser!
//internal var dictSockets:[String:AnyObject] = [:]

//    func getSelectedSocket() -> GCDAsyncSocket {
//        if let coServiceName = self.arrServices.first?.name,
//            let rv = self.dictSockets[coServiceName] as? GCDAsyncSocket {
//                return rv
//        }
//        else {
//            fatalError("Could not getSelectedSocket - nil")
//        }
//    }
    
//}

/*
#import "RemoteReceiver.h"
#import "GCDAsyncSocket.h"
#import "tvOSGame-Swift.h"


#define ACK_SERVICE_NAME @"_ack._tcp."



@implementation RemoteReceiver
- (void)netServiceDidPublish:(NSNetService *)service
{
//    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
}
- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict
{
//    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
//    NSLog(@"Write data is done");
}
@end
*/



