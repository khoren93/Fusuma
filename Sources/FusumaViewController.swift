//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit
import Photos
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


@objc public protocol FusumaDelegate: class {
    
    @objc optional func fusumaDismissedWithImage(_ image: UIImage)
    func fusumaVideoCompleted(withFileURL fileURL: URL)
    func fusumaCameraRollUnauthorized()
    func fusumaAllowAccessDidOpensettings()
    @objc optional func fusumaClosed()
    
    func fusumaCameraRollDidSelectImage()
    func fusumaImageSelected(image: UIImage?)
    func fusumaDidModeChanged(mode: Mode)
}

public var fusumaBaseTintColor   = UIColor.hex("#c1c5cb", alpha: 1.0)
public var fusumaTintColor       = UIColor.hex("#47d081", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#212121", alpha: 1.0)

public var fusumaAlbumImage : UIImage? = nil
public var fusumaCameraImage : UIImage? = nil
public var fusumaVideoImage : UIImage? = nil
public var fusumaCheckImage : UIImage? = nil
public var fusumaCloseImage : UIImage? = nil
public var fusumaFlashOnImage : UIImage? = nil
public var fusumaFlashOffImage : UIImage? = nil
public var fusumaFlipImage : UIImage? = nil
public var fusumaShotImage : UIImage? = nil

public var fusumaVideoStartImage : UIImage? = nil
public var fusumaVideoStopImage : UIImage? = nil

public var fusumaCropImage: Bool = true

public var fusumaCameraRollTitle = "CAMERA ROLL"
public var fusumaCameraTitle = "PHOTO"
public var fusumaVideoTitle = "VIDEO"

public var fusumaTintIcons : Bool = true

public enum FusumaModeOrder {
    case cameraFirst
    case libraryFirst
}

@objc public enum Mode : NSInteger {
    case camera
    case library
    case video
}

//@objc public class FusumaViewController: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {
public final class FusumaViewController: UIViewController {
    
    
    
    public var hasVideo = false
    
    var mode: Mode = Mode.camera
    public var modeOrder: FusumaModeOrder = .libraryFirst
    var willFilter = true
    
    @IBOutlet weak var photoLibraryViewerContainer: UIView!
    @IBOutlet weak var cameraShotContainer: UIView!
    @IBOutlet weak var videoShotContainer: UIView!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet var libraryFirstConstraints: [NSLayoutConstraint]!
    @IBOutlet var cameraFirstConstraints: [NSLayoutConstraint]!
    
    lazy var albumView  = FSAlbumView.instance()
    lazy var cameraView = FSCameraView.instance()
    lazy var videoView = FSVideoCameraView.instance()
    
    fileprivate var hasGalleryPermission: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewController", bundle: Bundle(for: self.classForCoder)).instantiate(withOwner: self, options: nil).first as? UIView {
            
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.hex("#FFFFFF", alpha: 1.0)
        
        cameraView.delegate = self
        albumView.delegate  = self
        videoView.delegate = self
        
        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.hex("#e2e2e2", alpha: 1.0), width: 1.0)
        menuView.isHidden = false
        
        let bundle = Bundle(for: self.classForCoder)
        
        // Get the custom button images if they're set
        let albumImage = fusumaAlbumImage != nil ? fusumaAlbumImage : UIImage(named: "ic_insert_photo", in: bundle, compatibleWith: nil)
        let cameraImage = fusumaCameraImage != nil ? fusumaCameraImage : UIImage(named: "ic_photo_camera", in: bundle, compatibleWith: nil)
        let videoImage = fusumaVideoImage != nil ? fusumaVideoImage : UIImage(named: "ic_videocam", in: bundle, compatibleWith: nil)
        
        let checkImage = fusumaCheckImage != nil ? fusumaCheckImage : UIImage(named: "ic_check", in: bundle, compatibleWith: nil)
        let closeImage = fusumaCloseImage != nil ? fusumaCloseImage : UIImage(named: "ic_close", in: bundle, compatibleWith: nil)
        
        if fusumaTintIcons {
            
            libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            libraryButton.setImage(albumImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            libraryButton.tintColor = fusumaBaseTintColor
            libraryButton.adjustsImageWhenHighlighted = false
            
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            cameraButton.setImage(cameraImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            cameraButton.tintColor  = fusumaBaseTintColor
            cameraButton.adjustsImageWhenHighlighted  = false
            
            videoButton.setImage(videoImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            videoButton.setImage(videoImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            videoButton.setImage(videoImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            videoButton.tintColor  = fusumaBaseTintColor
            videoButton.adjustsImageWhenHighlighted = false
            
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            closeButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            closeButton.tintColor = fusumaTintColor
            
            doneButton.setImage(checkImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            doneButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .highlighted)
            doneButton.setImage(closeImage?.withRenderingMode(.alwaysTemplate), for: .selected)
            doneButton.tintColor = fusumaTintColor
            
        } else {
            
            libraryButton.setImage(albumImage, for: .normal)
            libraryButton.setImage(albumImage, for: .highlighted)
            libraryButton.setImage(albumImage, for: .selected)
            libraryButton.tintColor = nil
            
            cameraButton.setImage(cameraImage, for: .normal)
            cameraButton.setImage(cameraImage, for: .highlighted)
            cameraButton.setImage(cameraImage, for: .selected)
            cameraButton.tintColor = nil
            
            videoButton.setImage(videoImage, for: .normal)
            videoButton.setImage(videoImage, for: .highlighted)
            videoButton.setImage(videoImage, for: .selected)
            videoButton.tintColor = nil
            
            closeButton.setImage(closeImage, for: .normal)
            doneButton.setImage(checkImage, for: .normal)
        }
        
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true
        videoButton.clipsToBounds = true
        
        changeMode(Mode.library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        videoShotContainer.addSubview(videoView)
        
        titleLabel.textColor = UIColor.hex("#000000", alpha: 1.0)
        
        //        if modeOrder != .LibraryFirst {
        //            libraryFirstConstraints.forEach { $0.priority = 250 }
        //            cameraFirstConstraints.forEach { $0.priority = 1000 }
        //        }
        
        if !hasVideo {
            
            videoButton.removeFromSuperview()
            
            self.view.addConstraint(NSLayoutConstraint(
                item:       self.view,
                attribute:  .trailing,
                relatedBy:  .equal,
                toItem:     cameraButton,
                attribute:  .trailing,
                multiplier: 1.0,
                constant:   0
                )
            )
            
            self.view.layoutIfNeeded()
        }
        
        if fusumaCropImage {
            cameraView.fullAspectRatioConstraint.isActive = false
            cameraView.croppedAspectRatioConstraint.isActive = true
        } else {
            cameraView.fullAspectRatioConstraint.isActive = true
            cameraView.croppedAspectRatioConstraint.isActive = false
        }
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        requestAuthorization(forMediaType: AVMediaTypeVideo)
        requestAuthorization(forMediaType: AVMediaTypeAudio)
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPoint.zero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        cameraView.frame = CGRect(origin: CGPoint.zero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
        
        
        albumView.initialize()
        cameraView.initialize()
        
        if hasVideo {
            
            videoView.frame = CGRect(origin: CGPoint.zero, size: videoShotContainer.frame.size)
            videoView.layoutIfNeeded()
            videoView.initialize()
        }
        
        //        changeMode(Mode.library)
        
        albumView.addBottomBorder(UIColor.hex("#e2e2e2", alpha: 1.0), width: 0.5)
        cameraView.addBottomBorder(UIColor.hex("#e2e2e2", alpha: 1.0), width: 0.5)
        
        if hasVideo {
            videoView.addBottomBorder(UIColor.hex("#e2e2e2", alpha: 1.0), width: 0.5)
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopAll()
    }
    
    override public var prefersStatusBarHidden : Bool {
        
        return false
    }
    
    @IBAction public func closeButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: {
            
            self.delegate?.fusumaClosed?()
        })
    }
    
    @IBAction func libraryButtonPressed(_ sender: UIButton) {
        
        changeMode(Mode.library)
        self.delegate?.fusumaDidModeChanged(mode: Mode.library)
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        
        changeMode(Mode.camera)
        self.delegate?.fusumaDidModeChanged(mode: Mode.camera)
    }
    
    @IBAction func videoButtonPressed(_ sender: UIButton) {
        
        changeMode(Mode.video)
        self.delegate?.fusumaDidModeChanged(mode: Mode.video)
    }
    
    @IBAction public func doneButtonPressed(_ sender: UIButton) {
        let view = albumView.imageCropView
        
        let image : UIImage? = view?.image
        
        if image == nil {
            delegate?.fusumaImageSelected(image: image!)
            return;
        }
        
        if fusumaCropImage {
            let normalizedX = (view?.contentOffset.x)! / (view?.contentSize.width)!
            let normalizedY = (view?.contentOffset.y)! / (view?.contentSize.height)!
            
            let normalizedWidth = (view?.frame.width)! / (view?.contentSize.width)!
            let normalizedHeight = (view?.frame.height)! / (view?.contentSize.height)!
            
            let cropRect = CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
            
            DispatchQueue.global(qos: .default).async(execute: {
                
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.normalizedCropRect = cropRect
                options.resizeMode = .exact
                
                let targetWidth = floor(CGFloat(self.albumView.phAsset.pixelWidth) * cropRect.width)
                let targetHeight = floor(CGFloat(self.albumView.phAsset.pixelHeight) * cropRect.height)
                let dimension = max(min(targetHeight, targetWidth), 1024 * UIScreen.main.scale)
                
                let targetSize = CGSize(width: dimension, height: dimension)
                
                PHImageManager.default().requestImage(for: self.albumView.phAsset, targetSize: targetSize,
                                                      contentMode: .aspectFill, options: options) {
                                                        result, info in
                                                        
                                                        DispatchQueue.main.async(execute: {
                                                            self.delegate?.fusumaImageSelected(image: result!)
                                                            
                                                            //                        self.dismiss(animated: true, completion: {
                                                            self.delegate?.fusumaDismissedWithImage?(result!)
                                                            //                        })
                                                        })
                }
            })
        } else {
            print("no image crop ")
            delegate?.fusumaImageSelected(image: (view?.image)!)
            
            //            self.dismiss(animated: true, completion: {
            self.delegate?.fusumaDismissedWithImage?((view?.image)!)
            //            })
        }
    }
    
}

extension FusumaViewController: FSAlbumViewDelegate, FSCameraViewDelegate, FSVideoCameraViewDelegate {
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(_ image: UIImage) {
        
        delegate?.fusumaImageSelected(image: image)
        //        self.dismiss(animated: true, completion: {
        //
        self.delegate?.fusumaDismissedWithImage?(image)
        //        })
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        delegate?.fusumaCameraRollUnauthorized()
    }
    
    public func albumViewCameraRollDidSelectImage() {
        delegate?.fusumaCameraRollDidSelectImage()
    }
    
    public func albumvViewAllowAccessDidOpenSettings() {
        delegate?.fusumaAllowAccessDidOpensettings()
    }
    
    func videoFinished(withFileURL fileURL: URL) {
        delegate?.fusumaVideoCompleted(withFileURL: fileURL)
        //        self.dismiss(animated: true, completion: nil)
    }
    
    func videoViewAllowAccessDidOpenSettings() {
        delegate?.fusumaAllowAccessDidOpensettings()
    }
    func cameraViewAllowAccessDidOpenSettings() {
        delegate?.fusumaAllowAccessDidOpensettings()
    }
    
}

private extension FusumaViewController {
    
    func stopAll() {
        
        if hasVideo {
            
            self.videoView.stopCamera()
        }
        
        self.cameraView.stopCamera()
    }
    
    func changeMode(_ mode: Mode) {
        
        if self.mode == mode {
            return
        }
        
        //operate this switch before changing mode to stop cameras
        switch self.mode {
        case .library:
            break
        case .camera:
            self.cameraView.stopCamera()
        case .video:
            self.videoView.stopCamera()
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        switch mode {
        case .library:
            titleLabel.text = NSLocalizedString(fusumaCameraRollTitle, comment: fusumaCameraRollTitle)
            doneButton.isHidden = false
            
            highlightButton(libraryButton)
            self.view.bringSubview(toFront: photoLibraryViewerContainer)
        case .camera:
            titleLabel.text = NSLocalizedString(fusumaCameraTitle, comment: fusumaCameraTitle)
            doneButton.isHidden = true
            
            highlightButton(cameraButton)
            self.view.bringSubview(toFront: cameraShotContainer)
            cameraView.startCamera()
        case .video:
            titleLabel.text = fusumaVideoTitle
            doneButton.isHidden = true
            
            highlightButton(videoButton)
            self.view.bringSubview(toFront: videoShotContainer)
            
            videoView.startCamera()
        }
        //doneButton.isHidden = !hasGalleryPermission
        self.view.bringSubview(toFront: menuView)
    }
    
    
    func dishighlightButtons() {
        cameraButton.tintColor  = fusumaBaseTintColor
        libraryButton.tintColor = fusumaBaseTintColor
        
        if cameraButton.layer.sublayers?.count > 1 {
            
            for layer in cameraButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if libraryButton.layer.sublayers?.count > 1 {
            
            for layer in libraryButton.layer.sublayers! {
                
                if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                    
                    layer.removeFromSuperlayer()
                }
                
            }
        }
        
        if let videoButton = videoButton {
            
            videoButton.tintColor = fusumaBaseTintColor
            
            if videoButton.layer.sublayers?.count > 1 {
                
                for layer in videoButton.layer.sublayers! {
                    if let borderColor = layer.borderColor , UIColor(cgColor: borderColor) == fusumaTintColor {
                        
                        layer.removeFromSuperlayer()
                    }
                    
                }
            }
        }
        
    }
    
    func highlightButton(_ button: UIButton) {
        
        button.tintColor = fusumaTintColor
        
        button.addBottomBorder(fusumaTintColor, width: 3)
    }
}


public extension FusumaViewController {
    
    public func useFusuma(tintIcons: Bool) {
        fusumaTintIcons = tintIcons
    }
    
    public func setFusumaColors(baseTintColor: UIColor, tintColor: UIColor, backgroundColor: UIColor) {
        fusumaBaseTintColor = baseTintColor
        fusumaTintColor = tintColor
        fusumaBackgroundColor = backgroundColor
    }
    
    public func setFusumaTitles(cameraRollTitle: String, cameraTitle: String, videoTitle: String) {
        fusumaCameraRollTitle = cameraRollTitle
        fusumaCameraTitle = cameraTitle
        fusumaVideoTitle = videoTitle
    }
    
    public func setFusumaPhotoIcons(albumIcon: UIImage, cameraIcon: UIImage, videoIcon: UIImage, checkIcon: UIImage, closeIcon: UIImage, flashOnImage: UIImage, flashOffImage: UIImage, flipImage: UIImage, shotImage: UIImage, videoStartImage: UIImage, videoStopImage: UIImage) {
        fusumaAlbumImage = albumIcon
        fusumaCameraImage = cameraIcon
        fusumaVideoImage = videoIcon
        fusumaCheckImage = checkIcon
        fusumaCloseImage = closeIcon
        fusumaFlashOnImage = flashOnImage
        fusumaFlashOffImage = flashOffImage
        fusumaFlipImage = flipImage
        fusumaShotImage = shotImage
        fusumaVideoStartImage = videoStartImage
        fusumaVideoStopImage = videoStopImage
    }
    
    public func setMode(mode: Mode) {
        changeMode(mode)
    }
    
    public func initializeAllowAccesViewForLibrary(titleText: String, descriptionText: String, buttonTitle: String,
                                  titleFont: UIFont?, descFont: UIFont?, buttonTitleFont: UIFont?,
                                  titleColor: UIColor, descColor: UIColor, buttonTitleColor: UIColor)
    {
        
        albumView.allowAccessButtonTitle = buttonTitle
        albumView.allowAccessButtonTitleColor = buttonTitleColor
        albumView.allowAccessButtonTitleFont = buttonTitleFont
        
        albumView.allowAccessDescFont = descFont
        albumView.allowAccessDescription = descriptionText
        albumView.allowAccessDescColor = descColor
        
        albumView.allowAccessTitle = titleText
        albumView.allowAccessTitleFont = titleFont
        albumView.allowAccessTitleColor = titleColor
        
    }
    
    public func initializeAllowAccesViewForCamera(titleText: String, descriptionText: String, buttonTitle: String,
                                                   titleFont: UIFont?, descFont: UIFont?, buttonTitleFont: UIFont?,
                                                   titleColor: UIColor, descColor: UIColor, buttonTitleColor: UIColor)
    {
        
        cameraView.allowAccessButtonTitle = buttonTitle
        cameraView.allowAccessButtonTitleColor = buttonTitleColor
        cameraView.allowAccessButtonTitleFont = buttonTitleFont
        
        cameraView.allowAccessDescFont = descFont
        cameraView.allowAccessDescription = descriptionText
        cameraView.allowAccessDescColor = descColor
        
        cameraView.allowAccessTitle = titleText
        cameraView.allowAccessTitleFont = titleFont
        cameraView.allowAccessTitleColor = titleColor
        
    }
    
    public func initializeAllowAccesViewForVideoView(titleText: String, descriptionText: String, buttonTitle: String,
                                                  titleFont: UIFont?, descFont: UIFont?, buttonTitleFont: UIFont?,
                                                  titleColor: UIColor, descColor: UIColor, buttonTitleColor: UIColor)
    {
        
        videoView.allowAccessButtonTitle = buttonTitle
        videoView.allowAccessButtonTitleColor = buttonTitleColor
        videoView.allowAccessButtonTitleFont = buttonTitleFont
        
        videoView.allowAccessDescFont = descFont
        videoView.allowAccessDescription = descriptionText
        videoView.allowAccessDescColor = descColor
        
        videoView.allowAccessTitle = titleText
        videoView.allowAccessTitleFont = titleFont
        videoView.allowAccessTitleColor = titleColor
        
    }

    /// Requests authorization permission.
    ///
    /// - Parameter mediaType: Specified media type (i.e. AVMediaTypeVideo, AVMediaTypeAudio, etc.)
    public func requestAuthorization(forMediaType mediaType: String) {
        
        AVCaptureDevice.requestAccess(forMediaType: mediaType) { [unowned self] (granted: Bool) in
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                switch mediaType {
                case AVMediaTypeVideo:
                    if granted {
                        
                        self.cameraView.allowAccessViewContainer.isHidden = true
                        self.videoView.allowAccessViewContainer.isHidden = true
                    } else {
                        
                        self.cameraView.allowAccessViewContainer.isHidden = false
                        self.videoView.allowAccessViewContainer.isHidden = false
                    }
                    
                case AVMediaTypeAudio:
                    if granted {
                        self.videoView.allowAccessViewContainer.isHidden = true
                    } else {
                        
                        self.videoView.allowAccessViewContainer.isHidden = false
                    }

                default:
                    break
                }
               
                
            })
        }
    }
}

public protocol FSAllowAccessViewDelegate: class {
    
    func allowAccessDidOpenSettings()
}

@objc public class FSAllowAccessView: UIView {
    
    @IBOutlet weak var allowAccessBackgroundView: UIView!
    @IBOutlet weak var allowAccessTitleLabel: UILabel!
    @IBOutlet weak var allowAccessTextLabel: UILabel!
    @IBOutlet weak var allowAccessButton: UIButton!
    
    weak var delegate: FSAllowAccessViewDelegate? = nil
    
    static func instance() -> FSAllowAccessView {
        return UINib(nibName: "FSAllowAccessView", bundle: Bundle(for: self.classForCoder())).instantiate(withOwner: self, options: nil)[0] as! FSAllowAccessView
    }

    
    func initialize() {
        
        allowAccessTitleLabel.numberOfLines = 0
        allowAccessTextLabel.numberOfLines = 0
        allowAccessTextLabel.textAlignment = .center
        allowAccessTitleLabel.textAlignment = .center
        
        allowAccessButton.layer.masksToBounds = true
        allowAccessButton.layer.cornerRadius = 20
        allowAccessButton.backgroundColor = UIColor.hex("#47d081", alpha: 1)
        allowAccessButton.setTitleColor(.white, for: .normal)
        allowAccessButton.contentEdgeInsets.left = 16
        allowAccessButton.contentEdgeInsets.right = 16
    }
    

    @IBAction func allowAccessAction(_ sender: UIButton) {
        
        delegate?.allowAccessDidOpenSettings()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}
