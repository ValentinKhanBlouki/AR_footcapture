//
//  SaveToPhotoLibrary.swift
//  Wundermental
//
//  Created by Valentin Khan-Blouki on 20.06.23.
//

import UIKit
import Photos


import Photos

class PhotoManager {
static let instance = PhotoManager()
var folder: PHCollectionList?

/// Fetches an existing folder with the specified identifier or creates one with the specified name
func fetchFolderWithIdentifier(_ identifier: String, name: String) {
    let fetchResult = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [identifier], options: nil)
    guard let folder = fetchResult.firstObject else {
        createFolderWithName(name)
        return
    }

    self.folder = folder
}

/// Creates a folder with the specified name
private func createFolderWithName(_ name: String) {
    var placeholder: PHObjectPlaceholder?

    PHPhotoLibrary.shared().performChanges({
        let changeRequest = PHCollectionListChangeRequest.creationRequestForCollectionList(withTitle: name)
        placeholder = changeRequest.placeholderForCreatedCollectionList
    }) { (success, error) in
        guard let placeholder = placeholder else { return }
        let fetchResult = PHCollectionList.fetchCollectionLists(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
        guard let folder = fetchResult.firstObject else { return }

        self.folder = folder
    }
}

/// Creates an album with the specified name
func createAlbumWithName(_ name: String, completion: @escaping (PHAssetCollection?) -> Void) {
    guard let folder = folder else {
        completion(nil)
        return
    }

    var placeholder: PHObjectPlaceholder?
    PHPhotoLibrary.shared().performChanges({
        let listRequest = PHCollectionListChangeRequest(for: folder)
        let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
        listRequest?.addChildCollections([createAlbumRequest.placeholderForCreatedAssetCollection] as NSArray)
        placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
    }) { (success, error) in
        guard let placeholder = placeholder else {
            completion(nil)
            return
        }

        let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
        let album = fetchResult.firstObject
        completion(album)
    }
}

/// Saves the image to a new album with the specified name
func saveImageToAlbumInRootFolder(_ albumName: String, image: UIImage?, completion: @escaping (Error?) -> Void) {
    createAlbumWithName(albumName) { (album) in
        guard let album = album else {
            return
        }

        PHPhotoLibrary.shared().performChanges({
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image!)
            let photoPlaceholder = createAssetRequest.placeholderForCreatedAsset!
            albumChangeRequest?.addAssets([photoPlaceholder] as NSArray)
        }, completionHandler: { (success, error) in
            if success {
                completion(nil)
            } else if let error = error {
                // Failed with error
            } else {
                // Failed with no error
            }
        })
    }
}}

class Album{
    
    func createAlbum(withTitle title: String, completion: @escaping (PHAssetCollection?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            let placeholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }) { success, error in
            if success {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", title)
                let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions).firstObject
                completion(collection)
            } else {
                print("Error creating album: \(String(describing: error))")
                completion(nil)
            }
        }
    }
    
    
    
    func saveImageToAlbum(image: UIImage, album: PHAssetCollection, completion: @escaping (Bool, Error?) -> Void) {
        
        guard let imageData = image.heic(compressionQuality: 1.0) else {
            print("Failed to convert image to HEIC data.")
            return
        }
        PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let createOptions:PHAssetResourceCreationOptions = PHAssetResourceCreationOptions()
            creationRequest.addResource(with: .photo, data: imageData, options: createOptions)


            guard let assetPlaceholder = creationRequest.placeholderForCreatedAsset else {
                completion(false, nil)
                return
            }
            
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
            albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
            
        }) { success, error in
            completion(success, error)
        }
    }
}

    



class Tiff{
    lazy var context = CIContext()
    
    func saveTIFFToPhotoLibrary(_ tiffData: Data, name: String) {
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let createOptions:PHAssetResourceCreationOptions = PHAssetResourceCreationOptions()
            createOptions.originalFilename = name;
            request.addResource(with: .photo, data: tiffData, options: createOptions)
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
                                                         options: [.depthImage: depthImage]){
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

