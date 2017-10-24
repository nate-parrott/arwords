//
//  ViewController.swift
//  arwords
//
//  Created by Nate Parrott on 10/23/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AudioToolbox

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var timer: Timer?
    
    var heightOffset: Float = 0 {
        didSet {
            floorNode.position = SCNVector3(0, heightOffset, 0)
        }
    }
    let globalNode = SCNNode()
    let floorNode = SCNNode()
    let words = "I walk/this/lonely/road/the only/road/that/i have/ever/known".components(separatedBy: "/")
    var wordOffset = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        // sceneView.showsStatistics = true
        // sceneView.debugOptions.formUnion(.showPhysicsShapes)
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        scene.rootNode.addChildNode(globalNode)
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let environment = UIImage(named: "envmap.jpg")!
        scene.lightingEnvironment.contents = environment
        scene.lightingEnvironment.intensity = 2.0
        
        // setup floor:
        let floor = SCNFloor()
        floorNode.geometry = floor
        floorNode.isHidden = true
        globalNode.addChildNode(floorNode)
        let floorShape = SCNPhysicsShape(geometry: floor, options: nil)
        let floorBody = SCNPhysicsBody(type: .static, shape: floorShape)
        floorNode.physicsBody = floorBody
        
        let longPressRec = UILongPressGestureRecognizer(target: self, action: #selector(recalibrate))
        sceneView.addGestureRecognizer(longPressRec)
    }
    
    @objc func recalibrate() {
        wordOffset = 0
        timer?.invalidate()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            self.startTimer()
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        heightOffset = sceneView.pointOfView!.position.y - 0.127
        for node in wordNodes { node.removeFromParentNode() }
        wordNodes = []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        startTimer()
    }
    
    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true, block: { [weak self] (_) in
            self?.dropWord()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        
        timer?.invalidate()
    }
    
    var wordNodes = [SCNNode]()
    
    func dropWord() {
        let scale = 0.02
        
        let word = words[wordOffset % words.count]
        wordOffset += 1
        let attributedText = NSAttributedString(string: word)
        let textSize = attributedText.size()
        let wordGeometry = SCNText(string: attributedText, extrusionDepth: 2)
        wordGeometry.containerFrame = CGRect(x: -textSize.width/2, y: -textSize.height/2, width: textSize.width * 1.1, height: textSize.height * 1.1)
        wordGeometry.chamferRadius = 0.1
        
        let material = wordGeometry.firstMaterial!
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)
        material.roughness.contents = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        material.metalness.contents = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        
        let wordNode = SCNNode(geometry: wordGeometry)
        wordNode.scale = SCNVector3(scale, scale, scale)
        // wordNode.position = sceneView.pointOfView!.position
        wordNode.position = wordSpawnPos()
        wordNode.rotation = SCNVector4(1, 0, 0, -Double.pi * 0.6)
        sceneView.scene.rootNode.addChildNode(wordNode)
        // let physicsShape = SCNPhysicsShape(geometry: wordGeometry, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox])
        let physicsShape = SCNPhysicsShape(geometry: wordGeometry, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox, SCNPhysicsShape.Option.scale: SCNVector3(scale, scale, scale)])
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.restitution = 0.1
        wordNode.physicsBody = physicsBody
        
        wordNodes.append(wordNode)
        while wordNodes.count > 10 {
            wordNodes.first!.removeFromParentNode()
            wordNodes.remove(at: 0);
        }
    }
    
    func wordSpawnPos() -> SCNVector3 {
        let ahead = SCNVector3(0, 0, -1)
        let pos = sceneView.pointOfView!.position
        let vec = sceneView.pointOfView!.convertPosition(ahead, to: sceneView.scene.rootNode)
        let angle = atan2(vec.z - pos.z, vec.x - pos.x)
        let dist: Float = 2
        return SCNVector3(pos.x + Float(cos(angle)) * dist, pos.y, pos.z + Float(sin(angle)) * dist)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
