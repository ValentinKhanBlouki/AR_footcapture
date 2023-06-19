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
import RealityKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{

    @IBOutlet var sceneView: ARSCNView!
    internal var internalState: State = .placeDome
    
    
    private var domeAnchor: ARAnchor!
    
    public var displayedDome: Dome!
    private var radius: CGFloat = 0.3
    private var horizontalSegments: Int = 10
    private var verticalSegments: Int = 20
    private var timer: Timer?
    
    @IBOutlet weak var errorLabel: MessageLabel!
    @IBOutlet weak var backButton: Button!
    @IBOutlet weak var instructionLabel: MessageLabel!
    @IBOutlet weak var nextButton: Button!
    
    @IBOutlet weak var highlightButton: Button!
    @IBOutlet weak var scanProgressLabel: UILabel!
    @IBOutlet weak var distanceToCurrentlySelectedNodeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
                
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.showsStatistics = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        state = State.placeDome
        nextButton.setSecondary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    

    @IBAction func highlightButtonTapped(_ sender: Any) {
        displayedDome.highlightNextNode()
        scanProgressLabel.text = "\(displayedDome.highlightedNode)/\(horizontalSegments*verticalSegments)"
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(calculateDistanceAndAngle), userInfo: nil, repeats: true)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        switchToNextState()
    }
    @IBAction func backButtonTapped(_ sender: Any) {
        if state == State.finish {
            state = State.placeDome
            return
        }
            
        switchToPreviousState()
    }
    
    @objc func calculateDistanceAndAngle() {
        guard let camera = sceneView.session.currentFrame?.camera,
                  let domeAnchor = domeAnchor else {
                return
            }
            
        let cameraPosition = simd_make_float3(camera.transform.columns.3)
        
        let domeAnchorPosition = simd_make_float3(domeAnchor.transform.columns.3)
        let relativeNodePosition = simd_float3(displayedDome.calculateCenterPositionOfHighlightedNode())
        
        let domeNodePosition = domeAnchorPosition + relativeNodePosition
//        let domeNodePosition = displayedDome.childNodes[displayedDome.highlightedNode].simdPosition
        
        
        let distance = simd_distance(domeNodePosition, cameraPosition)
        distanceToCurrentlySelectedNodeLabel.text = String(format: "%.2f", distance)
        // print("Distance to domeAnchor: \(distance)")
    }
    
    
    //MARK: Object Placement
    @objc
    func handleTap(_ sender: UITapGestureRecognizer){
        if state != State.placeDome {
            return
        }
        if domeAnchor != nil {
            sceneView.session.remove(anchor: domeAnchor)
        }
        
        let location = sender.location(in: sceneView) //get location in arSCNView
        let results = sceneView.hitTest(location, types: .estimatedHorizontalPlane)
        
        
        if let firstResult = results.first{
            domeAnchor = ARAnchor(transform: firstResult.worldTransform)
            sceneView.session.add(anchor: domeAnchor)
            nextButton.setPrimary()
        }
        else{
            errorLabel.setErrorMessage()
            errorLabel.showAutoHideMessage(Errors.domePlaceNoSurface)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if displayedDome != nil {
            radius = displayedDome.radius
        }
        displayedDome = Dome(radius: radius, horizontalSegments: horizontalSegments, verticalSegments: verticalSegments, view: sceneView)
        return displayedDome
    }
    
    @objc
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Present an error message to the user
        print(frame.camera.transform)
        
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
