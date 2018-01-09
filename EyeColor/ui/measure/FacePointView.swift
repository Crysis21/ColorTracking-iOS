//
//  FacePointView.swift
//  Anaface
//
//  Created by Cristian Holdunu on 31/03/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//

import UIKit

class FacePointView: UIView {
    weak var facePoint:FacePoint?
    
    public init(frame: CGRect, point:FacePoint) {
        super.init(frame: frame)
        self.facePoint = point
        isUserInteractionEnabled = true
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var centerOfCircle: CGPoint {
        return CGPoint(x:bounds.midX, y:bounds.midY)
    }
    
    var halfSize: CGFloat {
        return min(bounds.size.height, bounds.size.width) / 2
    }
    
    var animating = false
    
    var lineWidth = CGFloat(1)
    
    //Circle Radius
    var full = CGFloat(Double.pi*2)
    
    func drawCircle(at center:CGPoint, withRadius radius: CGFloat) -> UIBezierPath {
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: full, clockwise: true)
        return circlePath
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor.red.cgColor)
        context.setStrokeColor(UIColor.blue.cgColor)
        let circlePath = drawCircle(at: centerOfCircle, withRadius: halfSize - lineWidth)
        circlePath.lineWidth = lineWidth
        circlePath.stroke()
    }
    
    public func startAnimating() {
        animating = true
    }
    
    public func stopAnimating() {
        animating = false
    }
}
