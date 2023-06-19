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
    
    private var initialPinchScale: CGFloat = 1.0
    private var initialRadius: CGFloat = 1.0
    
    var lastPanLocation: SCNVector3?
    var panStartZ: CGFloat?
    
    public var radius: CGFloat
    private var horizontalSegments : Int
    private var verticalSegments : Int

    private var highlightedNode: Int = 0
    
    init(radius: CGFloat, horizontalSegments: Int, verticalSegments: Int, view: SCNView) {
        self.view = view
        self.radius = radius
        self.horizontalSegments = horizontalSegments
        self.verticalSegments = verticalSegments
        super.init()
        
        self.initialRadius = radius
        createDome()
        
        enableDragging()
    }
    
    func createDome() {
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
                
                let vertices: [SCNVector3] = [vertex1, vertex2, vertex3, vertex4]
                let vertexSource = SCNGeometrySource(vertices: vertices)
                
//                if i % 2 == 0 || j % 2 != 0 {
//                    // Fill the rectangle completely
//                    let indices: [UInt16] = [0, 1, 2, 2, 3, 0]
//                    let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
//                    let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<UInt16>.size)
//                    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
//
//                    let material = SCNMaterial()
//                    material.diffuse.contents = UIColor.WYellow
//                    material.isDoubleSided = true
//
//                    geometry.materials = [material]
//
//                    let rectangleNode = SCNNode(geometry: geometry)
//                    self.addChildNode(rectangleNode)
//                } else {
//                    // Just draw the outline of the rectangle
//                    let indices: [UInt16] = [0, 1, 1, 2, 2, 3, 3, 0]
//                    let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
//                    let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<UInt16>.size)
//                    let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
//
//                    let material = SCNMaterial()
//                    material.diffuse.contents = UIColor.WGrey
//                    geometry.materials = [material]
//
//                    let rectangleNode = SCNNode(geometry: geometry)
//                    self.addChildNode(rectangleNode)
//                }
                
                let indices: [UInt16] = [0, 1, 1, 2, 2, 3, 3, 0]
                let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
                let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<UInt16>.size)
                let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
                
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.WGrey
                geometry.materials = [material]
                
                let rectangleNode = SCNNode(geometry: geometry)
                self.addChildNode(rectangleNode)
                
                
                if (i == 0) {
                    break
                }
            }
        }
    }
    
    func highlightNode(at index: Int) {
        guard index >= 0 && index < horizontalSegments * verticalSegments else {
            return
        }
        
        // Reset the previously highlighted node, if any
//        if let previousNode = self.childNodes[highlightedNode] {
//            resetHighlight(for: previousNode)
//        }
        
        let node = self.childNodes[index]
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.blue
            geometry.materials = [material]
            
            // Highlight edges by adjusting line width
            if let element = geometry.elements.first {
                element.pointSize = 30.0  // Adjust the line thickness as needed
            }
        }
        
        highlightedNode = index
    }

    func resetHighlight(for node: SCNNode) {
        if let geometry = node.geometry {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.WGrey
            geometry.materials = [material]
            
            // Reset line width to default value
            if let element = geometry.elements.first {
                element.pointSize = 1.0  // Reset to the default line thickness
            }
        }
    }

    
        
    func highlightNextNode() {
        let nextIndex = highlightedNode + 1
        highlightNode(at: nextIndex)
    }
    
    func enableDragging() {
        DispatchQueue.main.async {
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
            self.view.addGestureRecognizer(pinchGesture)
            
            let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(panGesture:)))
            self.view.addGestureRecognizer(panRecognizer)
        }
    }
    
    func disableDragging() {
        DispatchQueue.main.async {
            for gestureRecognizer in self.view.gestureRecognizers ?? [] {
                if gestureRecognizer is UIPinchGestureRecognizer || gestureRecognizer is UIPanGestureRecognizer {
                    self.view.removeGestureRecognizer(gestureRecognizer)
                }
            }
        }
    }
    
    func updateGeometry() {
        for node in self.childNodes {
               node.removeFromParentNode()
           }
        createDome()
       }
        
    @objc func panGesture(panGesture: UIPanGestureRecognizer) {
        let location = panGesture.location(in: self.view)
        switch panGesture.state {
            case .began:
                lastPanLocation = self.worldPosition
                panStartZ = CGFloat(view.projectPoint(lastPanLocation!).z)
                break
            case .changed:
                let worldTouchPosition = view.unprojectPoint(SCNVector3(location.x, location.y, panStartZ!))
                let movementVector = SCNVector3(worldTouchPosition.x - lastPanLocation!.x,
                                                worldTouchPosition.y - lastPanLocation!.y,
                                                worldTouchPosition.z - lastPanLocation!.z)
                self.localTranslate(by: movementVector)
                self.lastPanLocation = worldTouchPosition
                break
            default:
                break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
            case .began:
                initialPinchScale = gesture.scale
                initialRadius = self.radius
                break
                
            case .changed:
                let scaleFactor = initialPinchScale * gesture.scale
                let newRadius = initialRadius * scaleFactor
                self.radius = newRadius
                break
            default:
                break
        }
        updateGeometry()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been initialised")
    }
}
