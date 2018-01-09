//
//  RxAPI.swift
//  Anaface
//
//  Created by Cristian Holdunu on 11/04/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//

import Foundation
import SwaggerClient
import RxSwift
import RxCocoa

extension SwaggerClientAPI {
    
    class func rx_call<O>(_ call: @escaping (_ completion: @escaping ((_ data: O?,_ error: Error?) -> Void)) -> Void) -> Observable<O> {
        
        return Observable.create({ observer in
            
            call() { (data, error) -> Void in
                
                if error != nil || data == nil {
                    observer.on(.error(error!))
                } else {
                    observer.on(.next(data!))
                    observer.on(.completed)
                }
            }
            
            return Disposables.create {
            }
        })
    }
    
    class func rx_call<P1, O>(_ call: @escaping (P1, _ completion: @escaping ((_ data: O?,_ error: Error?) -> Void)) -> Void, p1: P1) -> Observable<O> {
        
        return Observable.create({ observer in
            
            call(p1) { (data, error) -> Void in
                
                if error != nil || data == nil {
                    observer.on(.error(error!))
                } else {
                    observer.on(.next(data!))
                    observer.on(.completed)
                }
            }
            
            return Disposables.create()
        })
    }
    
    class func rx_call<P1, P2, O>(_ call: @escaping (P1, P2, _ completion: @escaping ((_ data: O?,_ error: Error?) -> Void)) -> Void, p1: P1, p2: P2) -> Observable<O> {
        
        return Observable.create({ observer in
            
            call(p1, p2) { (data, error) -> Void in
                
                if error != nil || data == nil {
                    observer.on(.error(error!))
                } else {
                    observer.on(.next(data!))
                    observer.on(.completed)
                }
            }
            
            return Disposables.create()
        })
        
    }
    
}

