//
//  ResultViewController.swift
//  EyeColor
//
//  Created by Cristian Holdunu on 16/12/2017.
//  Copyright © 2017 Hold1. All rights reserved.
//

import UIKit
import SwaggerClient
import Nuke
import NVActivityIndicatorView
import Photos

class ResultViewController: UIViewController {
    
    @IBOutlet weak var loadingView: NVActivityIndicatorView!
    @IBOutlet weak var faceView: FaceView!
    
    var whitePhoto: WhiteImage?
    var selectedColor: UIColor?
    var detectedColors: [DetectedColor]?
    var graphImage: UIImage?
    var backgroundImage: UIImage? {
        didSet {
            guard subjectImage != nil, backgroundImage != nil else {
                print("images not ready")
                return
            }
            renderResult()
        }
    }
    var subjectImage: UIImage? {
        didSet {
            guard subjectImage != nil, backgroundImage != nil else {
                print("images not ready")
                return
            }
            renderResult()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView.startAnimating()
        guard whitePhoto != nil else {
            return
        }
        
        Manager.shared.loadImage(with: URL(string: (whitePhoto?.backgroundUrl)!)!) { image in
            self.backgroundImage = image.value
        }
        
        Manager.shared.loadImage(with: URL(string: (whitePhoto?.subjectUrl)!)!) { image in
            self.subjectImage = image.value
        }
    }
    
    private func renderResult() {
        loadingView.stopAnimating()
        let image = mergePhotos(background: self.backgroundImage!, subject: drawCircles(image: self.subjectImage!))
        self.faceView.display(image: image)
    }
    
    private func mergePhotos(background: UIImage, subject: UIImage) -> UIImage{
        let newImageWidth  = max(background.size.width, subject.size.width)
        let newImageHeight = max(background.size.height, subject.size.height)
        let newImageSize = CGSize(width : newImageWidth, height: newImageHeight)
        
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen.main.scale)
        
        let startX  = CGFloat(0)
        let startY  = CGFloat(0)
        
        background .draw(at: CGPoint(x: startX,  y: startY))
        subject.draw(at: CGPoint(x: startX, y: startY))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    private func drawCircles(image: UIImage) -> UIImage {
        let render = UIGraphicsImageRenderer(size: image.size)
        let drawImage = render.image(actions: {(context) in
            image.draw(at: CGPoint.zero)
            
            let baseSize = 0.1 * image.size.height
            
            for drawColor in detectedColors! {
                
                var x = 0
                var y = 0
                x = Int(arc4random_uniform(UInt32(image.size.width)))
                y = Int(arc4random_uniform(UInt32(image.size.height)))
                
                let size = baseSize + CGFloat(drawColor.percentage) * baseSize / 100
                let splashView  = SplashView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: size, height: size)), color: drawColor.color)
                
                let layer = CGLayer(context.cgContext, size: CGSize(width:size, height:size), auxiliaryInfo: nil);
                splashView.layer.draw(in: (layer?.context)!)
                
                context.cgContext.draw(layer!, at: CGPoint(x: x, y: y))
            }
            
        })
        
        return drawImage
    }
    
    @IBAction func savePictures(_ sender: Any) {
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.savePhotos()
        } else if PHPhotoLibrary.authorizationStatus() == .notDetermined {
            PHPhotoLibrary.requestAuthorization { [weak self] (status) in
                if status == .authorized {
                    DispatchQueue.main.async {
                        self?.savePhotos()
                    }
                } else{
                    DispatchQueue.main.async {
                        print("failed to save photos")
                    }
                }
            }
        } else {
            print("failed to save photos")
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func savePhotos() {
        if let image = graphImage {
            savePhotoToLibrary(image: image)
        }
        if let image = self.faceView.zoomView?.image {
            savePhotoToLibrary(image: image)
        }
    }
    
    func savePhotoToLibrary(image: UIImage) {
        let photoLibrary = PHPhotoLibrary.shared()
        photoLibrary.performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (success: Bool, error: Error?) -> Void in
            if success {
                // Set thumbnail
            } else {
                print("Error writing to photo library: \(error!.localizedDescription)")
            }
        }
    }
    
}
