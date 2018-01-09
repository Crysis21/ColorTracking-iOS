//
//  DetectedColor.swift
//  EyeColor
//
//  Created by Cristian Holdunu on 15/12/2017.
//  Copyright © 2017 Hold1. All rights reserved.
//

import Foundation
import UIKit

class DetectedColor: NSObject {
    var color: UIColor
    var percentage: Double
    
    init(_ color: UIColor, percentage: Double) {
        self.color = color
        self.percentage = percentage
    }
}
