//
//  FaceView.swift
//  Anaface
//
//  Created by Cristian Holdunu on 31/03/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//

import UIKit
import SwaggerClient

open class FaceView: UIScrollView {
    
    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2
    var cropPreview: UIImageView?
    var zoomView: UIImageView? = nil
    var imageSize: CGSize = CGSize.zero
    fileprivate var pointToCenterAfterResize: CGPoint = CGPoint.zero
    fileprivate var scaleToRestoreAfterResize: CGFloat = 1.0
    fileprivate var maxScaleFromMinScale: CGFloat = 5.0
    fileprivate var viewPoints = [FacePointView]()
    public var anFace: ANFace?
    fileprivate var imageRatio = CGFloat(1.0)
    private var currentImage: UIImage?
    
    fileprivate var pointSize:CGFloat {
        get {
            return realPointSize * zoomScale
        }
    }
    fileprivate var realPointSize: CGFloat {
        get {
            guard anFace != nil else {
                return 36
            }
            return CGFloat(Float(anFace!.width!) / 12.2)
        }
    }
    public var pointTouchDelegate: OnPointTouchDelegate?
    fileprivate var pointDimension: CGRect?
    
    override open var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }
        
        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                recoverFromResizing()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    fileprivate func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
    }
    
    fileprivate func adjustFrameToCenter() {
        
        guard zoomView != nil else {
            return
        }
        
        var frameToCenter = zoomView!.frame
        
        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }
        
        zoomView!.frame = frameToCenter
        
        for pointView in viewPoints {
            guard pointView.facePoint != nil else {
                return
            }
            pointView.frame = CGRect(x: CGFloat(pointView.facePoint!.x!) * zoomScale + frameToCenter.origin.x - pointSize/2,
                                     y: CGFloat(pointView.facePoint!.y!) * zoomScale + frameToCenter.origin.y - pointSize/2,
                                     width: pointSize,
                                     height: pointSize)
        }
        
    }
    
    fileprivate func focusFace() {
        guard anFace != nil else {
            return
        }
        let optimalFaceWidth = 0.6 * bounds.width
        let optimalFaceHeight = 0.65 * bounds.height
        let currentWidth = (anFace?.width)! * Float(zoomScale)
        let currentHeight = (anFace?.height)! * Float(zoomScale)
        
        let correction = CGFloat(min(Float(optimalFaceWidth) / currentWidth, Float(optimalFaceHeight) / currentHeight))
        
        
        let zoomRect = zoomRectForScale(zoomScale * correction,
                                        center: CGPoint(x: CGFloat((anFace?.x)!),
                                                        y: CGFloat((anFace?.y)!)))
        zoom(to: zoomRect, animated: true)
        if let del = pointTouchDelegate {
            del.onTouchEnded()
        }
        
    }
    
    
    fileprivate func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: zoomView)
        
        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    fileprivate func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        
        // restore center point, first making sure it is within the allowable range.
        
        // convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: zoomView)
        
        // calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)
        
        // restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()
        
        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        contentOffset = offset
    }
    
    fileprivate func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width,y:contentSize.height - bounds.height)
    }
    
    fileprivate func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }
    
    // MARK: - Display image
    
    open func display(image: UIImage) {
        
        if let zoomView = zoomView {
            zoomView.removeFromSuperview()
        }
        self.currentImage = image
        zoomView = UIImageView(image: image)
        zoomView!.isUserInteractionEnabled = true
        addSubview(zoomView!)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FaceView.doubleTapGestureRecognizer(_:)))
        tapGesture.numberOfTapsRequired = 2
        zoomView!.addGestureRecognizer(tapGesture)
        
        configureImageForSize(image.size)
        
        imageRatio = self.bounds.size.width / image.size.width
    }
    
    public func setFace(face: ANFace) {
        self.anFace = face
        //MARK: Create logic for adding points
        
        for point in (anFace?.facePoints!)!{
            pointDimension = CGRect(x: CGFloat(point.x!) * zoomScale - pointSize/2,
                                    y: CGFloat(point.y!) * zoomScale - pointSize/2,
                                    width: pointSize,
                                    height: pointSize)
            let pointView = FacePointView(frame: pointDimension!, point: point)
            pointView.isUserInteractionEnabled = true
            addSubview(pointView)
            viewPoints.append(pointView)
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(FaceView.touchFacePoint(_:)))
            pointView.addGestureRecognizer(panGesture)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(FaceView.touchFacePoint(_:)))
            tapGesture.numberOfTapsRequired = 1
            pointView.addGestureRecognizer(tapGesture)
            
        }
        adjustFrameToCenter()
        focusFace()
    }
    
    
    fileprivate func configureImageForSize(_ size: CGSize) {
        imageSize = size
        contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
        contentOffset = CGPoint.zero
    }
    
    fileprivate func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = bounds.height / imageSize.height   // the scale needed to perfectly fit the image height-wise
        
        // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = bounds.height >= bounds.width
        var minScale = (imagePortrait == phonePortrait) ? xScale : min(xScale, yScale)
        
        let maxScale = maxScaleFromMinScale*minScale
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        
        maximumZoomScale = maxScale
        minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }
    
    // MARK: - Gesture
    
    @objc func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        }
        else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(FaceView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale, center: center)
            zoom(to: zoomRect, animated: true)
        }
    }
    
    
    @objc func touchFacePoint(_ gestureRecognizer: UIGestureRecognizer)  {
        if let facePoint = gestureRecognizer.view as? FacePointView {
            if (((gestureRecognizer as? UITapGestureRecognizer) != nil)) ||  gestureRecognizer.state != .ended {
                if let panGestureRecogniser = gestureRecognizer as? UIPanGestureRecognizer {
                    let translation = panGestureRecogniser.translation(in: self)
                    // note: 'view' is optional and need to be unwrapped
                    if let facePointView = gestureRecognizer.view as? FacePointView {
                        let newX = (facePointView.facePoint?.x!)! + Double(translation.x / zoomScale)
                        let newY = (facePointView.facePoint?.y!)! + Double(translation.y / zoomScale)
                        
                        facePointView.center = CGPoint(x: gestureRecognizer.view!.center.x + translation.x, y: gestureRecognizer.view!.center.y + translation.y)
                        facePointView.facePoint?.x! += Double(translation.x / zoomScale)
                        facePointView.facePoint?.y! += Double(translation.y / zoomScale)
                        
                    }
                    panGestureRecogniser.setTranslation(CGPoint.zero, in: self)
                }
                if pointTouchDelegate != nil {
                    pointTouchDelegate?.onPointTouched(facePoint.facePoint!)
                }
            } else {
                if pointTouchDelegate != nil {
                    pointTouchDelegate?.onTouchEnded()
                }
            }
        }
    }
    
    
    fileprivate func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the FaceView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    open func refresh() {
        if let image = zoomView?.image {
            display(image: image)
        }
    }
    
    
    //MARK: - Cut points
    func getPointsArea(accept: @escaping (UIImage) -> Void) {
        let eyesComposition: UIImage?
        var photos = [UIImage]()
        for pointView in self.viewPoints {
            if let point = pointView.facePoint {
                let rect = CGRect(x: CGFloat(point.x!)-realPointSize/2 + 15, y: CGFloat(point.y!)-realPointSize/2 + 15, width: realPointSize - 30, height: realPointSize - 30)
                let scaledRect = CGRect(x: rect.origin.x * (currentImage?.scale)!, y: rect.origin.y * (currentImage?.scale)!, width: rect.size.width * (currentImage?.scale)!, height: rect.size.height * (currentImage?.scale)!)
                let image = circularScaleAndCropImage(UIImage(cgImage: (self.currentImage?.cgImage?.cropping(to: scaledRect))!), frame: rect)
                photos.append(image)
            }
        }
        if (photos.count>1){
            eyesComposition = mergePhotos(left: photos.first!, right: photos.last!)
        } else {
            eyesComposition = photos.first
        }
        self.cropPreview?.image = eyesComposition
        accept(eyesComposition!)
    }
    
    func mergePhotos(left: UIImage, right: UIImage) -> UIImage {
        let newImageWidth  = left.size.width + right.size.width
        let newImageHeight = max(left.size.height, right.size.height)
        let newImageSize = CGSize(width : newImageWidth, height: newImageHeight)
        
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen.main.scale)
        
        let firstImageDrawX  = CGFloat(0)
        let firstImageDrawY  = CGFloat(0)
        
        let secondImageDrawX = left.size.width
        let secondImageDrawY = CGFloat(0)
        
        left .draw(at: CGPoint(x: firstImageDrawX,  y: firstImageDrawY))
        right.draw(at: CGPoint(x: secondImageDrawX, y: secondImageDrawY))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image!
    }
    
    func circularScaleAndCropImage(_ image: UIImage, frame: CGRect) -> UIImage{
        // This function returns a newImage, based on image, that has been:
        // - scaled to fit in (CGRect) rect
        // - and cropped within a circle of radius: rectWidth/2
        //Create the bitmap graphics context
        UIGraphicsBeginImageContextWithOptions(CGSize(width: CGFloat(frame.size.width), height: CGFloat(frame.size.height)), false, 0.0)
        let context: CGContext? = UIGraphicsGetCurrentContext()
        //Get the width and heights
        let imageWidth: CGFloat = image.size.width
        let imageHeight: CGFloat = image.size.height
        let rectWidth: CGFloat = frame.size.width
        let rectHeight: CGFloat = frame.size.height
        //Calculate the scale factor
        let scaleFactorX: CGFloat = rectWidth / imageWidth
        let scaleFactorY: CGFloat = rectHeight / imageHeight
        //Calculate the centre of the circle
        let imageCentreX: CGFloat = rectWidth / 2
        let imageCentreY: CGFloat = rectHeight / 2
        // Create and CLIP to a CIRCULAR Path
        // (This could be replaced with any closed path if you want a different shaped clip)
        let radius: CGFloat = rectWidth / 2
        context?.beginPath()
        context?.addArc(center: CGPoint(x: imageCentreX, y: imageCentreY), radius: radius, startAngle: CGFloat(0), endAngle: CGFloat(2 * Float.pi), clockwise: false)
        context?.closePath()
        context?.clip()
        //Set the SCALE factor for the graphics context
        //All future draw calls will be scaled by this factor
        context?.scaleBy(x: scaleFactorX, y: scaleFactorY)
        // Draw the IMAGE
        let myRect = CGRect(x: CGFloat(0), y: CGFloat(0), width: imageWidth, height: imageHeight)
        image.draw(in: myRect)
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
}

extension FaceView: UIScrollViewDelegate{
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenter()
    }
    
}

public protocol OnPointTouchDelegate {
    func onPointTouched(_ point: FacePoint);
    func onTouchEnded();
}
