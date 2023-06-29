//
//  DomeTile.swift
//  Wundermental
//
//  Created by Nicolas Walter on 28.06.23.
//

import Foundation
import SceneKit


class DomeTile: SCNNode {
    var centerPoint: SCNVector3
    var calculatedEulerAngels: SCNVector3
    var vertexSource: SCNGeometrySource
    
    var isScanned: Bool
    var isHighlighted: Bool
    
    init(vertexSource: SCNGeometrySource, centerPoint: SCNVector3, isScanned: Bool, isHighlighted: Bool, calculatedEulerAngles: SCNVector3) {
        self.centerPoint = centerPoint
        self.isScanned = isScanned
        self.isHighlighted = isHighlighted
        self.calculatedEulerAngels = calculatedEulerAngles
        self.vertexSource = vertexSource
        super.init()
        
        if(isScanned) {
            setScanned()
        } else if(isHighlighted) {
            setHighlighted()
        } else {
            setGeometryToOutline()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.centerPoint = SCNVector3Zero
        self.calculatedEulerAngels = SCNVector3Zero
        self.isScanned = false
        self.isHighlighted = false
        self.vertexSource = SCNGeometrySource()
        super.init(coder: aDecoder)
    }
    
    func setColour(color: UIColor) {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.isDoubleSided = true
        
        geometry?.materials = [material]
    }
    
    func setHighlighted() {
        isHighlighted = true
        setGeometryToFilled()
        setColour(color: UIColor.WLightBlue)
    }
    
    func setScanned() {
        isHighlighted = false
        isScanned = true
        setGeometryToFilled()
        setColour(color: UIColor.WGreenDark)
    }
    
    func setNormal() {
        isHighlighted = false
        setGeometryToOutline()
    }
    
    func setGeometryToOutline() {
        let indices: [UInt16] = [0, 1, 1, 2, 2, 3, 3, 0]
        let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
        let element = SCNGeometryElement(data: indexData, primitiveType: .line, primitiveCount: indices.count / 2, bytesPerIndex: MemoryLayout<UInt16>.size)
        geometry = SCNGeometry(sources: [vertexSource], elements: [element])
    }
    
    func setGeometryToFilled() {
        let indices: [UInt16] = [0, 1, 2, 2, 3, 0]
        let indexData = Data(bytes: indices, count: MemoryLayout<UInt16>.size * indices.count)
        let element = SCNGeometryElement(data: indexData, primitiveType: .triangles, primitiveCount: indices.count / 3, bytesPerIndex: MemoryLayout<UInt16>.size)
        geometry = SCNGeometry(sources: [vertexSource], elements: [element])
    }
}
