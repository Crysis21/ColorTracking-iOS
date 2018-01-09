//
//  ColorMeasurementViewController.swift
//  EyeColor
//
//  Created by Cristian Holdunu on 15/12/2017.
//  Copyright © 2017 Hold1. All rights reserved.
//

import UIKit
import Charts
import Shimmer

class ColorMeasurementViewController: UIViewController, ChartViewDelegate, OnPointTouchDelegate {
    
    public var selectedImage: UIImage?
    public var imageData: Data?
    private var detectedColors = [DetectedColor]()
    
    @IBOutlet weak var chartView: PieChartView!
    @IBOutlet weak var selectedColor: UIView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var faceView: FaceView!
    @IBOutlet weak var cropPreview: UIImageView!
    
    @IBOutlet weak var tipText: UILabel!
    @IBOutlet weak var shimmerView: FBShimmeringView!
    override func viewDidLoad() {
        super.viewDidLoad()
        faceView.cropPreview = self.cropPreview
        faceView.display(image: selectedImage!)
        faceView.pointTouchDelegate = self
        chartView.delegate = self
        
        continueBtn.layer.cornerRadius = 4
        applyButtonShadow(continueBtn)
        detectFaces()
        
    }
    
    
    func detectFaces() {
        let context = CIContext()
        let options: [String : Any] = [CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
                                       CIDetectorAccuracy: CIDetectorAccuracyHigh,
                                       CIDetectorEyeBlink: true]
    
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: options)
        let processImage = CIImage(cgImage: (selectedImage?.cgImage)!)
        let faces = faceDetector?.features(in: processImage)
        guard faces?.first != nil else {
            print("no face detected")
            self.detectColors(self.selectedImage!)
            return
        }
        
        let face = faces?.first as! CIFaceFeature
        let imageSize = selectedImage?.size
        
        let anFace = ANFace()
        anFace.bounds = convertRect(size: imageSize!, rect: face.bounds)
        if face.hasLeftEyePosition && !face.leftEyeClosed {
            let point = convertPoint(size: imageSize!, point: face.leftEyePosition)
            let leftEye = FacePoint(x: Double(point.x), y: Double(point.y))
            anFace.facePoints?.append(leftEye)
        }
        if face.hasRightEyePosition && !face.rightEyeClosed {
            let point = convertPoint(size: imageSize!, point: face.rightEyePosition)
            let rightEye = FacePoint(x: Double(point.x), y: Double(point.y))
            anFace.facePoints?.append(rightEye)
        }
        faceView.setFace(face: anFace)
    }
    
    func detectColors(_ image: UIImage) {
        detectedColors.removeAll()
        DispatchQueue.global(qos: .default).async {
            let start = Date()
            let pallete = ColorThief.getColorMap(from: image, colorCount: 10, ignoreWhite: true)?.makePalette()
            let elapsed = -start.timeIntervalSinceNow
            NSLog("time for getColorFromImage: \(Int(elapsed * 1000.0))ms")
            for i in 0 ..< (pallete?.count)! {
                let detColor = DetectedColor(pallete![i].makeUIColor(), percentage: Double(pallete![i].dominance * 100))
                self.detectedColors.append(detColor)
            }
            DispatchQueue.main.async {
                self.renderColors()
                self.selectedColor.backgroundColor = self.detectedColors.first?.color
            }
        }
        
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeLeft:
            return 3
        case .landscapeRight:
            return 1
        default:
            return 6
        }
    }

    
    fileprivate func applyButtonShadow(_ button: UIView) {
        
        button.layer.shadowColor = UIColor.lightGray.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        button.layer.shadowRadius = 1.0
        button.layer.shadowOpacity = 0.5
        button.layer.masksToBounds = false
        button.layer.shadowPath = UIBezierPath(roundedRect: button.bounds, cornerRadius: button.layer.cornerRadius).cgPath
    }
    
    func renderColors() {
        //MARK: prepare chartview UI
        chartView.delegate = self
//        chartView.dragEnabled = true
//        chartView.setScaleEnabled(true)
//        chartView.pinchZoomEnabled = true
//        chartView.drawGridBackgroundEnabled = false
//        chartView.highlightPerDragEnabled = false
//        chartView.scaleYEnabled = false
//        chartView.scaleXEnabled = true
        
//        let xAxis = chartView.xAxis
//        xAxis.labelPosition = .bottom
//        xAxis.labelTextColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
//        xAxis.drawAxisLineEnabled = false
//        xAxis.drawGridLinesEnabled = false
//        xAxis.drawLimitLinesBehindDataEnabled = false
//        xAxis.avoidFirstLastClippingEnabled = true
//        xAxis.granularity = 1.0
//        xAxis.spaceMin = xAxis.granularity / 2
//        xAxis.spaceMax = xAxis.granularity / 2
        
//        let rightAxis = chartView.leftAxis
//        rightAxis.labelPosition = .outsideChart
//        rightAxis.gridLineWidth = 0.2
//        rightAxis.labelTextColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
//        rightAxis.drawGridLinesEnabled = true
//        rightAxis.granularityEnabled = false
//        rightAxis.drawAxisLineEnabled=false
//        rightAxis.axisMinimum = 0
//
//        chartView.rightAxis.enabled = false
        chartView.chartDescription?.enabled=false
//        chartView.legend.enabled=false
        chartView.setExtraOffsets(left: 0, top: 0, right: 0, bottom: 0)
        
        //render numbers chart
        var chartEntries = [PieChartDataEntry] ()
        for i in 0 ..< detectedColors.count {
            let stat = detectedColors[i]
//            let entry = PieChartDataEntry(x: Double(i), y: stat.percentage)
            let entry = PieChartDataEntry(value: stat.percentage, label: "\(stat.color.hexString)")
            chartEntries.append(entry)
        }
        let dataSet = PieChartDataSet(values: chartEntries, label: "Eye Colours")
        let lineData = PieChartData(dataSet: dataSet)
        
        dataSet.entryLabelColor = UIColor.clear
        dataSet.valueTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        dataSet.colors = detectedColors.map{$0.color}
        dataSet.selectionShift = CGFloat(5)
        
        chartView.data = lineData
        chartView.data?.setDrawValues(true)
        chartView.legend.drawInside=true
        chartView.legend.orientation = .vertical
        chartView.legend.verticalAlignment = .center
        //        let dates = workout?.data?.flatMap({element in return element.date})
        //        chartView.xAxis.valueFormatter = DateValueFormatter(dates: dates!)
    }
    
    //MARK - listen to chart value selection
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        if let pieEntry = entry as? PieChartDataEntry {
            selectedColor.backgroundColor = hexStringToUIColor(hex: pieEntry.label!)
        } else {
         selectedColor.backgroundColor = detectedColors[Int(entry.x)].color
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoSelectorViewController {
            vc.drawColor = self.selectedColor.backgroundColor
            vc.detectedColors = self.detectedColors
            vc.graphImage = self.view.screenshot()
        }
    }
    
    func imageOrientationToTiffOrientation(value: UIImageOrientation) -> Int32
    {
        switch (value)
        {
        case .up:
            return 1
        case .down:
            return 3
        case .left:
            return 8
        case .right:
            return 6
        case .upMirrored:
            return 2
        case .downMirrored:
            return 4
        case .leftMirrored:
            return 5
        case .rightMirrored:
            return 7
        }
    }
    
    private func convertRect(size: CGSize, rect: CGRect) -> CGRect {
        var rect = rect
        rect.origin.y = size.height - rect.origin.y - rect.height
        return rect
    }
    
    private func convertPoint(size: CGSize, point: CGPoint) -> CGPoint {
        var point = point
        point.y = size.height - point.y
        return point
    }
    
    //MARK - callbacks for point touch on FaceView

    func onPointTouched(_ point: FacePoint) {
        
    }
    
    func onTouchEnded() {
        self.faceView.getPointsArea(accept: {image in
            self.detectColors(image)
        })
    }
    
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
