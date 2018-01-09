//
//  AVCamPreviewView.swift
//  Anaface
//
//  Created by Cristian Holdunu on 23/03/2017.
//  Copyright © 2017 Atama Group. All rights reserved.
//


import Foundation
import UIKit
import AVFoundation


class AVCamPreviewView: UIView{
    
    var session: AVCaptureSession? {
        get{
            return (self.layer as! AVCaptureVideoPreviewLayer).session;
        }
        set(session){
            (self.layer as! AVCaptureVideoPreviewLayer).session = session;
        }
    };
    
    override class var layerClass :AnyClass{
        return AVCaptureVideoPreviewLayer.self;
    }
    
}
