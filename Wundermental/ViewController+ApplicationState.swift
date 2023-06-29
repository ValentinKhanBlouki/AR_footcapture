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
                newState = .placeDome
                break
                
            case .scanning:
                if displayedDome == nil {
                    errorLabel.isHidden = false
                    errorLabel.setErrorMessage()
                    errorLabel.showAutoHideMessage(Errors.domeNotPlace)
                    return
                }
                newState = .scanning
                break
                
            case .finish:
                newState = .finish
                break
            }
            
            // 2. Apply changes as needed per state.
            internalState = newState
            
            switch newState {
            case .placeDome:
                if displayedDome != nil {
                    displayedDome.enableDragging()
                }
                print("State: Place Dome")
                //showBackButton(false)
                instructionLabel.display(Instructions.placeDome)
                nextButton.isEnabled = true
                nextButton.setTitle("Next", for: [])

                backButton.setTitle("Back", for: [])
                backButton.isHidden = true
                distanceToCurrentlySelectedNodeLabel.isHidden = true
                //loadModelButton.isHidden = true
                //flashlightButton.isHidden = true
                break
                
            case .scanning:
                displayedDome.disableDragging()
                print("State: Scan")
                //loadModelButton.isHidden = true
                //flashlightButton.isHidden = true
                //showBackButton(false)
                instructionLabel.display(Instructions.scanObject)

                nextButton.isEnabled = true
                nextButton.setTitle("Next", for: [])
                backButton.setTitle("Back", for: [])
                backButton.setSecondary()
                backButton.isHidden = false
                distanceToCurrentlySelectedNodeLabel.isHidden = false
                //displayInstruction(Message("Please wait for stable tracking"))
                break
                
            case .finish:
                print("State: Finish")
                //self.setNavigationBarTitle("Test")
                //loadModelButton.isHidden = true
                //flashlightButton.isHidden = false
                //showMergeScanButton()
                instructionLabel.display(Instructions.finish)
                nextButton.isEnabled = true
                nextButton.setTitle("Share", for: [])
                
                backButton.setTitle("Restart Scan", for: [])
                backButton.setSecondary()
                backButton.isHidden = false
                break
            }
            
        }
    }
    
    func switchToPreviousState() {
        print("switch to preivcous")
        print(state)
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
        print(state)
    }
    
    func switchToNextState() {
        print("switch to next")
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
        print(state)
    }
}
