//
//  Dome.swift
//  Wundermental
//
//  Created by Nicolas Walter on 20.05.23.
//

import Foundation
import SceneKit
import simd


class Dome: SCNNode {
    
    private var view: SCNView
    
    private var initialPinchScale: CGFloat = 1.0
    private var initialRadius: CGFloat = 1.0
    
    var lastPanLocation: SCNVector3?
    var panStartZ: CGFloat?
    
    public var radius: CGFloat
    private var horizontalSegments : Int
    private var verticalSegments : Int

    public var highlightedNode: DomeTile?
    
    
    enum nodeStatus {
        case normal
        case toBeScannedRightNow
        case alreadyScanned
    }
    
    
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
        highlightedNode = nil
        for i in 0..<horizontalSegments {
            let phi1 = CGFloat(i) * .pi / 2 / CGFloat(horizontalSegments - 1)
            let phi2 = CGFloat(i+1) * .pi / 2 / CGFloat(horizontalSegments - 1)
            if (i == 0) {
                continue
            }
            
            for j in 0..<verticalSegments {
                let theta1 = CGFloat(j) * 2 * .pi / CGFloat(verticalSegments - 1)
                let theta2 = CGFloat(j+1) *  2  * .pi / CGFloat(verticalSegments - 1)
                
                // Calculate the vertices of the rectangle
                let vertex1 = SCNVector3(radius * sin(phi1) * cos(theta1), radius * cos(phi1), radius * sin(phi1) * sin(theta1))
                let vertex2 = SCNVector3(radius * sin(phi1) * cos(theta2), radius * cos(phi1), radius * sin(phi1) * sin(theta2))
                let vertex3 = SCNVector3(radius * sin(phi2) * cos(theta2), radius * cos(phi2), radius * sin(phi2) * sin(theta2))
                let vertex4 = SCNVector3(radius * sin(phi2) * cos(theta1), radius * cos(phi2), radius * sin(phi2) * sin(theta1))
                
                let centerPoint = calculateAverage(vertex1: vertex1, vertex2: vertex2, vertex3: vertex3, vertex4: vertex4)
                
               
                let vector1 = SIMD3<Float>((vertex2.x - vertex1.x), (vertex2.y - vertex1.y), (vertex2.z - vertex1.z))
                let vector2 = SIMD3<Float>((vertex3.x - vertex2.x), (vertex3.y - vertex2.y), (vertex3.z - vertex2.z))
                
                let normalVector = normalize(cross(vector1, vector2))
                let pitch = atan2(normalVector.y, sqrt(normalVector.x * normalVector.x + normalVector.z * normalVector.z))
                let yaw = -atan2(normalVector.x, normalVector.z)
                let calculatedEulerAngels = SCNVector3(pitch, yaw, 0)
                
                let vertices: [SCNVector3] = [vertex1, vertex2, vertex3, vertex4]
                let vertexSource = SCNGeometrySource(vertices: vertices)

                self.addChildNode(DomeTile(vertexSource: vertexSource, centerPoint: centerPoint, isScanned: false, isHighlighted: false, calculatedEulerAngles: calculatedEulerAngels))
                
            }
        }
    }
    
    func subtractVectors(_ vector1: SCNVector3, _ vector2: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(vector1.x - vector2.x, vector1.y - vector2.y, vector1.z - vector2.z)
    }
    
    func highlightClosest(cameraPos: simd_float3, domeAnchor: simd_float3) {
        var closestNode: SCNNode? = nil
        var closestDistance: Float = 1.0
        print(domeAnchor)
        for node in childNodes {
            if let domeTile = (node as? DomeTile) {
                if domeTile.isScanned {
                    continue
                }
                
                let d = simd_distance(cameraPos, domeAnchor + simd_float3(domeTile.centerPoint))
                if(d < closestDistance) {
                    closestDistance = d
                    closestNode = node
                }
            }
        }        

        if(closestNode == nil) {
            return
        }

        if let domeTile = (closestNode as? DomeTile) {
            if !domeTile.isScanned {
                highlightedNode?.setNormal()
                highlightedNode = domeTile
                domeTile.setHighlighted()
            }
        }
    }
    
    func setHighlightedTileAsScanned() {
            highlightedNode?.setScanned()
            highlightedNode = nil
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
        updateGeometry()
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
    
    func calculateAverage(vertex1: SCNVector3, vertex2: SCNVector3, vertex3: SCNVector3, vertex4: SCNVector3) -> SCNVector3 {
        let vertexCount = 4
        
        // Sum up the individual components
        var sumX: Float = 0.0
        var sumY: Float = 0.0
        var sumZ: Float = 0.0
        
        sumX += vertex1.x
        sumY += vertex1.y
        sumZ += vertex1.z
        
        sumX += vertex2.x
        sumY += vertex2.y
        sumZ += vertex2.z
        
        sumX += vertex3.x
        sumY += vertex3.y
        sumZ += vertex3.z
        
        sumX += vertex4.x
        sumY += vertex4.y
        sumZ += vertex4.z
        
        // Calculate the average
        let averageX = sumX / Float(vertexCount)
        let averageY = sumY / Float(vertexCount)
        let averageZ = sumZ / Float(vertexCount)
        
        let averageVertex = SCNVector3(averageX, averageY, averageZ)
        return averageVertex
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been initialised")
    }
}
