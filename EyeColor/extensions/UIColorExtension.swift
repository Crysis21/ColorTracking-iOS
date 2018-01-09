//
//  UIColorExtension.swift
//  Anaface
//
//  Created by Cristian Holdunu on 03/04/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: 1
        )
    }
    
    convenience init(argb: UInt) {
        self.init(
            red: CGFloat((argb & 0x00FF0000) >> 16) / 255.0,
            green: CGFloat((argb & 0x0000FF00) >> 8) / 255.0,
            blue: CGFloat(argb & 0x000000FF) / 255.0,
            alpha: CGFloat((argb & 0xFF000000) >> 24) / 255.0
        )
    }
    
    open class var anOrange: UIColor {
        get  {
            return UIColor(rgb: 0xec7123)
        }
    }
    
    open class var anOrangeDark: UIColor {
        get {
            return UIColor(rgb: 0xcf5c14)
        }
    }
    
    open class var anGrey: UIColor {
        get {
            return UIColor(rgb: 0x616161)
        }
    }
    
    
    open class var anDarkGrey: UIColor {
        get {
            return UIColor(rgb: 0x666666)
        }
    }
    var hexString: String {
        let components = self.cgColor.components
        
        let red = Float((components?[0])!)
        let green = Float((components?[1])!)
        let blue = Float((components?[2])!)
        return String(format: "#%02lX%02lX%02lX", lroundf(red * 255), lroundf(green * 255), lroundf(blue * 255))
    }
    
}
