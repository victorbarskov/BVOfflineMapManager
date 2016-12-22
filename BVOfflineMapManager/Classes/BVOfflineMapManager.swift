//
//  BVOfflineMapManager.swift
//  Pods
//
//  Created by Victor Barskov on 22.12.16.
//
//
//  Copyright (c) 2016 Victor Barskov.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import UIKit
import MapKit


public enum CustomMapZoom: Int {
    case High = 10, Low = 12, Deep = 16, Deepest = 17
}

public enum CustomMapRadius: Int {
    case HalfMile = 4, Mile = 6, TwoMiles = 8
}

public enum CustomMapTileOverlayType: Int {
    case Apple = 0, Offline = 1
}

var downloadedTilesConst = 0
var countedTilesConst = 0

public class BVOfflineMapManager: NSObject {
    
    // MARK: - Singletone -
    
    public class var shared: BVOfflineMapManager {
        struct Singleton {
            static let instance = BVOfflineMapManager()
        }
        return Singleton.instance
    }
    
    // MARK: - Properties -
    
    private var downloadedTiles = 0
    private var countTiles = 0
    private var circularProgress: KYCircularProgress!
    private var circularProgressFrame: CGRect!
    private var stopButton: UIButton!
    private var tileOverlay: MKTileOverlay?
    private var urlTemplatePath = String()
    private let queue = NSOperationQueue()
    private var flag = false
    
    
    // Tiles swiftch on MapView
    
    public func reloadTileOverlay(mapView: MKMapView, overlayType: CustomMapTileOverlayType?) {
        
        // remove existing map tile overlay
        
        let type = overlayType
        
        if tileOverlay != nil {
            mapView.removeOverlay(tileOverlay!)
        }
        
        if type == .Apple {
            
            tileOverlay = nil
            
        } else {
            
            let documentPath = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
            let urlTemplate = documentPath.absoluteString + "tiles/{z}/{x}/{y}.png"
            tileOverlay?.geometryFlipped = true
            tileOverlay = MKTileOverlay(URLTemplate: urlTemplate)
            tileOverlay?.canReplaceMapContent = true
            mapView.addOverlay(tileOverlay!)
            
        }
        
    }
    
    // MARK: - Methods -
    
    // - All about tiles downloading -
    
    private func transformWorldCoordinateToTilePathForZoom(zoom: Int, lon: Double, lat : Double) -> (x: Int, y: Int) {
        
        let midtileX = floor((lon + 180.0) / 360.0 * pow(2.0, Double(zoom)))
        let midTileY = floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, Double(zoom)))
        let tileX = Int(midtileX)
        let tileY = Int(midTileY)
        
        return (tileX, tileY)
        
    }
    
    public func startDownloading (lat: Double,
                                  lon: Double,
                                  zoom: CustomMapZoom,
                                  radius: CustomMapRadius,
                                  progressfillColor: UIColor = UIColor.blackColor(),
                                  progressGuideColor: UIColor = UIColor.lightGrayColor(),
                                  fillLineWidth: Double = 12.0,
                                  textLabelFont: UIFont = UIFont.systemFontOfSize(28.0),
                                  textLabelColor: UIColor = UIColor.blackColor(),
                                  stopButtonColor: UIColor = UIColor.blueColor(),
                                  stopButtonLabelFont: UIFont = UIFont.systemFontOfSize(17.0),
                                  stopButtontitle: String = NSLocalizedString("Stop", comment: "")) {
        
        
        stopDownloading()
        configureCircularProgress(progressfillColor,
                                  progressGuideColor: progressGuideColor,
                                  fillLineWidth: fillLineWidth,
                                  textLabelFont: textLabelFont,
                                  textLabelColor: textLabelColor,
                                  stopButtonColor: stopButtonColor,
                                  stopButtonLabelFont: stopButtonLabelFont,
                                  stopButtontitle: stopButtontitle)
        
        userInteractionDisabled()
        
        getNumberTiles(zoom, radius: radius, lon: lon, lat: lat) { (count) in
            
            countedTilesConst = count
            
            let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
            
            dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
                
                let sixThirteen = (radius.rawValue - radius.rawValue + 2)
                let thirteenFiveteen = (radius.rawValue - radius.rawValue + 3)
                
                for i in 1...zoom.rawValue {
                    
                    switch i {
                        
                    case let i where i > 0 && i < 6:
                        
                        let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                        
                        for x in tile.x...tile.x {
                            for y in tile.y...tile.y {
                                self.countTiles += 1
                                self.saveImage(i, x: x, y: y)
                            }
                        }
                    case let i where i > 5 && i < 14:
                        
                        let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                        
                        for x in tile.x - sixThirteen...tile.x + sixThirteen {
                            for y in tile.y - sixThirteen...tile.y + sixThirteen {
                                self.countTiles += 1
                                self.saveImage(i, x: x, y: y)
                            }
                        }
                        
                    case let i where i > 13 && i < 16:
                        
                        let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                        
                        for x in tile.x - thirteenFiveteen...tile.x + thirteenFiveteen {
                            for y in tile.y - thirteenFiveteen...tile.y + thirteenFiveteen {
                                self.countTiles += 1
                                self.saveImage(i, x: x, y: y)
                            }
                        }
                        
                    case let i where i > 15 && i < 17 :
                        
                        let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                        
                        for x in tile.x - radius.rawValue...tile.x + radius.rawValue {
                            
                            for y in tile.y - radius.rawValue...tile.y + radius.rawValue {
                                self.countTiles += 1
                                self.saveImage(i, x: x, y: y)
                            }
                        }
                        
                    case let i where i > 16 :
                        
                        let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                        
                        for x in tile.x - radius.rawValue*3...tile.x + radius.rawValue*3 {
                            
                            for y in tile.y - radius.rawValue*3...tile.y + radius.rawValue*3 {
                                self.countTiles += 1
                                self.saveImage(i, x: x, y: y)
                            }
                        }
                        
                        //                        print("countTiles", self.countTiles)
                        
                    default: break
                        
                    }
                }
            }
        }
    }
    
    
    private func getNumberTiles(zoom: CustomMapZoom,radius: CustomMapRadius, lon: Double, lat : Double, completion: (Int) -> Void) {
        
        var count = 0
        
        let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
        
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
            
            let sixThirteen = (radius.rawValue - radius.rawValue + 2)
            let thirteenFiveteen = (radius.rawValue - radius.rawValue + 3)
            
            for i in 1...zoom.rawValue {
                
                switch i {
                    
                case let i where i > 0 && i < 6:
                    
                    let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                    
                    for _ in tile.x...tile.x {
                        for _ in tile.y...tile.y {
                            count += 1
                        }
                    }
                case let i where i > 5 && i < 14:
                    
                    let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                    
                    for _ in tile.x - sixThirteen...tile.x + sixThirteen {
                        for _ in tile.y - sixThirteen...tile.y + sixThirteen {
                            count += 1
                        }
                    }
                    
                case let i where i > 13 && i < 16:
                    
                    let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                    
                    for _ in tile.x - thirteenFiveteen...tile.x + thirteenFiveteen {
                        for _ in tile.y - thirteenFiveteen...tile.y + thirteenFiveteen {
                            count += 1
                        }
                    }
                    
                case let i where i > 15 && i < 17 :
                    
                    let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                    
                    for _ in tile.x - radius.rawValue...tile.x + radius.rawValue {
                        
                        for _ in tile.y - radius.rawValue...tile.y + radius.rawValue {
                            count += 1
                        }
                    }
                    
                case let i where i > 16 :
                    
                    let tile = self.transformWorldCoordinateToTilePathForZoom(i, lon: lon, lat: lat)
                    
                    for _ in tile.x - radius.rawValue*3...tile.x + radius.rawValue*3 {
                        
                        for _ in tile.y - radius.rawValue*3...tile.y + radius.rawValue*3 {
                            count += 1
                        }
                    }
                    
                default: break
                    
                }
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(count)
            }
            
        }
        
    }
    
    private func saveImage (zoom: Int, x: Int, y: Int) {
        
        let url = "http://c.tile.openstreetmap.org/\(zoom)/\(x)/\(y).png"
        //        let url = "http://mt0.google.com/vt/z=\(zoom)&x=\(x)&y=\(y)"
        let urlWithString = NSURL(string: url)
        
        queue.name = "TileDownloadQueue"
        queue.maxConcurrentOperationCount = 1
        
        queue.addOperationWithBlock {
            
            NSURLSession.sharedSession().downloadTaskWithURL(urlWithString!) { temporaryURL, response, error in
                
                guard let url = temporaryURL else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.stopDownloading()
                        if !self.flag {
                            self.errorAlert()
                            self.flag = true
                        }
                    }
                    return
                }
                guard let data = NSData.init(contentsOfURL: url) else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.stopDownloading()
                        if !self.flag {
                            self.errorAlert()
                            self.flag = true
                        }
                    }
                    return
                }
                guard let image = UIImage(data: data) else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.stopDownloading()
                        if !self.flag {
                            self.errorAlert()
                            self.flag = true
                        }
                    }
                    return
                }
                
                guard let pathForWriting = self.pathToWriteImage(zoom, x: x) else {return}
                let fileName = "\(y)"
                self.saveImage(image, fileName: fileName, type: "png", directoryPath: pathForWriting)
                downloadedTilesConst += 1
                
                //                print("downloadedTiles: \(downloadedTilesConst)")
                
                guard error == nil && temporaryURL != nil else {
                    print(error)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.stopDownloading()
                        if !self.flag {
                            self.errorAlert()
                            self.flag = true
                        }
                    }
                    return
                }
                
                if countedTilesConst > 0 && downloadedTilesConst > 0 {
                    
                    let current = Double(downloadedTilesConst)/Double(countedTilesConst)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        
                        if let progress = self.circularProgress {
                            progress.progress = Double(current)
                        }
                        
                        if Double(current) == 1.0 {
                            
                            print("downloadedTiles", downloadedTilesConst)
                            
                            self.stopDownloading()
                            
                            let alertController = UIAlertController (title: "Thank you!", message: "Maps will be switched automatically once you will be offline", preferredStyle: .Alert)
                            
                            let action = UIAlertAction(title:"Ok", style: .Default) { (_) -> Void in
                                
                            }
                            alertController.addAction(action)
                            
                            if let topVC = UIApplication.topViewController() {
                                topVC.presentViewController(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                }
                }.resume()
        }
    }
    
    private func saveImage(image: UIImage, fileName: String, type: String, directoryPath: String) {
        
        guard let dirURL = NSURL(string: directoryPath) else {return}
        
        do {
            
            try NSFileManager.defaultManager().createDirectoryAtURL(dirURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        
        if type.lowercaseString == "png" {
            
            let mutableURLPNG = dirURL.URLByAppendingPathComponent("\(fileName).png")
            
            do {
                try UIImagePNGRepresentation(image)?.writeToURL(mutableURLPNG, options: .DataWritingFileProtectionComplete)
                
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            
        } else if type.lowercaseString == "jpg" || type.lowercaseString == "jpeg" {
            
            let mutableURLJPG = dirURL.URLByAppendingPathComponent("\(fileName).png")
            do {
                try UIImageJPEGRepresentation(image, 1.0)?.writeToURL(mutableURLJPG, options: .DataWritingFileProtectionComplete)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
    }
    
    private func pathToWriteImage (z: Int, x: Int) -> String? {
        
        let pathFolder = "tiles/\(z)/\(x)"
        let directory = applicationDirectory()
        return "\(directory)/\(pathFolder)"
    }
    
    private func applicationDirectory() -> NSURL {
        
        return NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first!
    }
    
    private func userInteractionEnabled() {
        
        guard let vc = UIApplication.topViewController() else {return}
        for view in vc.view.subviews {
            view.userInteractionEnabled = true
        }
    }
    
    private func userInteractionDisabled() {
        
        guard let vc = UIApplication.topViewController() else {return}
        for view in vc.view.subviews {
            if view.tag == 101 {
                view.userInteractionEnabled = true
            } else {
                view.userInteractionEnabled = false
            }
        }
    }
    
    @objc private func stopDownloading() {
        
        
        userInteractionEnabled()
        
        queue.cancelAllOperations()
        
        if let progress = self.circularProgress {
            progress.removeFromSuperview()
        }
        if let button = self.stopButton {
            button.removeFromSuperview()
        }
        downloadedTilesConst = 0
        countedTilesConst = 0
        
    }
    
    private func configureCircularProgress(progressfillColor: UIColor, progressGuideColor: UIColor, fillLineWidth: Double, textLabelFont: UIFont, textLabelColor: UIColor, stopButtonColor: UIColor, stopButtonLabelFont: UIFont, stopButtontitle: String ) {
        
        guard let vc = UIApplication.topViewController() else {return}
        
        circularProgressFrame = CGRectMake(vc.view.center.x - CGRectGetWidth(vc.view.frame)/3/2, vc.view.center.y - CGRectGetWidth(vc.view.frame)/2/2, CGRectGetWidth(vc.view.frame)/3, CGRectGetWidth(vc.view.frame)/3)
        
        circularProgress = KYCircularProgress(frame: circularProgressFrame)
        
        circularProgress.colors = [progressfillColor]
        circularProgress.lineWidth = fillLineWidth
        circularProgress.showProgressGuide = true
        circularProgress.progressGuideColor =  progressGuideColor/*UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)*/
        
        let textLabel = UILabel(frame: CGRectMake(CGRectGetWidth(vc.view.frame)/3/2 - 40, CGRectGetWidth(vc.view.frame)/3/2 - 16, 80.0, 32.0))
        textLabel.font = textLabelFont
        textLabel.textAlignment = .Center
        textLabel.textColor = textLabelColor
        textLabel.alpha = 0.8
        circularProgress.addSubview(textLabel)
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .White)
        
        spinner.frame = CGRectMake(CGRectGetWidth(vc.view.frame)/3/2 - 20/2, CGRectGetWidth(vc.view.frame)/3/2 - 20/2, 20, 20)// (or wherever you want it in the button)
        
        spinner.startAnimating()
        spinner.color = UIColor.lightGrayColor()
        circularProgress.addSubview(spinner)
        
        self.stopButton = UIButton(frame: CGRect(x: CGRectGetWidth(vc.view.frame)/2 - 50, y: circularProgressFrame.maxY + circularProgressFrame.size.height/6, width: 100, height: 50))
        
        stopButton.backgroundColor = stopButtonColor
        stopButton.titleLabel?.font = stopButtonLabelFont
        stopButton.layer.cornerRadius = 5.0
        stopButton.tag = 101
        stopButton.setTitle(stopButtontitle, forState: .Normal)
        stopButton.addTarget(self, action: #selector(BVOfflineMapManager.stopDownloading), forControlEvents: .TouchUpInside)
        
        vc.view.addSubview(self.stopButton)
        
        circularProgress.progressChangedClosure() {(progress: Double, circularView: KYCircularProgress) in
            
            dispatch_async(dispatch_get_main_queue()) {
                spinner.stopAnimating()
                spinner.removeFromSuperview()
                textLabel.text = "\(Int(progress * 100.0))%"
            }
        }
        
        vc.view.addSubview(circularProgress)
    }
    
    public func clearMapCache(callBack:(Bool) -> ()) {
        
        guard let vc = UIApplication.topViewController() else {return}
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        spinner.frame = CGRectMake(vc.view.frame.size.width/2 - 10, vc.view.frame.size.height/2 - 10, 20, 20)
        spinner.startAnimating()
        spinner.color = UIColor.blackColor()
        vc.view.addSubview(spinner)
        
        let fileManager = NSFileManager.defaultManager()
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).first! as NSURL
        let documentsPath = documentsUrl.path
        
        let qos = Int(QOS_CLASS_USER_INITIATED.rawValue)
        
        dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
            
            do {
                if let documentPath = documentsPath
                {
                    
                    let fileNames = try fileManager.contentsOfDirectoryAtPath("\(documentPath)")
                    
                    let contained = fileNames.contains("tiles")
                    if !contained {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            spinner.stopAnimating()
                            spinner.removeFromSuperview()
                            
                            let alertController = UIAlertController (title: "Cache is clear", message: nil, preferredStyle: .Alert)
                            
                            let okAction = UIAlertAction(title: "Ok", style: .Default) { (_) -> Void in
                            }
                            alertController.addAction(okAction)
                            
                            if let topVC = UIApplication.topViewController() {
                                topVC.presentViewController(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                    
                    for fileName in fileNames {
                        
                        if (fileName == "tiles")
                        {
                            let filePathName = "\(documentPath)/\(fileName)"
                            
                            do {
                                
                                try fileManager.removeItemAtPath(filePathName)
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    
                                    spinner.stopAnimating()
                                    spinner.removeFromSuperview()
                                    
                                    callBack(true)
                                    
                                }
                                
                            } catch {
                                dispatch_async(dispatch_get_main_queue()) {
                                    
                                    spinner.stopAnimating()
                                    spinner.removeFromSuperview()
                                }
                                
                            }
                        }
                    }
                }
                
            } catch {
                print("Could not clear temp folder: \(error)")
            }
            
        }
        
    }
    
    private func errorAlert() {
        
        let alertController = UIAlertController (title: NSLocalizedString("Sorry...", comment: ""), message: NSLocalizedString("Something went wrong, please try again later", comment: "") , preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "Ok", style: .Default) { (_) -> Void in
            
        }
        alertController.addAction(action)
        
        if let topVC = UIApplication.topViewController() {
            topVC.presentViewController(alertController, animated: true, completion: nil)
        }
        
    }
    
}


// MARK: - Extensions -

public extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.sharedApplication().keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(presented)
        }
        return controller
    }
}

//  KYCircularProgress.swift
//
//  Copyright (c) 2014-2015 Kengo Yokoyama.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


// MARK: - KYCircularProgress
private class KYCircularProgress: UIView {
    
    /**
     Typealias of progressChangedClosure.
     */
    private typealias progressChangedHandler = (progress: Double, circularView: KYCircularProgress) -> Void
    
    /**
     This closure is called when set value to `progress` property.
     */
    private var progressChangedClosure: progressChangedHandler?
    
    /**
     Main progress view.
     */
    private var progressView: KYCircularShapeView!
    
    /**
     Gradient mask layer of `progressView`.
     */
    private var gradientLayer: CAGradientLayer!
    
    /**
     Guide view of `progressView`.
     */
    private var progressGuideView: KYCircularShapeView?
    
    /**
     Mask layer of `progressGuideView`.
     */
    private var guideLayer: CALayer?
    
    /**
     Current progress value. (0.0 - 1.0)
     */
    @IBInspectable private var progress: Double = 0.0 {
        didSet {
            let clipProgress = max( min(progress, Double(1.0)), Double(0.0) )
            progressView.updateProgress(clipProgress)
            
            progressChangedClosure?(progress: clipProgress, circularView: self)
        }
    }
    
    /**
     Progress start angle.
     */
    private var startAngle: Double = 0.0 {
        didSet {
            progressView.startAngle = startAngle
            progressGuideView?.startAngle = startAngle
        }
    }
    
    /**
     Progress end angle.
     */
    private var endAngle: Double = 0.0 {
        didSet {
            progressView.endAngle = endAngle
            progressGuideView?.endAngle = endAngle
        }
    }
    
    /**
     Main progress line width.
     */
    @IBInspectable private var lineWidth: Double = 8.0 {
        didSet {
            progressView.shapeLayer().lineWidth = CGFloat(lineWidth)
        }
    }
    
    /**
     Guide progress line width.
     */
    @IBInspectable private var guideLineWidth: Double = 8.0 {
        didSet {
            progressGuideView?.shapeLayer().lineWidth = CGFloat(guideLineWidth)
        }
    }
    
    /**
     Progress bar path. You can create various type of progress bar.
     */
    private var path: UIBezierPath? {
        didSet {
            progressView.shapeLayer().path = path?.CGPath
            progressGuideView?.shapeLayer().path = path?.CGPath
        }
    }
    
    /**
     Progress bar colors. You can set many colors in `colors` property, and it makes gradation color in `colors`.
     */
    private var colors: [UIColor]? {
        didSet {
            updateColors(colors)
        }
    }
    
    /**
     Progress guide bar color.
     */
    @IBInspectable private var progressGuideColor: UIColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.2) {
        didSet {
            guideLayer?.backgroundColor = progressGuideColor.CGColor
        }
    }
    
    /**
     Switch of progress guide view. If you set to `true`, progress guide view is enabled.
     */
    @IBInspectable private var showProgressGuide: Bool = false {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
            configureProgressGuideLayer(showProgressGuide)
        }
    }
    
    required private init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureProgressLayer()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureProgressLayer()
    }
    
    /**
     Create `KYCircularProgress` with progress guide.
     
     :param: frame `KYCircularProgress` frame.
     :param: showProgressGuide If you set to `true`, progress guide view is enabled.
     */
    private init(frame: CGRect, showProgressGuide: Bool) {
        super.init(frame: frame)
        configureProgressLayer()
        self.showProgressGuide = showProgressGuide
    }
    
    /**
     This closure is called when set value to `progress` property.
     
     :param: completion progress changed closure.
     */
    public func progressChangedClosure(completion: progressChangedHandler) {
        progressChangedClosure = completion
    }
    
    private func configureProgressLayer() {
        progressView = KYCircularShapeView(frame: bounds)
        progressView.shapeLayer().fillColor = UIColor.clearColor().CGColor
        progressView.shapeLayer().path = path?.CGPath
        progressView.shapeLayer().lineWidth = CGFloat(lineWidth)
        progressView.shapeLayer().strokeColor = tintColor.CGColor
        
        gradientLayer = CAGradientLayer(layer: layer)
        gradientLayer.frame = progressView.frame
        gradientLayer.startPoint = CGPointMake(0, 0.5)
        gradientLayer.endPoint = CGPointMake(1, 0.5)
        gradientLayer.mask = progressView.shapeLayer()
        gradientLayer.colors = colors ?? [UIColor(rgba: 0x9ACDE755).CGColor, UIColor(rgba: 0xE7A5C955).CGColor]
        
        layer.addSublayer(gradientLayer)
    }
    
    private func configureProgressGuideLayer(showProgressGuide: Bool) {
        if showProgressGuide && progressGuideView == nil {
            progressGuideView = KYCircularShapeView(frame: bounds)
            progressGuideView!.shapeLayer().fillColor = UIColor.clearColor().CGColor
            progressGuideView!.shapeLayer().path = progressView.shapeLayer().path
            progressGuideView!.shapeLayer().lineWidth = CGFloat(guideLineWidth)
            progressGuideView!.shapeLayer().strokeColor = tintColor.CGColor
            
            guideLayer = CAGradientLayer(layer: layer)
            guideLayer!.frame = progressGuideView!.frame
            guideLayer!.mask = progressGuideView!.shapeLayer()
            guideLayer!.backgroundColor = progressGuideColor.CGColor
            guideLayer!.zPosition = -1
            
            progressGuideView!.updateProgress(1.0)
            
            layer.addSublayer(guideLayer!)
        }
    }
    
    private func updateColors(colors: [UIColor]?) {
        var convertedColors: [CGColorRef] = []
        if let colors = colors {
            for color in colors {
                convertedColors.append(color.CGColor)
            }
            if convertedColors.count == 1 {
                convertedColors.append(convertedColors.first!)
            }
        } else {
            convertedColors = [UIColor(rgba: 0x9ACDE7FF).CGColor, UIColor(rgba: 0xE7A5C9FF).CGColor]
        }
        gradientLayer.colors = convertedColors
    }
}

// MARK: - KYCircularShapeView
private class KYCircularShapeView: UIView {
    var startAngle = 0.0
    var endAngle = 0.0
    
    override class func layerClass() -> AnyClass {
        return CAShapeLayer.self
    }
    
    private func shapeLayer() -> CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        updateProgress(0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if startAngle == endAngle {
            endAngle = startAngle + (M_PI * 2)
        }
        shapeLayer().path = shapeLayer().path ?? layoutPath().CGPath
    }
    
    private func layoutPath() -> UIBezierPath {
        let halfWidth = CGFloat(CGRectGetWidth(frame) / 2.0)
        return UIBezierPath(arcCenter: CGPointMake(halfWidth, halfWidth), radius: halfWidth - shapeLayer().lineWidth, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: true)
    }
    
    private func updateProgress(progress: Double) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        shapeLayer().strokeEnd = CGFloat(progress)
        CATransaction.commit()
    }
}

// MARK: - UIColor Extension
extension UIColor {
    convenience public init(rgba: Int64) {
        let red   = CGFloat((rgba & 0xFF000000) >> 24) / 255.0
        let green = CGFloat((rgba & 0x00FF0000) >> 16) / 255.0
        let blue  = CGFloat((rgba & 0x0000FF00) >> 8)  / 255.0
        let alpha = CGFloat( rgba & 0x000000FF)        / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}


