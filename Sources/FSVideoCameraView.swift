//
//  FSVideoCameraView.swift
//  Fusuma
//
//  Created by Brendan Kirchner on 3/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol FSVideoCameraViewDelegate: class {
    func videoFinished(withFileURL fileURL: URL)
    func videoViewAllowAccessDidOpenSettings()
}

final class FSVideoCameraView: UIView, FSAllowAccessViewDelegate {
    
    @IBOutlet weak var allowAccessViewContainer: UIView!
    lazy var allowAccessView = FSAllowAccessView.instance()
    public var allowAccessTitle: String?
    public var allowAccessDescription: String?
    public var allowAccessButtonTitle: String?
    public var allowAccessTitleFont: UIFont?
    public var allowAccessDescFont: UIFont?
    public var allowAccessButtonTitleFont: UIFont?
    public var allowAccessTitleColor: UIColor?
    public var allowAccessDescColor: UIColor?
    public var allowAccessButtonTitleColor: UIColor?
    
    @IBOutlet weak var previewViewContainer: UIView!
    @IBOutlet weak var shotButton: UIButton!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    
    weak var delegate: FSVideoCameraViewDelegate? = nil
    
    var session: AVCaptureSession?
    var device: AVCaptureDevice?
    var videoInput: AVCaptureDeviceInput?
    var videoOutput: AVCaptureMovieFileOutput?
    var focusView: UIView?
    
    var flashOffImage: UIImage?
    var flashOnImage: UIImage?
    var videoStartImage: UIImage?
    var videoStopImage: UIImage?
    
    var timer: Timer?
    var timerSeconds: NSInteger = -1
    
    fileprivate var isRecording = false
    
    static func instance() -> FSVideoCameraView {
        
        return UINib(nibName: "FSVideoCameraView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSVideoCameraView
    }
    
    func initialize() {
        
        if session != nil {
            
            return
        }
        
        allowAccessViewContainer.addSubview(allowAccessView)
        allowAccessViewContainer.isHidden = true
        allowAccessView.frame  = CGRect(origin: CGPoint.zero, size: allowAccessViewContainer.frame.size)
        allowAccessView.layoutIfNeeded()
        allowAccessView.initialize()
        allowAccessView.delegate = self
        
        initializeAllowAccesViewForVideView()
                
        self.backgroundColor = UIColor.hex("#FFFFFF", alpha: 1.0)
        
        self.timerLabel.textColor = UIColor.white
        self.timerLabel.isHidden = true
        
        self.isHidden = false
        
        // AVCapture
        session = AVCaptureSession()
        
        for device in AVCaptureDevice.devices() {
            
            if let device = device as? AVCaptureDevice , device.position == AVCaptureDevicePosition.front {
                
                self.device = device
                
                if !device.hasFlash {
                    
                    flashButton.isHidden = true
                }
            }
        }
        
        do {
            
            if let session = session {
                
                videoInput = try AVCaptureDeviceInput(device: device)
                
                session.addInput(videoInput)
                
                videoOutput = AVCaptureMovieFileOutput()
                let totalSeconds = 60.0 //Total Seconds of capture time
                let timeScale: Int32 = 30 //FPS
                
                let maxDuration = CMTimeMakeWithSeconds(totalSeconds, timeScale)
                
                videoOutput?.maxRecordedDuration = maxDuration
                videoOutput?.minFreeDiskSpaceLimit = 1024 * 1024 //SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
                
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
                
                let videoLayer = AVCaptureVideoPreviewLayer(session: session)
                videoLayer?.frame = self.previewViewContainer.bounds
                videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill

                for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio) {
                    let device = device as? AVCaptureDevice
                    let audioInput = try AVCaptureDeviceInput(device: device)
                    session.addInput(audioInput)
                }

                if session.canSetSessionPreset(AVCaptureSessionPreset640x480) {
                    session.sessionPreset = AVCaptureSessionPreset640x480
                }

                self.previewViewContainer.layer.addSublayer(videoLayer!)
                
                session.startRunning()
                
            }
            
            // Focus View
            self.focusView         = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
            let tapRecognizer      = UITapGestureRecognizer(target: self, action: #selector(FSVideoCameraView.focus(_:)))
            self.previewViewContainer.addGestureRecognizer(tapRecognizer)
            
        } catch {
            self.allowAccessViewContainer.isHidden = false
        }
        
        
        let bundle = Bundle(for: self.classForCoder)
        
        flashOnImage = fusumaFlashOnImage != nil ? fusumaFlashOnImage : UIImage(named: "ic_flash_on", in: bundle, compatibleWith: nil)
        flashOffImage = fusumaFlashOffImage != nil ? fusumaFlashOffImage : UIImage(named: "ic_flash_off", in: bundle, compatibleWith: nil)
        let flipImage = fusumaFlipImage != nil ? fusumaFlipImage : UIImage(named: "ic_loop", in: bundle, compatibleWith: nil)
        videoStartImage = fusumaVideoStartImage != nil ? fusumaVideoStartImage : UIImage(named: "video_button", in: bundle, compatibleWith: nil)
        videoStopImage = fusumaVideoStopImage != nil ? fusumaVideoStopImage : UIImage(named: "video_button_rec", in: bundle, compatibleWith: nil)
        
        
        if(fusumaTintIcons) {
            flashButton.tintColor = fusumaBaseTintColor
            flipButton.tintColor  = fusumaBaseTintColor
            shotButton.tintColor  = fusumaBaseTintColor
            
            flashButton.setImage(flashOffImage?.withRenderingMode(.alwaysOriginal), for: UIControlState())
            flipButton.setImage(flipImage?.withRenderingMode(.alwaysOriginal), for: UIControlState())
            shotButton.setImage(videoStartImage?.withRenderingMode(.alwaysOriginal), for: UIControlState())
        } else {
            flashButton.setImage(flashOffImage, for: UIControlState())
            flipButton.setImage(flipImage, for: UIControlState())
            shotButton.setImage(videoStartImage, for: UIControlState())
        }
        
        flashConfiguration()
        
        self.startCamera()
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
    }
    
    public func initializeAllowAccesViewForVideView() {
        
        allowAccessView.allowAccessButton.titleLabel?.font = allowAccessButtonTitleFont
        allowAccessView.allowAccessButton.setTitle(allowAccessButtonTitle, for: .normal)
        allowAccessView.allowAccessButton.setTitleColor(allowAccessButtonTitleColor, for: .normal)
        
        allowAccessView.allowAccessTitleLabel.text = allowAccessTitle
        allowAccessView.allowAccessTitleLabel.textColor = allowAccessTitleColor
        allowAccessView.allowAccessTitleLabel.font = allowAccessTitleFont
        
        allowAccessView.allowAccessTextLabel.text = allowAccessDescription
        allowAccessView.allowAccessTextLabel.textColor = allowAccessDescColor
        allowAccessView.allowAccessTextLabel.font = allowAccessDescFont
        
    }
    
    public func allowAccessDidOpenSettings() {
        
        delegate?.videoViewAllowAccessDidOpenSettings()
    }
    func startCamera() {
        
        let statusForVideo = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        let statusForMicrophone = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeAudio)
        
        if statusForVideo == AVAuthorizationStatus.authorized && statusForMicrophone == AVAuthorizationStatus.authorized {

            //self.allowAccessViewContainer.isHidden = true
            session?.startRunning()
            
        } else if (statusForVideo == AVAuthorizationStatus.denied || statusForVideo == AVAuthorizationStatus.restricted) &&
            (statusForMicrophone == AVAuthorizationStatus.denied || statusForMicrophone == AVAuthorizationStatus.restricted)
            {
            //self.allowAccessViewContainer.isHidden = false
            session?.stopRunning()
        }
    }
    
    func stopCamera() {
        if self.isRecording {
            self.toggleRecording()
        }
        session?.stopRunning()
    }
    
    @IBAction func shotButtonPressed(_ sender: UIButton) {
        
        self.toggleRecording()
    }
    
    fileprivate func toggleRecording() {
        guard let videoOutput = videoOutput else {
            return
        }
        
        self.isRecording = !self.isRecording
        
        let shotImage: UIImage?
        if self.isRecording {
            shotImage = videoStopImage
        } else {
            shotImage = videoStartImage
        }
        self.shotButton.setImage(shotImage, for: UIControlState())
        
        if self.isRecording {
            let outputPath = "\(NSTemporaryDirectory())output.mov"
            let outputURL = URL(fileURLWithPath: outputPath)
            
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: outputPath) {
                do {
                    try fileManager.removeItem(atPath: outputPath)
                } catch {
                    print("error removing item at path: \(outputPath)")
                    self.isRecording = false
                    return
                }
            }
            self.flipButton.isEnabled = false
            self.flashButton.isEnabled = false
            self.timerLabel.isHidden = false
            videoOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
        } else {
            videoOutput.stopRecording()
            self.flipButton.isEnabled = true
            self.flashButton.isEnabled = true
            self.timerLabel.isHidden = true
        }
        return
    }
    
    @IBAction func flipButtonPressed(_ sender: UIButton) {
        
        session?.stopRunning()
        
        do {
            
            session?.beginConfiguration()
            
            if let session = session {
                
                for input in session.inputs {
                    
                    session.removeInput(input as! AVCaptureInput)
                }
                
                let position = (videoInput?.device.position == AVCaptureDevicePosition.front) ? AVCaptureDevicePosition.back : AVCaptureDevicePosition.front
                
                for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
                    
                    if let device = device as? AVCaptureDevice , device.position == position {
                        
                        videoInput = try AVCaptureDeviceInput(device: device)
                        session.addInput(videoInput)
                        
                    }
                }

                for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio) {
                    let device = device as? AVCaptureDevice
                    let audioInput = try! AVCaptureDeviceInput(device: device)
                    session.addInput(audioInput)
                }

                if session.canSetSessionPreset(AVCaptureSessionPreset640x480) {
                    session.sessionPreset = AVCaptureSessionPreset640x480
                }
                
            }
            
            session?.commitConfiguration()
            
            
        } catch {
            
        }
        
        session?.startRunning()
    }
    
    @IBAction func flashButtonPressed(_ sender: UIButton) {
        
        do {
            
            if let device = device {
                
                guard device.hasFlash else { return }
                
                try device.lockForConfiguration()
                
                
                let mode = device.flashMode
                
                if mode == AVCaptureFlashMode.off {
                    device.flashMode = AVCaptureFlashMode.on
                    flashButton.setImage(flashOnImage, for: UIControlState())
                    
                } else if mode == AVCaptureFlashMode.on {
                    device.flashMode = AVCaptureFlashMode.off
                    flashButton.setImage(flashOffImage, for: UIControlState())
                }
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            flashButton.setImage(flashOffImage, for: UIControlState())
            return
        }
        
    }
    
    func startTimer() {
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    func stopTimer() {
        
        self.timer?.invalidate()
    }
    
    func timerTick() {
        
        self.timerSeconds += 1
        self.timerLabel.text = self.timerSeconds.description
        
    }
}


extension FSVideoCameraView: AVCaptureFileOutputRecordingDelegate {
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        print("started recording to: \(fileURL)")
        self.startTimer()
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        print("finished recording to: \(outputFileURL)")

        self.delegate?.videoFinished(withFileURL: outputFileURL)
        self.stopTimer()
    }
    
}

extension FSVideoCameraView {
    
    func focus(_ recognizer: UITapGestureRecognizer) {
        
        let point = recognizer.location(in: self)
        let viewsize = self.bounds.size
        let newPoint = CGPoint(x: point.y/viewsize.height, y: 1.0-point.x/viewsize.width)
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            
            try device?.lockForConfiguration()
            
        } catch _ {
            
            return
        }
        
        if device?.isFocusModeSupported(AVCaptureFocusMode.autoFocus) == true {
            
            device?.focusMode = AVCaptureFocusMode.autoFocus
            device?.focusPointOfInterest = newPoint
        }
        
        if device?.isExposureModeSupported(AVCaptureExposureMode.continuousAutoExposure) == true {
            
            device?.exposureMode = AVCaptureExposureMode.continuousAutoExposure
            device?.exposurePointOfInterest = newPoint
        }
        
        device?.unlockForConfiguration()
        
        self.focusView?.alpha = 0.0
        self.focusView?.center = point
        self.focusView?.backgroundColor = UIColor.clear
        self.focusView?.layer.borderColor = UIColor.white.cgColor
        self.focusView?.layer.borderWidth = 1.0
        self.focusView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        self.addSubview(self.focusView!)
        
        UIView.animate(withDuration: 0.8, delay: 0.0, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 3.0, options: UIViewAnimationOptions.curveEaseIn, // UIViewAnimationOptions.BeginFromCurrentState
            animations: {
                self.focusView!.alpha = 1.0
                self.focusView!.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            }, completion: {(finished) in
                self.focusView!.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.focusView!.removeFromSuperview()
        })
    }
    
    func flashConfiguration() {
        
        do {
            
            if let device = device {
                
                guard device.hasFlash else { return }
                
                try device.lockForConfiguration()
                
                if device.isFlashModeSupported(AVCaptureFlashMode.off) {
                    device.flashMode = AVCaptureFlashMode.off
                }
                
                flashButton.setImage(flashOffImage, for: UIControlState())
                
                device.unlockForConfiguration()
                
            }
            
        } catch _ {
            
            return
        }
    }
}
