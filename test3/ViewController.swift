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
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        let moveGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        view.addGestureRecognizer(moveGesture)

        let resizeGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        view.addGestureRecognizer(resizeGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if let tappedNode = hits.first?.node {
                if gesture.state == .changed {
                    let translation = gesture.translation(in: gesture.view)
                    let modifiedPos = SCNVector3Make(tappedNode.position.x + Float(translation.x), tappedNode.position.y - Float(translation.y), tappedNode.position.z)
                    tappedNode.position = modifiedPos
                    gesture.setTranslation(CGPoint.zero, in: gesture.view)
            }
        }
    }

    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        let hits = self.sceneView.hitTest(location, options: nil)
        if let tappedNode = hits.first?.node {
            if gesture.state == .changed {
                let pinchScaleX = Float(gesture.scale) * tappedNode.scale.x
                let pinchScaleY = Float(gesture.scale) * tappedNode.scale.y
                let pinchScaleZ = Float(gesture.scale) * tappedNode.scale.z
                tappedNode.scale = SCNVector3(x: pinchScaleX, y: pinchScaleY, z: pinchScaleZ)
                gesture.scale = 1
            }
        }
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
    
    let radius: CGFloat = 0.3
    let segments = 30
    let height: CGFloat = 0.001
    
    // ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0)
        let boxNode = SCNNode(geometry: boxGeometry)
            
        let sphereNode = SCNNode()

        let colors: [UIColor] = [
            .red, .orange, .yellow, .green, .blue, .purple
            // Add more colors here for additional segments
        ]

        for i in 0..<segments {
            let phi1 = CGFloat(i) * .pi / CGFloat(segments - 1)
            let phi2 = CGFloat(i+1) * .pi / CGFloat(segments - 1)
            
            for j in 0..<segments {
                let theta1 = CGFloat(j) * 2 * .pi / CGFloat(segments - 1)
                let theta2 = CGFloat(j+1) * 2 * .pi / CGFloat(segments - 1)
                
                // Calculate the vertices of the rectangle
                let vertex1 = SCNVector3(radius * sin(phi1) * cos(theta1), radius * cos(phi1), radius * sin(phi1) * sin(theta1))
                let vertex2 = SCNVector3(radius * sin(phi1) * cos(theta2), radius * cos(phi1), radius * sin(phi1) * sin(theta2))
                let vertex3 = SCNVector3(radius * sin(phi2) * cos(theta2), radius * cos(phi2), radius * sin(phi2) * sin(theta2))
                let vertex4 = SCNVector3(radius * sin(phi2) * cos(theta1), radius * cos(phi2), radius * sin(phi2) * sin(theta1))
                
                // Create a geometry element for the rectangle
                let vertices: [SCNVector3] = [vertex1, vertex2, vertex3, vertex4]
                let vertexSource = SCNGeometrySource(vertices: vertices)
                
                // Determine if the rectangle should be filled or just an outline
                let shouldFill = Bool.random()
                
                if shouldFill {
                    // Fill the rectangle completely
                    let indices: [UInt16] = [0, 1, 2, 2, 3, 0]
                    let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
                    let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<UInt16>.size)
                    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
                    
                    // Assign a random color from the colors array
                    let colorIndex = Int.random(in: 0..<colors.count)
                    let material = SCNMaterial()
                    material.diffuse.contents = colors[colorIndex]
                    
                    // Assign the material to the geometry
                    geometry.materials = [material]
                    
                    // Create a node with the geometry and add it to the sphere node
                    let rectangleNode = SCNNode(geometry: geometry)
                    sphereNode.addChildNode(rectangleNode)
                } else {
                    // Just draw the outline of the rectangle
                    let indices: [UInt16] = [0, 1, 1, 2, 2, 3, 3, 0]
                    let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
                    let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<UInt16>.size)
                    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
                                
                                // Assign a random color for the outline
                                let material = SCNMaterial()
                                material.diffuse.contents = UIColor.black
                                
                                // Assign the material to the geometry
                                geometry.materials = [material]
                                
                                // Create a node with the geometry and add it to the sphere node
                                let rectangleNode = SCNNode(geometry: geometry)
                                sphereNode.addChildNode(rectangleNode)
                            }
                        }
                    }

        return sphereNode
        //return ARDome(radius: 0.3, radialSegments: 10, verticalSegments: 10)
    
       // return boxNode
    }
    
    func distance(from: SCNVector3, to: SCNVector3) -> Float {
        let dx = from.x - to.x
        let dy = from.y - to.y
        let dz = from.z - to.z
        return sqrt(dx*dx + dy*dy + dz*dz)
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
