//
//  ViewController+ApplicationState.swift
//  Wundermental
//
//  Created by Nicolas Walter on 21.05.23.
//

import Foundation
import ARKit
import SceneKit
import UIKit

extension ViewController {
    
    
    enum State {
        case placeDome
        case scanning
        case finish
        case albumName
        case detailPhotos
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
            case .albumName:
                newState = .albumName
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
                
            case .detailPhotos:
                newState = .detailPhotos
                break
            case .finish:
                newState = .finish
                break
            }
            
            // 2. Apply changes as needed per state.
            internalState = newState
            switch newState {
            case .albumName :
                    albumName.layer.cornerRadius = 10.0
                    albumName.textColor = UIColor.black
                    albumName.attributedPlaceholder = NSAttributedString(
                    string: "enter album name",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
                )
                
                nextButton.isHidden = true
                backButton.isHidden = true
                createAlbum.isHidden = false
                createAlbum.setTitle("Create Album", for: [])
                albumName.isHidden = false
                instructionLabel.isHidden = true
                distanceToCurrentlySelectedNodeLabel.isHidden = true
                angleOfPhone.isHidden = true
                
            case .placeDome:
                if displayedDome != nil {
                    displayedDome.enableDragging()
                }
                DispatchQueue.main.async {
                    // UInextButton.isEnabled = true
                    self.nextButton.isEnabled = true
                    self.nextButton.isHidden = false
                    self.nextButton.setTitle("Next", for: [])
                    self.createAlbum.isHidden = true
                    self.albumName.isHidden = true
                    self.instructionLabel.isHidden = false
                    self.backButton.isHidden = true
                    self.distanceToCurrentlySelectedNodeLabel.isHidden = true
                    self.angleOfPhone.isHidden = true

                }
                instructionLabel.display(Instructions.placeDome)
               
                break
                
            case .scanning:
                displayedDome.isHidden = false
                displayedDome.disableDragging()
                instructionLabel.display(Instructions.scanObject)

                nextButton.isEnabled = true
                nextButton.setTitle("Next", for: [])
                nextButton.setSecondary()
                
                backButton.setSecondary()
                backButton.isHidden = false
                
                distanceToCurrentlySelectedNodeLabel.isHidden = false
                angleOfPhone.isHidden = false
                createAlbum.isHidden = true
                break
                
            case .detailPhotos:
                instructionLabel.display(Instructions.detailPhotos)
                displayedDome.isHidden = true
                createAlbum.isHidden = false
                createAlbum.setSecondary()
                createAlbum.setTitle("Take Picture", for: [])
                
                nextButton.isEnabled = true
                nextButton.setTitle("Finish", for: [])
                nextButton.setPrimary()
                
                backButton.setSecondary()
                backButton.isHidden = false
                distanceToCurrentlySelectedNodeLabel.isHidden = true
                angleOfPhone.isHidden = true
                
                
            case .finish:
                instructionLabel.display(Instructions.finish)
                
                nextButton.isEnabled = true
                nextButton.setTitle("Share", for: [])
                createAlbum.isHidden = true
                
                backButton.setTitle("Restart", for: [])
                backButton.setSecondary()
                
                backButton.isHidden = false
                self.distanceToCurrentlySelectedNodeLabel.isHidden = true
                self.angleOfPhone.isHidden = true
                
                break
            }
            
        }
    }
    
    func switchToPreviousState() {
        switch state {
        case .albumName:
            break
        case .placeDome:
            break
        case .scanning:
            state = .placeDome
            break
        case .detailPhotos:
            state = .scanning
        case .finish:
            state = .detailPhotos
            break
        }
    }
    
    func switchToNextState() {
        switch state {
        case .albumName:
            state = .placeDome
        case .placeDome:
            state = .scanning
            break
        case .scanning:
            state = .detailPhotos
            break
        case .detailPhotos:
            state = .finish
            break
        case .finish:
            break
        }
    }
}
