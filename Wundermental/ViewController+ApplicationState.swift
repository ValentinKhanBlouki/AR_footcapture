//
//  ViewController+ApplicationState.swift
//  Wundermental
//
//  Created by Nicolas Walter on 21.05.23.
//

import Foundation
import ARKit
import SceneKit

extension ViewController {
    
    enum State {
        case placeDome
        case scanning
        case finish
    }
    
    /// - Tag: ARObjectScanningConfiguration
    // The current state the application is in
    var state: State {
        get {
            return self.internalState
        }
        set {
            // 1. Check that preconditions for the state change are met.
            var newState = newValue
            switch newValue {
            case .placeDome:
                newState = .scanning
                break
                
            case .scanning:
                newState = .finish
                break
                
            case .finish:
                break
            }
            
            // 2. Apply changes as needed per state.
            internalState = newState
            
            switch newState {
            case .placeDome:
                print("State: Place Dome")
                //showBackButton(false)
                nextButton.isEnabled = true
                //loadModelButton.isHidden = true
                //flashlightButton.isHidden = true
                
                // Make sure the SCNScene is cleared of any SCNNodes from previous scans.
                sceneView.scene = SCNScene()
                
            case .scanning:
                print("State: Not ready to scan")
                //loadModelButton.isHidden = true
                //flashlightButton.isHidden = true
                //showBackButton(false)
                nextButton.isEnabled = false
                nextButton.setTitle("Next", for: [])
                //displayInstruction(Message("Please wait for stable tracking"))
                
            case .finish:
                print("State: Testing")
                //self.setNavigationBarTitle("Test")
                //loadModelButton.isHidden = true
                //flashlightButton.isHidden = false
                //showMergeScanButton()
                nextButton.isEnabled = true
                nextButton.setTitle("Share", for: [])
                
            }
            
        }
    }
    
    func switchToPreviousState() {
        switch state {
        case .placeDome:
            break
        case .scanning:
            state = .placeDome
            break
        case .finish:
            state = .scanning
            break
        }
    }
    
    func switchToNextState() {
        switch state {
        case .placeDome:
            state = .scanning
            break
        case .scanning:
            state = .finish
            break
        case .finish:
            break
        }
    }
}
