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
    public var lidarAvailable : Bool = false // default
    private var radius: CGFloat = 0.3
    private var horizontalSegments: Int = 6
    private var verticalSegments: Int = 12
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
        lidarAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        if lidarAvailable {
            configuration.frameSemantics = .sceneDepth
        }
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !lidarAvailable {
                displayLiDARAlert()
        }
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if state == State.placeDome {
           timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(calculateDistanceAndAngle), userInfo: nil, repeats: true)
        }
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
        guard let camera = sceneView.session.currentFrame?.camera else {
            return
        }
        
        var cameraPosition = simd_make_float3(camera.transform.columns.3)
        cameraPosition = simd_make_float3(cameraPosition.x, cameraPosition.y, cameraPosition.z)
        guard let cameraEulerAngle = sceneView.session.currentFrame?.camera.eulerAngles else { return }
        
        print(simd_float3(displayedDome.worldPosition))
        
        displayedDome.highlightClosest(cameraPos: cameraPosition, domeAnchor: simd_float3(displayedDome.worldPosition))
               
        var distance = Float(10.0)
        var rotationIsCorrect = false
        if let domeTile = displayedDome.highlightedNode {
            distance = simd_distance(simd_float3(displayedDome.worldPosition) + simd_float3(domeTile.centerPoint), cameraPosition)
            let calculatedEuler = domeTile.calculatedEulerAngels
            
            rotationIsCorrect = (abs(abs(calculatedEuler.x) - abs(cameraEulerAngle.x)) < 0.5
                && abs(abs(calculatedEuler.y) - abs(cameraEulerAngle.y)) < 0.5)
        }
      
        if(distance > Float(radius) && distance < (Float(radius) + 10)) {
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WGreen
            distanceToCurrentlySelectedNodeLabel.text = "Perfect"
        } else if(distance < Float(radius)) {
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WLightRed
            distanceToCurrentlySelectedNodeLabel.text = "Move further away"
        } else {
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WLightRed
            distanceToCurrentlySelectedNodeLabel.text = "Move closer"
        }
        if(distance > Float(radius) && distance < Float(radius) + 10
            && rotationIsCorrect) {
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WGreen
            distanceToCurrentlySelectedNodeLabel.text = "Picture taken 📸 ✅"
            displayedDome.setHighlightedTileAsScanned()
            takePicture()
        }
    }
    
    @objc func takePicture() {
        
        // GET IMAGES
        displayedDome.isHidden = true
        let snapshot = sceneView.snapshot()
        if lidarAvailable {
            let depthImage = getDepthImage()
            if let tiff = Tiff().convertToTIFF(depthImage){
                        Tiff().saveTIFFToPhotoLibrary(tiff) //CIImage!
                    }
        }
        SaveToPhotoLibrary().saveImageAsHEICToPhotoGallery(snapshot)
        // SIGNAL COMPLETION TO USER
        let systemSoundID: SystemSoundID = 1108 // Camera shutter sound ID
        AudioServicesPlaySystemSound(systemSoundID)
        displayedDome.isHidden = false
    }



    @objc func getDepthImage() -> CIImage {
        let depthMap = sceneView.session.currentFrame?.sceneDepth?.depthMap
        let depthImage = CIImage(cvPixelBuffer: depthMap!)
        return depthImage
    }
    
    @objc func displayLiDARAlert() {
            let alertController = UIAlertController(title: "No LiDAR Sensor", message: "Your phone does not have the LiDAR sensor necessary to acquire depth data. Therefore only normal images will be saved.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                // Continue with normal image saving or perform other actions
            }
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
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
            print(simd_make_float3(domeAnchor.transform.columns.3))
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
