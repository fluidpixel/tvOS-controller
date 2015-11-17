//
//  PlayersViewController.swift
//  tvOS-controller
//
//  Created by Lauren Brown on 16/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import UIKit
import SceneKit

class PlayersViewController: UIViewController, TVCTVSessionDelegate {

    @IBOutlet weak var CarView1: SCNView!
    @IBOutlet weak var CarView2: SCNView!
    @IBOutlet weak var CarView3: SCNView!
    @IBOutlet weak var CarView4: SCNView!
    
    var players = [GameObject]()
    var numberOfPlayers = 0
    let MAX_NUMBER_OF_PLAYERS = 4
    
    var carScene = SCNScene()
    
    //ready confirmation
    @IBOutlet weak var ready1: UILabel!
    @IBOutlet weak var Ready2: UILabel!
    @IBOutlet weak var Ready3: UILabel!
    @IBOutlet weak var Ready4: UILabel!
    
    //lights
    var lightNode1 = SCNNode()
    var lightNode2 = SCNNode()
    var lightNode3 = SCNNode()
    var lightNode4 = SCNNode()
    // cameras
    let cameraNode1 = SCNNode()
    let cameraNode2 = SCNNode()
    let cameraNode3 = SCNNode()
    let cameraNode4 = SCNNode()
    
    //array to neaten things up 
    var PlayerViews = [SCNView!]()

    let remote = TVCTVSession()
    
    @IBOutlet weak var Player1ColourLabel: UILabel!
    
    @IBOutlet weak var PlayerNumberLabel: UILabel!
    @IBOutlet weak var StatusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareScenes()
        self.remote.delegate = self
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "StartGame" {
            if let vc = segue.destinationViewController as? ViewController {
                vc.gameObjects = players
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func prepareScenes() {
        //prepare all at the start and only light them up when a player joins
        //
        CarView1.scene = SCNScene()
        CarView2.scene = SCNScene()
        CarView3.scene = SCNScene()
        CarView4.scene = SCNScene()
        
        PlayerViews = [CarView1, CarView2, CarView3, CarView4]
        
        //setup cameras
        let camera = SCNCamera()
        
        cameraNode1.camera = camera
        cameraNode2.camera = camera
        cameraNode3.camera = camera
        cameraNode4.camera = camera
        
        cameraNode1.position = SCNVector3(10, 5, 10)
        cameraNode2.position = SCNVector3(10, 5, 10)
        cameraNode3.position = SCNVector3(10, 5, 10)
        cameraNode4.position = SCNVector3(10, 5, 10)
        
        
        let light = SCNLight()
        light.type = SCNLightTypeSpot
        
        lightNode1.light = light
        lightNode2.light = light
        lightNode3.light = light
        lightNode4.light = light
        
        lightNode1.position = SCNVector3(0, 50, 0)
        lightNode2.position = SCNVector3(0, 50, 0)
        lightNode3.position = SCNVector3(0, 50, 0)
        lightNode4.position = SCNVector3(0, 50, 0)

//        //add camera and light to views
//        CarView1.scene!.rootNode.addChildNode(cameraNode1)
//        CarView2.scene!.rootNode.addChildNode(cameraNode2)
//        CarView3.scene!.rootNode.addChildNode(cameraNode3)
//        CarView4.scene!.rootNode.addChildNode(cameraNode4)
        
    }
    
    func addNewPlayer(device : String) {
        
        numberOfPlayers++
        var newPlayer = GameObject()
        newPlayer.playerID = device
        newPlayer.ID = numberOfPlayers
        newPlayer.colourID = numberOfPlayers
        
        PlayerNumberLabel.text = "\(numberOfPlayers)/\(MAX_NUMBER_OF_PLAYERS)"
        if numberOfPlayers == MAX_NUMBER_OF_PLAYERS {
            StatusLabel.text = "All Players Ready!"
        }
        
        switch numberOfPlayers {
        case 1:
            AddPlayerToScreen(CarView1, lightNode: lightNode1, cameraNode: cameraNode1)
            break
        case 2:
            AddPlayerToScreen(CarView2, lightNode: lightNode2, cameraNode: cameraNode2)
            break
        case 3:
            AddPlayerToScreen(CarView3, lightNode: lightNode3, cameraNode: cameraNode3)
            break
        case 4:
            AddPlayerToScreen(CarView4, lightNode: lightNode4, cameraNode: cameraNode4)
            break
        default:
            break
        }
        players.append(newPlayer)
    }
    
    func AddPlayerToScreen(view : SCNView, lightNode : SCNNode, cameraNode : SCNNode) {
        
        if let carScene : SCNScene = SCNScene(named: "gameAssets.scnassets/rc_car.dae") {
            if let node = carScene.rootNode.childNodeWithName("rccarBody", recursively: false)  {
                node.position = SCNVector3Make(0, 0, 0)
                node.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
                node.physicsBody = SCNPhysicsBody.staticBody()
                node.name = "Car"
                let action = SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 0.5, z: 0, duration: 0.5))
                node.runAction(action)
                let constraint = SCNLookAtConstraint(target: node)
                
                lightNode.constraints = [constraint]
                cameraNode.rotation = SCNVector4(0, 1, 0, 0.7)
                view.scene?.rootNode.addChildNode(node)
                view.scene?.rootNode.addChildNode(lightNode)
                view.scene?.rootNode.addChildNode(cameraNode)
                
            }
            
        }
    }
    
    func removePlayerFromScreen() {
        
    }
    
    func changePlayerColour(i : Int, playerFromDevice: String) {
        
        for var j = 0; j < numberOfPlayers; ++j {
            if players[j].playerID == playerFromDevice {
                if let node = PlayerViews[j].scene!.rootNode.childNodeWithName("Car", recursively: false) {
                    players[j].colourID = (players[j].colourID + i) % 9
                    node.geometry?.materials[0].diffuse.contents = players[j].GetColour(players[j].colourID)
                    
                }
            }
        }
    }
    
    func playerIsReady(playerFromDevice : String) {
        
        for var j = 0; j < numberOfPlayers; ++j {
            if players[j].playerID == playerFromDevice {
                switch j {
                case 0:
                    ready1.hidden = !ready1.hidden
                    break
                case 1:
                    Ready2.hidden = !Ready2.hidden
                    break
                case 2:
                    Ready3.hidden = !Ready3.hidden
                    break
                case 3:
                    Ready4.hidden = !Ready4.hidden
                    break
                default:
                    break
                }
            }
        }
    }
    
    func deviceDidConnect(device: String) {
        print("Player joined!")
        
        addNewPlayer(device)
    }
    
    func deviceDidDisconnect(device: String) {
        print("Player left! :(")
        
        numberOfPlayers--
        
        //remove player from list
        for var i = 0; i < players.count; ++i {
            if players[i].playerID == device {
                players.removeAtIndex(i)
            }
        }
    }
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String) {
        print("received message")
        
        //join game
        //addNewPlayer(fromDevice)
    }
    
    func didReceiveMessage(message: [String : AnyObject], fromDevice: String, replyHandler: ([String : AnyObject]) -> Void) {
        print("received message with reply handler")
        
        if message.keys.first! == "Colour" {
            
            changePlayerColour(message.values.first as! Int, playerFromDevice: fromDevice)
            
        } else if message.keys.first == "Ready" {
            playerIsReady(fromDevice)
        }
        
        //join game
        //addNewPlayer(fromDevice)
    }
    

}
