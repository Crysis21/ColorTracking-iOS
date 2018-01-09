//
//  ImageService.swift
//  PlayerFramework
//
//  Created by Florian Preknya on 2/28/16.
//  Copyright © 2016 AudioNow Digital. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage

protocol ImageService {
    func imageFromURL(_ URL: URL) -> Observable<UIImage?>
    func imageSizeFromURL(_ URL: URL) -> CGSize?
    func setImageSizeForURL(_ size: CGSize, URL: URL) -> Void
}

class DefaultImageService: ImageService {
    
    static let sharedInstance = DefaultImageService() // Singleton
    
    fileprivate var _imageSizeCache: [String : CGSize] = [:]
    
    fileprivate init() {
    }
    
    internal func imageFromURL(_ URL: URL) -> Observable<UIImage?> {
        
        return Observable.deferred {
            
            let imageQuery: Observable<UIImage?> = Observable.create { observer -> Disposable in
                
                if !["http", "https"].contains(URL.scheme ?? "") {
                    
                    // serve ONLY images from valid network URLs!
                    observer.on(.next(nil))
                    observer.on(.completed)
                }
                
                let task = SDWebImageManager.shared().loadImage(with: URL as URL!, options: [], progress: nil, completed: { (image, data, error, cached, finished, url) in
                    if error != nil {
                        observer.on(.error(error!))
                    } else {
                        observer.on(.next(image))
                        observer.on(.completed)
                    }
                })
                return Disposables.create {
                    task?.cancel()
                }
            }
            
            return imageQuery.do(onNext: { image in
                if let image = image {
                    self.setImageSizeForURL(image.size, URL: URL)
                }
            })
        }
    }
    
    func imageSizeFromURL(_ URL: Foundation.URL) -> CGSize?
    {
        return _imageSizeCache[URL.absoluteString]
    }
    
    func setImageSizeForURL(_ size: CGSize, URL: Foundation.URL) -> Void {
        DispatchQueue.main.async {
            self._imageSizeCache[URL.absoluteString] = size
        }
    }
}

