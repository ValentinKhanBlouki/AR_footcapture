//
//  ContentView.swift
//  TestAugmentedReality
//
//  Created by Knowing on 02.05.23.
//

import SwiftUI
import RealityKit
import ARKit
//1 create model entity
//2 create anchor entity
//3 add to scene

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        arView.session.delegate = self //to call did add anchors
        
        setupARView() //override default configuration
        
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:))))
    }
    
    func setupARView(){
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()  //used to put object in physical space
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic //make it look as real as possible (reflection)
        arView.session.run(configuration)
    }
    
    //MARK: Object Placement
    @objc
    func handleTap(recognizer: UITapGestureRecognizer){
        let location = recognizer.location(in: arView) //get location in arView
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first{
            let anchor = ARAnchor(name: "ContemporaryFan", transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
            
        }else{
            print("Object placement failed - couldn't find a surface")
        }
        
        
    }
    func placedObject(named entityName: String, for anchor: ARAnchor){
        let entity = try! ModelEntity.loadModel(named: entityName) //force try if you know that model exists
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: entity)
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
        
    }
    
}

extension ViewController: ARSessionDelegate{
    func session(_ session:ARSession, didAdd anchors: [ARAnchor]){
        for anchor in anchors{
            if let anchorName = anchor.name, anchorName == "ContemporaryFan"{
                placedObject(named: anchorName, for: anchor)
            }
        }
    }
}
