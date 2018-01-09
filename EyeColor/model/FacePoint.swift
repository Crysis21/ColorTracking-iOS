//
//  FacePoint.swift
//  Anaface
//
//  Created by Cristian Holdunu on 13/03/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//

open class FacePoint {
    public var id:Int64?
    public var x:Double?
    public var y:Double?
    public var faceId:Int64?
    
    public init(){
        x=0
        y=0
    }
    
    public init(x:Double, y:Double) {
        self.x = x
        self.y = y
    }
}


