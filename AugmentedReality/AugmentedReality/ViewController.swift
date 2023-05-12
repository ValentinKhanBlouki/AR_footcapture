//
//  ViewController.swift
//  TestAugmented
//
//  Created by Knowing on 09.05.23.
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
        let configuration = ARWorldTrackingConfiguration()  //used to put object in physical space, tracks devices movement
        configuration.planeDetection = [.horizontal, .vertical]
        //configuration.detectionObjects //maybe use to detect foot or leg
        configuration.environmentTexturing = .automatic //make it look as real as possible (reflection)
        arView.session.run(configuration)
    }
    
    //MARK: Object Placement
    @objc
    func handleTap(recognizer: UITapGestureRecognizer){
        let location = recognizer.location(in: arView) //get location in arView
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        if let firstResult = results.first{
            let anchor = ARAnchor(name: "anchor", transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
            
        }else{
            print("Object placement failed - couldn't find a surface")
        }
        
        
    }
    func placedObject(named entityName: String, for anchor: ARAnchor){
        let box = MeshResource.generateBox(size: 0.3)
        let material = SimpleMaterial(color: .black, isMetallic: true)
        let entity = ModelEntity(mesh: box, materials: [material])
        entity.generateCollisionShapes(recursive: true)
        arView.installGestures([.all], for: entity) //enable rotation, scale, etc.
        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(entity)
        arView.scene.addAnchor(anchorEntity)
        
    }
    
}

extension ViewController: ARSessionDelegate{ //track changes to the seesion
    func session(_ session:ARSession, didAdd anchors: [ARAnchor]){
        for anchor in anchors{
            if let anchorName = anchor.name, anchorName == "anchor"{
                placedObject(named: anchorName, for: anchor)
            }
        }
    }
}
