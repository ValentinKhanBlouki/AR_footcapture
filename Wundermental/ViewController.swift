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
import Photos

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    
    @IBOutlet var sceneView: ARSCNView!
    internal var internalState: State = .placeDome
    
    
    private var domeAnchor: ARAnchor!
    
    public var displayedDome: Dome!
    public var lidarAvailable : Bool = false // default
    private var radius: CGFloat = 0.3
    private var horizontalSegments: Int = 5 // 3 horizontal segments -> first and last are not rendered
    private var verticalSegments: Int = 30
    
    
    private var timer: Timer?
    private var distanceTolerance = Float(0.2)
    private var angleTolerance = Float(0.2)
    private var albumNameText: String?
    
    
    @IBOutlet weak var errorLabel: MessageLabel!
    @IBOutlet weak var backButton: Button!
    @IBOutlet weak var instructionLabel: MessageLabel!
    @IBOutlet weak var nextButton: Button!
    
    @IBOutlet weak var highlightButton: Button!
    @IBOutlet weak var scanProgressLabel: UILabel!
    @IBOutlet weak var distanceToCurrentlySelectedNodeLabel: UILabel!
    @IBOutlet weak var angleOfPhone: UILabel!
    @IBOutlet weak var createAlbum: Button!
    @IBOutlet weak var albumName: UITextField!
    
    
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    // VIEW SETUP
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        sceneView.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        sceneView.showsStatistics = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        state = State.albumName
        nextButton.setSecondary()
        backButton.setTitle("Back", for: [])
        
        createAlbum.setSecondary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        lidarAvailable = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        if lidarAvailable {
            configuration.frameSemantics = .sceneDepth
        }
        if let hiResFormat = ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution {
            configuration.videoFormat = hiResFormat
        }
        sceneView.session.run(configuration)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !lidarAvailable {
            displayLiDARAlert()
        }
    }
    
    @objc func displayLiDARAlert() {
        let alertController = UIAlertController(title: "No LiDAR Sensor", message: "Your phone does not have the LiDAR sensor necessary to acquire depth data. Therefore only normal images will be saved.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            // Continue with normal image saving or perform other actions
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    // BUTTONS
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    
    @IBAction func createButtonTapped(_ sender: Any){
        if (state == State.detailPhotos) {
            takePicture()
            errorLabel.showAutoHideMessage(Message("picture taken"), duration: 1.0)
            return
        }
        
        dismissKeyboard()
        if let text = albumName.text {
            if text.isEmpty {
                let alertController = UIAlertController(title: "Album name empty", message: "Please type in a name for the album", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                    // Continue with normal image saving or perform other actions
                }
                alertController.addAction(okAction)
                present(alertController, animated: true, completion: nil)
                return
            }
            
            Album().createAlbum(withTitle: text) { album in
                if let createdAlbum = album {
                    self.albumNameText = text
                    
                    print("Album created with local identifier: \(createdAlbum.localIdentifier)")
                    self.switchToNextState()
                } else {
                    print("Failed to create album.")
                }
            }
        }
    }
    
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if state == State.placeDome {
            timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(scan3DObject), userInfo: nil, repeats: true)
        }
        
        if state == State.finish{
            
            shareAssetsWithAirDrop(albumName: self.albumNameText!, presentingViewController: self)
            
        }
        switchToNextState()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        if state == State.finish {
            state = State.albumName
            displayedDome = nil
            sceneView.session.remove(anchor: domeAnchor)
            return
            
        }
        switchToPreviousState()
    }
    
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    // CONTINUOUS MEASUREMENT
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    
    @objc func scan3DObject() {
        
        if displayedDome == nil || state != State.scanning{
            return
        }
        if displayedDome.allDomeTilesAreScanned(){
            state = State.detailPhotos
            return
        }
        guard let camera = sceneView.session.currentFrame?.camera else {
            return
        }
        
        var cameraPosition = simd_make_float3(camera.transform.columns.3)
        cameraPosition = simd_make_float3(cameraPosition.x, cameraPosition.y, cameraPosition.z)
        guard let cameraEulerAngle = sceneView.session.currentFrame?.camera.eulerAngles else { return }
        
        displayedDome.highlightClosest(cameraPos: cameraPosition, domeAnchor: simd_float3(displayedDome.worldPosition))
        
        var distance = Float(10.0)
        var rotationIsCorrect = false
        if let domeTile = displayedDome.highlightedNode {
            distance = simd_distance(simd_float3(displayedDome.worldPosition) + simd_float3(domeTile.centerPoint), cameraPosition)
            let calculatedEuler = domeTile.calculatedEulerAngels
            
            
            
            rotationIsCorrect = (abs(abs(calculatedEuler.x) - abs(cameraEulerAngle.x)) < angleTolerance
                                 && abs(abs(calculatedEuler.y) - abs(cameraEulerAngle.y)) < angleTolerance)
            
            
            if rotationIsCorrect {
                angleOfPhone.text = "Angle Perfect"
                angleOfPhone.backgroundColor = UIColor.WGreen
            } else {
                var instruction = ""
                // Check Y angle (corresponds to left-right)
                let angleYDiff = abs(calculatedEuler.y) - abs(cameraEulerAngle.y)
                if (abs(angleYDiff) > angleTolerance) {
                    instruction += "↔️ \(String(format: "%.2f", angleYDiff)) "
                }
                // Check X angle (corresponds to up-down)
                let angleXDiff = abs(calculatedEuler.x) - abs(cameraEulerAngle.x)
                if (abs(angleXDiff) > angleTolerance) {
                    instruction += "↕️ \(String(format: "%.2f", angleXDiff))"
                }
                angleOfPhone.text = instruction
                angleOfPhone.backgroundColor = UIColor.WLightRed
            }
        }
        
        if(distance > Float(radius)*0.8 && distance < (Float(radius)*0.8)+distanceTolerance) {
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WGreen
            distanceToCurrentlySelectedNodeLabel.text = "Distance Perfect"
            
        } else if(distance >= Float(radius)*0.8){
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WLightRed
            distanceToCurrentlySelectedNodeLabel.text = "Move closer"
        } else if(distance <= Float(radius)*0.8+distanceTolerance){
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WLightRed
            distanceToCurrentlySelectedNodeLabel.text = "Move further away"
            
        }
        if(distance > Float(radius)*0.8 && distance < (Float(radius)*0.8)+distanceTolerance
           && rotationIsCorrect) {
            distanceToCurrentlySelectedNodeLabel.backgroundColor = UIColor.WGreen
            distanceToCurrentlySelectedNodeLabel.text = "Picture taken 📸 ✅"
            displayedDome.setHighlightedTileAsScanned()
            takePicture()
        }
    }
    
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    // IMAGE ACQUISITION
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    
    @objc func takePicture() {
        let imageBaseFileName = Int(arc4random_uniform(10000)) // QUESTION: never used?
        
        let session = sceneView.session
        guard let currentFrame = session.currentFrame else {
            return
        }
        let context = CIContext()
        
        // Extract photographic snapshot (regular image).
        let pixelBuffer = currentFrame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)) else {
            return
        }
        let snapshot = UIImage(cgImage: cgImage)
        
        // Extract Depth Map.
        let depthMap: UIImage?

        if lidarAvailable {
            let depthMapPixelBuffer = sceneView.session.currentFrame?.sceneDepth?.depthMap
            let depthMapCI = CIImage(cvPixelBuffer: depthMapPixelBuffer!)
            let depthMapWidth = CVPixelBufferGetWidth(depthMapPixelBuffer!)
            let depthMapHeight = CVPixelBufferGetHeight(depthMapPixelBuffer!)
            guard let depthMapCGI = context.createCGImage(depthMapCI, from: CGRect(x: 0, y: 0, width: depthMapWidth, height: depthMapHeight)) else {
                return
            }
            depthMap = UIImage(cgImage: depthMapCGI)
        } else {
            depthMap = nil
        }
    
        
        // Save both in album.
        if let text = albumName.text {
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", text)
            let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
            
            // Save snapshot.
            if let album = album{
                Album().saveImagesToPhotoAlbum(image: snapshot, depthMap: depthMap, album: album) { success, error in
                    if success {
                        print("Image saved to album successfully.")
                        
                    } else {
                        print("Failed to save image to album. Error: \(String(describing: error))")
                    }
                }
            } else {
                print("Album not found or image is nil.")
            }
        } else {
            print("No text entered.")
        }
    }
    
    
    
    
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    // IMAGE ACQUISITION
    // ///////////////////////////////////////////////////////////////////////////////////////////////
    func shareAssetsWithAirDrop(albumName: String, presentingViewController: UIViewController) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        
        let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
        
        if let album = album {
            let assetResults = PHAsset.fetchAssets(in: album, options: nil)
            
            var assetsToShare: [UIImage] = []
            assetResults.enumerateObjects { asset, _, _ in
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: requestOptions) { image, _ in
                    if let image = image {
                        assetsToShare.append(image)
                    }
                }
            }
            
            if !assetsToShare.isEmpty {
                let activityViewController = UIActivityViewController(activityItems: assetsToShare, applicationActivities: nil)
                
                activityViewController.excludedActivityTypes = [UIActivity.ActivityType.addToReadingList]
                
                activityViewController.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                    if completed {
                        print("Assets shared with AirDrop.")
                    } else if let error = error {
                        print("Error sharing assets: \(error.localizedDescription)")
                    } else {
                        print("Sharing cancelled by user.")
                    }
                }
                
                presentingViewController.present(activityViewController, animated: true, completion: nil)
            } else {
                print("No assets found in the album.")
            }
        } else {
            print("Album not found.")
        }
    }
    
    
    
    //MARK: Object Placement
    @objc
    func handleTap(_ sender: UITapGestureRecognizer){
        self.view.endEditing(true)
        if albumName.text != "" {
            print("set primary")
            createAlbum.setPrimary()
        }
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
