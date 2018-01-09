//
//  ReachabilityService.swift
//  RxExample
//
//  Created by Vodovozov Gleb on 10/22/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if !RX_NO_MODULE
    import RxSwift
#endif
import Foundation

public enum ReachabilityStatus {
    case reachable(viaWiFi: Bool)
    case unreachable
}

extension ReachabilityStatus {
    var reachable: Bool {
        switch self {
        case .reachable:
            return true
        case .unreachable:
            return false
        }
    }
}

protocol ReachabilityService {
    var reachability: Observable<ReachabilityStatus> { get }
}

class DefaultReachabilityService
: ReachabilityService {
    
    fileprivate let _reachabilitySubject: BehaviorSubject<ReachabilityStatus>?
    
    var reachability: Observable<ReachabilityStatus> {
        return _reachabilitySubject?.asObservable() ?? Observable.never()
    }
    
    let _reachability: Reachability?
    
    
    // singleton
    static let sharedInstance = try! DefaultReachabilityService()
    
    init() throws {
        
        var reachabilitySubject: BehaviorSubject<ReachabilityStatus>?
        
        let reachabilityRef = Reachability()
        if let reachabilityRef = reachabilityRef {
            
            reachabilitySubject = BehaviorSubject<ReachabilityStatus>(value: .unreachable)
            
            // so main thread isn't blocked when reachability via WiFi is checked
            let backgroundQueue = DispatchQueue(label: "reachability.wificheck", attributes: [])
            
            reachabilityRef.whenReachable = { reachability in
                print("Reachability is ON!")
                backgroundQueue.async {
                    reachabilitySubject?.on(.next(.reachable(viaWiFi: reachabilityRef.isReachableViaWiFi)))
                }
            }
            
            reachabilityRef.whenUnreachable = { reachability in
                print("Reachability is OFF!")
                backgroundQueue.async {
                    reachabilitySubject?.on(.next(.unreachable))
                }
            }
            
            try reachabilityRef.startNotifier()
        }
        
        _reachability = reachabilityRef
        _reachabilitySubject = reachabilitySubject
    }
    
    deinit {
        _reachability?.stopNotifier()
    }
}

extension NSObject {
    
    // trigger for a closure (some code) called ONLY when there is a current station (with user interface)
    func whenReachabilityChanges(_ closure: @escaping (ReachabilityStatus) -> Void) {
        
        let _ = DefaultReachabilityService.sharedInstance.reachability
            .takeUntil(self.rx.deallocated)
            .subscribe(onNext: { reachabilityStatus in
                closure(reachabilityStatus)
            })
    }
}

extension NSError {
    
    var isConnectionRelated: Bool {
        return code >= -1022 && code <= -998
    }
}

extension ObservableConvertibleType {
    func retryOnBecomesReachable(valueOnFailure: E? = nil) -> Observable<E> {
        return self.asObservable()
            .catchError({ (e) -> Observable<E> in
                
                // when reachability is regained, retry ONLY for errors that were connection related
                if (e as NSError).isConnectionRelated {
                    var observableResult: Observable<E> =
                        DefaultReachabilityService.sharedInstance.reachability
                            .filter { $0.reachable }
                            .flatMap { _ in Observable.error(e) }
                    
                    if let valueOnFailure = valueOnFailure {
                        observableResult = observableResult.startWith(valueOnFailure)
                    }
                    
                    return observableResult
                } else {
                    return Observable.error(e)
                }
            })
            .retryWhen({ (errorObservable: Observable<Error>) -> Observable<E?> in
                errorObservable.flatMap { e -> Observable<E?> in
                    if (e as NSError).isConnectionRelated {
                        // retry (after 0.5 seconds)!
                        return Observable.just(nil).delay(0.5, scheduler: MainScheduler.instance)
                    } else {
                        // do not retry, just throw the error further!
                        return Observable.error(e)
                    }
                }
            })
        
    }
}

