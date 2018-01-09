//
//  CameraViewController.swift
//
//  Created by Cristian Holdunu on 23/03/2017.
//

import UIKit
import AVFoundation
import Photos
import Shimmer
import RxSwift

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var deniedLabel: UIView!
    @IBOutlet weak var changeCameraButton: UIButton!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var faceFrame: UIView!
    
    @IBOutlet weak var tipText: UILabel!
    @IBOutlet weak var shimmerView: FBShimmeringView!
    
    let captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    var activeInput: AVCaptureDeviceInput!
    let imageOutput = AVCapturePhotoOutput()
    fileprivate var deviceAuthorized: Bool  = false
    fileprivate var photoData: Data?
    var disposable: Disposable?
    let sessionQueue = DispatchQueue(label: "com.hold1.camera", qos: .userInitiated)
    
    let tips = ["Use the grid to center your face","Find a good lighting","Take a clear picture of your face", "Make sure your eyes are visible"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        faceFrame.layer.borderColor = UIColor.white.cgColor
        faceFrame.layer.borderWidth = 1
        checkDeviceAuthorizationStatus()
        setupCaptureSession()
        setUpPreview()
        startSession()
        
        shimmerView.contentView = tipText
        shimmerView.isShimmering = true
     
        let scheduler = SerialDispatchQueueScheduler(qos: .default)

        disposable = Observable<Int>.interval(4, scheduler: scheduler)
            .observeOn(MainScheduler.instance)
            .subscribe {
            event in
            self.tipText.text = self.tips[event.element!%self.tips.count]
            print(event)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.disposable?.dispose()
    }
    
    func checkDeviceAuthorizationStatus(){
        let mediaType:String = AVMediaType.video.rawValue;
        AVCaptureDevice.requestAccess(for: AVMediaType(rawValue: mediaType), completionHandler: { (granted: Bool) in
            if granted{
                self.deviceAuthorized = true;
                DispatchQueue.main.async {
                    self.deniedLabel.isHidden = true
                }
            } else {
                DispatchQueue.main.async {
                    self.deniedLabel.isHidden = false
                }
                self.deviceAuthorized = false;
            }
        })
    }
    
    // MARK: - Setup Capture Session & Preview
    func setupCaptureSession() {
        // TODO: check this preset - could be High instead of Photo
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let camera = AVCaptureDevice.default(for: AVMediaType.video)
        
        guard camera != nil else {
            print("no camera available")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: camera!)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                activeInput = input
            }
        } catch {
            print("Error setting up device input: \(error.localizedDescription)")
        }
        // TODO: Check on this one!
        imageOutput.isHighResolutionCaptureEnabled = true
        if captureSession.canAddOutput(imageOutput) {
            captureSession.addOutput(imageOutput)
        }
    }
    
    func setUpPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = cameraPreview.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreview.layer.addSublayer(previewLayer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let connection = self.previewLayer?.connection  {
            let currentDevice: UIDevice = UIDevice.current
            let orientation: UIDeviceOrientation = currentDevice.orientation
            let previewLayerConnection : AVCaptureConnection = connection
            if previewLayerConnection.isVideoOrientationSupported {
                switch (orientation) {
                case .portrait: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                case .landscapeRight: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeLeft)
                    break
                case .landscapeLeft: updatePreviewLayer(layer: previewLayerConnection, orientation: .landscapeRight)
                    break
                case .portraitUpsideDown: updatePreviewLayer(layer: previewLayerConnection, orientation: .portraitUpsideDown)
                    break
                default: updatePreviewLayer(layer: previewLayerConnection, orientation: .portrait)
                    break
                }
            }
        }
    }
    
    private func updatePreviewLayer(layer: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        layer.videoOrientation = orientation
        previewLayer.frame = self.view.bounds
    }
    
    func startSession() {
        if !captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopRunning() {
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    // MARK: - Set Flash
    @IBAction func setFlashMode(_ sender: Any) {
        guard self.deviceAuthorized else {
            return
        }
        if let device = self.activeInput?.device {
            switch device.flashMode {
            case .auto:
                self.setFlashMode(.on, device: device)
            case .off:
                self.setFlashMode(.auto, device: device)
            case .on:
                self.setFlashMode(.off, device: device)
            }
        }
    }
    
    func setFlashMode(_ flashMode: AVCaptureDevice.FlashMode, device: AVCaptureDevice){
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError? = nil
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                switch device.flashMode {
                case AVCaptureDevice.FlashMode.auto:
                    flashBtn.setImage(UIImage(named: "ic_flash_auto"), for: .normal)
                case .off:
                    flashBtn.setImage(UIImage(named: "ic_flash_off"), for: .normal)
                case .on:
                    flashBtn.setImage(UIImage(named: "ic_flash_on"), for: .normal)
                }
            } catch let error1 as NSError {
                error = error1
                print(error!)
            }
        }
    }
    
    
    
    // MARK: - Switch Cameras
    @IBAction func switchCameras(_ sender: UIButton) {
        guard self.deviceAuthorized else {
            return
        }
        if let device = activeInput?.device {
            switch device.position {
            case .front:
                self.changeCameraButton.setImage(UIImage(named: "ic_camera_rear"), for: .normal)
            case .back:
                self.changeCameraButton.setImage(UIImage(named:"ic_camera_front"), for: .normal)
            default:
                self.changeCameraButton.setImage(UIImage(named:"ic_camera_front"), for: .normal)
                
            }
        }
        
        self.sessionQueue.async(execute: {
            let currentVideoDevice:AVCaptureDevice = self.activeInput!.device
            let currentPosition: AVCaptureDevice.Position = currentVideoDevice.position
            var preferredPosition: AVCaptureDevice.Position = AVCaptureDevice.Position.unspecified
            
            switch currentPosition {
            case AVCaptureDevice.Position.front:
                preferredPosition = AVCaptureDevice.Position.back
            case AVCaptureDevice.Position.back:
                preferredPosition = AVCaptureDevice.Position.front
            case AVCaptureDevice.Position.unspecified:
                preferredPosition = AVCaptureDevice.Position.back
            }
            
            
            let device:AVCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: preferredPosition)!
            
            var videoDeviceInput: AVCaptureDeviceInput?
            
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
            } catch _ as NSError {
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(self.activeInput!)
            if self.captureSession.canAddInput(videoDeviceInput!){
                NotificationCenter.default.removeObserver(self, name:NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object:currentVideoDevice)
                DispatchQueue.main.async {
                    self.setFlashMode(AVCaptureDevice.FlashMode.auto, device: device)
                }
                
                //                NotificationCenter.default.addObserver(self, selector: #selector(CameraViewController.deviceSubjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: device)
                self.captureSession.addInput(videoDeviceInput!)
                self.activeInput = videoDeviceInput
            }else{
                self.captureSession.addInput(self.activeInput)
            }
            self.captureSession.commitConfiguration()
        })
    }
    
    // MARK: - Capture Photo
    @IBAction func capturePhoto(_ sender: UIButton) {
        guard self.deviceAuthorized else {
            return
        }
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        self.imageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("will capture photo...")
    }
    
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            self.photoData = photo.fileDataRepresentation()
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "measureViewController") as! ColorMeasurementViewController
            vc.selectedImage = UIImage(data: photoData!)?.fixedOrientation()
            vc.imageData = photoData!
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("test")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        guard error == nil else {
            print("failed to take photo")
            return
        }
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            
            self.photoData = dataImage
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "measureViewController") as! ColorMeasurementViewController
            vc.selectedImage = UIImage(data: photoData!)?.fixedOrientation()
            vc.imageData = photoData!
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
    // MARK: - Helpers
    
    func currentVideoOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = AVCaptureVideoOrientation.portrait
        case .landscapeRight:
            orientation = AVCaptureVideoOrientation.landscapeLeft
        case .portraitUpsideDown:
            orientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            orientation = AVCaptureVideoOrientation.landscapeRight
        }
        
        return orientation
    }
    
}
