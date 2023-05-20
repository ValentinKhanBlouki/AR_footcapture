//
//  Dome.swift
//  Wundermental
//
//  Created by Nicolas Walter on 20.05.23.
//

import Foundation
import SceneKit

class Dome: SCNNode {
    
    private var view: SCNView
    private var initialPosition: SCNVector3 = SCNVector3Zero
    
    init(radius: CGFloat, horizontalSegments: Int, verticalSegments: Int, view: SCNView) {
        self.view = view
        super.init()
        
        for i in 0..<horizontalSegments {
            let phi1 = CGFloat(i) * .pi / 2 / CGFloat(horizontalSegments - 1)
            let phi2 = CGFloat(i+1) * .pi / 2 / CGFloat(horizontalSegments - 1)
            
            for j in 0..<verticalSegments {
                let theta1 = CGFloat(j) * 2 * .pi / CGFloat(verticalSegments - 1)
                let theta2 = CGFloat(j+1) *  2  * .pi / CGFloat(verticalSegments - 1)
                
                // Calculate the vertices of the rectangle
                let vertex1 = SCNVector3(radius * sin(phi1) * cos(theta1), radius * cos(phi1), radius * sin(phi1) * sin(theta1))
                let vertex2 = SCNVector3(radius * sin(phi1) * cos(theta2), radius * cos(phi1), radius * sin(phi1) * sin(theta2))
                let vertex3 = SCNVector3(radius * sin(phi2) * cos(theta2), radius * cos(phi2), radius * sin(phi2) * sin(theta2))
                let vertex4 = SCNVector3(radius * sin(phi2) * cos(theta1), radius * cos(phi2), radius * sin(phi2) * sin(theta1))
                
                // Create a geometry element for the rectangle
                let vertices: [SCNVector3] = [vertex1, vertex2, vertex3, vertex4]
                let vertexSource = SCNGeometrySource(vertices: vertices)
                
                if Bool.random() {
                    // Fill the rectangle completely
                    let indices: [UInt16] = [0, 1, 2, 2, 3, 0]
                    let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
                    let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<UInt16>.size)
                    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
                    
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.WYellow
                    material.isDoubleSided = true

                    geometry.materials = [material]
                    
                    let rectangleNode = SCNNode(geometry: geometry)
                    self.addChildNode(rectangleNode)
                } else {
                    // Just draw the outline of the rectangle
                    let indices: [UInt16] = [0, 1, 1, 2, 2, 3, 3, 0]
                    let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
                    let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<UInt16>.size)
                    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
                    
                    let material = SCNMaterial()
                    material.diffuse.contents = UIColor.WGrey
                    geometry.materials = [material]
                    
                    let rectangleNode = SCNNode(geometry: geometry)
                    self.addChildNode(rectangleNode)
                }
                
                if (i == 0) {
                    break
                }
            }
        }
        enableDragging()
    }
    
    var lastPanPosition: SCNVector3?
    var panningNode: SCNNode?
    var panStartZ: CGFloat?
    
    func enableDragging() {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(panGesture:)))
        view.addGestureRecognizer(panRecognizer)
                                                   }
        
    @objc func panGesture(panGesture: UIPanGestureRecognizer) {
        guard let view = view as? SCNView else { return }
        let location = panGesture.location(in: self.view)
        switch panGesture.state {
        case .began:
            guard let hitNodeResult = view.hitTest(location, options: nil).first else { return }
            panStartZ = CGFloat(view.projectPoint(hitNodeResult.node.worldPosition).z)
            break
        case .changed:
            let worldTouchPosition = view.unprojectPoint(SCNVector3(location.x, location.y, panStartZ!))

            self.position = worldTouchPosition
            break
        case .ended:
            break
        default:
            break
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been initialised")
    }
}
