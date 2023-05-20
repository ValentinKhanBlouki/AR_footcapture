//
//  ViewController.swift
//  test3
//
//  Created by Nicolas Walter on 13.05.23.
//

import UIKit
import SceneKit
import ARKit
import Foundation
import SCNLine


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        
        let domeNode = Dome(radius: 0.3, horizontalSegments: 10, verticalSegments: 20, view: sceneView)
        sceneView.scene.rootNode.addChildNode(domeNode)
        domeNode.simdPosition = SIMD3<Float>(0, 0, 0)

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        
        sceneView.session.run(configuration)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: Object Placement
    @objc
    func handleTap(_ sender: UITapGestureRecognizer){
        let location = sender.location(in: sceneView) //get location in arSCNView
        let results = sceneView.hitTest(location, types: .estimatedHorizontalPlane)
        
        if let firstResult = results.first{
            let anchor = ARAnchor(transform: firstResult.worldTransform)
                    sceneView.session.add(anchor: anchor)
            
        }else{
            print("Object placement failed - couldn't find a surface")
        }
    }

    
    // ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return Dome(radius: 0.3, horizontalSegments: 10, verticalSegments: 20, view: sceneView)

    }
    
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


extension Array {
    func chunked(into size: Int) -> [[Element]] {
              return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
