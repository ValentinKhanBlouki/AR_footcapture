//
//  SaveToPhotoLibrary.swift
//  Wundermental
//
//  Created by Valentin Khan-Blouki on 20.06.23.
//

import UIKit
import Photos


class SaveToPhotoLibrary{
    func saveImageAsHEICToPhotoGallery(_ image: UIImage) {
        guard let imageData = image.heic(compressionQuality: 1.0) else {
            print("Failed to convert image to HEIC data.")
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: imageData, options: nil)
        }) { success, error in
            if let error = error {
                print("Failed to save image as HEIC:", error.localizedDescription)
            } else {
                print("Image saved as HEIC.")
            }
        }
    }
    
}



class Tiff{
    lazy var context = CIContext()
    
    func saveTIFFToPhotoLibrary(_ tiffData: Data) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: tiffData, options: nil)
        }) { success, error in
            if success {
                print("TIFF image saved to photo library successfully.")
            } else {
                print("Error saving TIFF image to photo library: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    
    
    
    func convertToTIFF(_ depthImage: CIImage) -> Data?{
        let colorSpace = CGColorSpace(name: CGColorSpace.linearGray)!
        
        if let depthMapData = context.tiffRepresentation(of: depthImage,
                                                         format: .Lf,
                                                         colorSpace: colorSpace,
                                                         options: [.disparityImage: depthImage]){
            return depthMapData
            
        } else {
            print("colorSpace .linearGray not available... can't save depth data!")
            return nil
        }
    }
}
    




class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save finished!")
    }
  
}


extension UIImage {
    var heic: Data? { heic() }
    func heic(compressionQuality: CGFloat = 1) -> Data? {
        guard
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.heic" as CFString, 1, nil),
            let cgImage = cgImage
        else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: compressionQuality, kCGImagePropertyOrientation: cgImageOrientation.rawValue] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}



extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}

extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation { .init(imageOrientation) }
}

