//
//  SplashView.swift
//  EyeColor
//
//  Created by Cristian Holdunu on 05/01/2018.
//  Copyright © 2018 Hold1. All rights reserved.
//

import UIKit

class SplashView: UIView {
    public var bgColor: UIColor = UIColor.white

    public convenience init(frame: CGRect, color: UIColor) {
        self.init(frame: frame)
        self.bgColor = color
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.clear
    }
    
    var centerOfCircle: CGPoint {
        return CGPoint(x:bounds.midX, y:bounds.midY)
    }
    
    var halfSize: CGFloat {
        return min(bounds.size.height, bounds.size.width) / 2 * multiplier - borderWidth
    }
    
    var borderWidth: CGFloat {
        return 0.074 * bounds.size.width
    }
    
    //Circle Radius
    var full = CGFloat(Double.pi*2)
    
    var multiplier:CGFloat = 1.0
    
    
    func drawCircle(at center:CGPoint, withRadius radius: CGFloat) -> UIBezierPath {
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 00, endAngle: full, clockwise: true)
        circlePath.lineWidth = borderWidth
        return circlePath
    }
    
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(bgColor.cgColor)
        
        let rectangle = bounds.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
        
        context.setFillColor(bgColor.cgColor)
        context.addEllipse(in: rectangle)
        context.drawPath(using: .fill)
    }
}
