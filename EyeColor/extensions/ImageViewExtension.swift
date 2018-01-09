//
//  ImageViewExtension.swift
//  Anaface
//
//  Created by Cristian Holdunu on 11/04/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//


import Foundation
import RxSwift

extension UIImageView {
    
    @nonobjc
    fileprivate func imageFromURL(_ url: URL?, transitionType: String? = nil, completion: ((UIImage?) -> Void)? = nil) {
        
        guard let url = url else {
            return
        }
        
        // dispose the previous image request (if any!)
        self.rxImageRequest?.dispose()
        
        // start a new image request
        self.rxImageRequest = DefaultImageService.sharedInstance.imageFromURL(url)
            .observeOn(MainScheduler.instance)
            .retryOnBecomesReachable()
            .take(1)
            .asDriver(onErrorJustReturn: nil)
            .do(onNext: { image in
                completion?(image)
            })
            .drive(self.rx.image(transitionType: transitionType))
    }
    
    @nonobjc
    func imageFromURL(_ urlString: String?, transitionType: String? = nil, completion: ((UIImage?) -> Void)? = nil) {
        
        if let urlString = urlString, urlString.starts(with: "resource:") {
            let resourceName = urlString.replacingOccurrences(of: "resource:", with: "")
            imageFromBundle(resourceName)
            completion?(image)
            return
        }
        
        if let urlString = urlString?.URLEscaped, let url = URL(string: urlString) {
            imageFromURL(url, transitionType: transitionType, completion: completion)
        }
    }
    
    func imageFromBundle(_ imageName: String?, renderingMode: UIImageRenderingMode? = nil) {
        
        guard let imageName = imageName else {
            return
        }
        
        var image = UIImage(named: imageName, in: Bundle(for: AppDelegate.self), compatibleWith: nil)
        if renderingMode != nil {
            image = image?.withRenderingMode(renderingMode!)
        }
        
        self.image = image
    }
    
    //////////////////////////////
    // implementation details...
    
    fileprivate class DisposableHolder {
        let value: Disposable?
        init(value: Disposable?) {
            self.value = value
        }
    }
    
    fileprivate var rxImageRequest: Disposable? {
        
        get {
            return (objc_getAssociatedObject(self, &AssociatedKey.rxImageRequest) as? DisposableHolder)?.value
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKey.rxImageRequest, DisposableHolder(value: newValue), .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    fileprivate struct AssociatedKey {
        static var rxImageRequest: UInt8 = 0
    }
}


extension String {
    var URLEscaped: String {
        
        let unescaped = self.removingPercentEncoding?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let escaped = unescaped?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return escaped
    }
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                substring(with: substringFrom..<substringTo)
            }
        }
    }
}

