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
    case high = 10, low = 12, deep = 16, deepest = 17
}

public enum CustomMapRadius: Int {
    case halfMile = 4, mile = 6, twoMiles = 8
}

public enum CustomMapTileOverlayType: Int {
    case apple = 0, offline = 1
}

var downloadedTilesConst = 0
var countedTilesConst = 0

open class BVOfflineMapManager: NSObject {
    
    // MARK: - Singletone -
    
    open class var shared: BVOfflineMapManager {
        struct Singleton {
            static let instance = BVOfflineMapManager()
        }
        return Singleton.instance
    }
    
    // MARK: - Properties -
    
    fileprivate var downloadedTiles = 0
    fileprivate var countTiles = 0
    fileprivate var circularProgress: KYCircularProgress!
    fileprivate var circularProgressFrame: CGRect!
    fileprivate var stopButton: UIButton!
    fileprivate var tileOverlay: MKTileOverlay?
    fileprivate var urlTemplatePath = String()
    fileprivate let queue = OperationQueue()
    fileprivate var flag = false
    
    
    // Tiles swiftch on MapView
    
    open func reloadTileOverlay(_ mapView: MKMapView, overlayType: CustomMapTileOverlayType?) {
        
        // remove existing map tile overlay
        
        let type = overlayType
        
        if tileOverlay != nil {
            mapView.remove(tileOverlay!)
        }
        
        if type == .apple {
            
            tileOverlay = nil
            
        } else {
            
            let documentPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let urlTemplate = documentPath.absoluteString + "tiles/{z}/{x}/{y}.png"
            tileOverlay?.isGeometryFlipped = true
            tileOverlay = MKTileOverlay(urlTemplate: urlTemplate)
            tileOverlay?.canReplaceMapContent = true
            mapView.add(tileOverlay!)
            
        }
        
    }
    
    // MARK: - Methods -
    
    // - All about tiles downloading -
    
    fileprivate func transformWorldCoordinateToTilePathForZoom(_ zoom: Int, lon: Double, lat : Double) -> (x: Int, y: Int) {
        
        let midtileX = floor((lon + 180.0) / 360.0 * pow(2.0, Double(zoom)))
        let midTileY = floor((1.0 - log( tan(lat * M_PI/180.0) + 1.0 / cos(lat * M_PI/180.0)) / M_PI) / 2.0 * pow(2.0, Double(zoom)))
        let tileX = Int(midtileX)
        let tileY = Int(midTileY)
        
        return (tileX, tileY)
        
    }
    
    open func startDownloading (_ lat: Double,
                                  lon: Double,
                                  zoom: CustomMapZoom,
                                  radius: CustomMapRadius,
                                  progressfillColor: UIColor = UIColor.black,
                                  progressGuideColor: UIColor = UIColor.lightGray,
                                  fillLineWidth: Double = 12.0,
                                  textLabelFont: UIFont = UIFont.systemFont(ofSize: 28.0),
                                  textLabelColor: UIColor = UIColor.black,
                                  stopButtonColor: UIColor = UIColor.blue,
                                  stopButtonLabelFont: UIFont = UIFont.systemFont(ofSize: 17.0),
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
            
//            let qos = Int(DispatchQoS.QoSClass.userInitiated.rawValue)
            
            DispatchQueue.global(priority: .background).async { () -> Void in
                
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
    
    
    fileprivate func getNumberTiles(_ zoom: CustomMapZoom,radius: CustomMapRadius, lon: Double, lat : Double, completion: @escaping (Int) -> Void) {
        
        var count = 0
        
//        let qos = Int(DispatchQoS.QoSClass.userInitiated.rawValue)
        
        DispatchQueue.global(priority: .background).async { () -> Void in
            
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
            
            DispatchQueue.main.async {
                completion(count)
            }
            
        }
        
    }
    
    fileprivate func saveImage (_ zoom: Int, x: Int, y: Int) {
        
        let url = "http://c.tile.openstreetmap.org/\(zoom)/\(x)/\(y).png"
        //        let url = "http://mt0.google.com/vt/z=\(zoom)&x=\(x)&y=\(y)"
        let urlWithString = URL(string: url)
        
        queue.name = "TileDownloadQueue"
        queue.maxConcurrentOperationCount = 1
        
        queue.addOperation {
            
            URLSession.shared.downloadTask(with: urlWithString!, completionHandler: { temporaryURL, response, error in
                
                guard let url = temporaryURL else {
                    DispatchQueue.main.async {
                        self.stopDownloading()
                        if !self.flag {
                            self.errorAlert()
                            self.flag = true
                        }
                    }
                    return
                }
                guard let data = try? Data.init(contentsOf: url) else {
                    DispatchQueue.main.async {
                        self.stopDownloading()
                        if !self.flag {
                            self.errorAlert()
                            self.flag = true
                        }
                    }
                    return
                }
                guard let image = UIImage(data: data) else {
                    DispatchQueue.main.async {
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
                    DispatchQueue.main.async {
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
                    
                    DispatchQueue.main.async {
                        
                        if let progress = self.circularProgress {
                            progress.progress = Double(current)
                        }
                        
                        if Double(current) == 1.0 {
                            
                            print("downloadedTiles", downloadedTilesConst)
                            
                            self.stopDownloading()
                            
                            let alertController = UIAlertController (title: "Thank you!", message: "Maps will be switched automatically once you will be offline", preferredStyle: .alert)
                            
                            let action = UIAlertAction(title:"Ok", style: .default) { (_) -> Void in
                                
                            }
                            alertController.addAction(action)
                            
                            if let topVC = UIApplication.topViewController() {
                                topVC.present(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                }
                }) .resume()
        }
    }
    
    fileprivate func saveImage(_ image: UIImage, fileName: String, type: String, directoryPath: String) {
        
        guard let dirURL = URL(string: directoryPath) else {return}
        
        do {
            
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print(error.localizedDescription);
        }
        
        if type.lowercased() == "png" {
            
            let mutableURLPNG = dirURL.appendingPathComponent("\(fileName).png")
            
            do {
                try UIImagePNGRepresentation(image)?.write(to: mutableURLPNG, options: .completeFileProtection)
                
            } catch let error as NSError {
                print(error.localizedDescription);
            }
            
        } else if type.lowercased() == "jpg" || type.lowercased() == "jpeg" {
            
            let mutableURLJPG = dirURL.appendingPathComponent("\(fileName).png")
            do {
                try UIImageJPEGRepresentation(image, 1.0)?.write(to: mutableURLJPG, options: .completeFileProtection)
            } catch let error as NSError {
                print(error.localizedDescription);
            }
        }
    }
    
    fileprivate func pathToWriteImage (_ z: Int, x: Int) -> String? {
        
        let pathFolder = "tiles/\(z)/\(x)"
        let directory = applicationDirectory()
        return "\(directory)/\(pathFolder)"
    }
    
    fileprivate func applicationDirectory() -> URL {
        
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    fileprivate func userInteractionEnabled() {
        
        guard let vc = UIApplication.topViewController() else {return}
        for view in vc.view.subviews {
            view.isUserInteractionEnabled = true
        }
    }
    
    fileprivate func userInteractionDisabled() {
        
        guard let vc = UIApplication.topViewController() else {return}
        for view in vc.view.subviews {
            if view.tag == 101 {
                view.isUserInteractionEnabled = true
            } else {
                view.isUserInteractionEnabled = false
            }
        }
    }
    
    @objc fileprivate func stopDownloading() {
        
        
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
    
    fileprivate func configureCircularProgress(_ progressfillColor: UIColor, progressGuideColor: UIColor, fillLineWidth: Double, textLabelFont: UIFont, textLabelColor: UIColor, stopButtonColor: UIColor, stopButtonLabelFont: UIFont, stopButtontitle: String ) {
        
        guard let vc = UIApplication.topViewController() else {return}
        
        circularProgressFrame = CGRect(x: vc.view.center.x - vc.view.frame.width/3/2, y: vc.view.center.y - vc.view.frame.width/2/2, width: vc.view.frame.width/3, height: vc.view.frame.width/3)
        
        circularProgress = KYCircularProgress(frame: circularProgressFrame)
        
        circularProgress.colors = [progressfillColor]
        circularProgress.lineWidth = fillLineWidth
        circularProgress.showProgressGuide = true
        circularProgress.progressGuideColor =  progressGuideColor/*UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.4)*/
        
        let textLabel = UILabel(frame: CGRect(x: vc.view.frame.width/3/2 - 40, y: vc.view.frame.width/3/2 - 16, width: 80.0, height: 32.0))
        textLabel.font = textLabelFont
        textLabel.textAlignment = .center
        textLabel.textColor = textLabelColor
        textLabel.alpha = 0.8
        circularProgress.addSubview(textLabel)
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        
        spinner.frame = CGRect(x: vc.view.frame.width/3/2 - 20/2, y: vc.view.frame.width/3/2 - 20/2, width: 20, height: 20)// (or wherever you want it in the button)
        
        spinner.startAnimating()
        spinner.color = UIColor.lightGray
        circularProgress.addSubview(spinner)
        
        self.stopButton = UIButton(frame: CGRect(x: vc.view.frame.width/2 - 50, y: circularProgressFrame.maxY + circularProgressFrame.size.height/6, width: 100, height: 50))
        
        stopButton.backgroundColor = stopButtonColor
        stopButton.titleLabel?.font = stopButtonLabelFont
        stopButton.layer.cornerRadius = 5.0
        stopButton.tag = 101
        stopButton.setTitle(stopButtontitle, for: UIControlState())
        stopButton.addTarget(self, action: #selector(BVOfflineMapManager.stopDownloading), for: .touchUpInside)
        
        vc.view.addSubview(self.stopButton)
        
        circularProgress.progressChangedClosure() {(progress: Double, circularView: KYCircularProgress) in
            
            DispatchQueue.main.async {
                spinner.stopAnimating()
                spinner.removeFromSuperview()
                textLabel.text = "\(Int(progress * 100.0))%"
            }
        }
        
        vc.view.addSubview(circularProgress)
    }
    
    open func clearMapCache(_ callBack:@escaping (Bool) -> ()) {
        
        guard let vc = UIApplication.topViewController() else {return}
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.frame = CGRect(x: vc.view.frame.size.width/2 - 10, y: vc.view.frame.size.height/2 - 10, width: 20, height: 20)
        spinner.startAnimating()
        spinner.color = UIColor.black
        vc.view.addSubview(spinner)
        
        let fileManager = FileManager.default
        let documentsUrl =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first! as? URL
        let documentsPath = documentsUrl?.path
        
//        let qos = Int(DispatchQoS.QoSClass.userInitiated.rawValue)
        
        DispatchQueue.global(priority: .background).async { () -> Void in
            
            do {
                if let documentPath = documentsPath
                {
                    
                    let fileNames = try fileManager.contentsOfDirectory(atPath: "\(documentPath)")
                    
                    let contained = fileNames.contains("tiles")
                    if !contained {
                        
                        DispatchQueue.main.async {
                            
                            spinner.stopAnimating()
                            spinner.removeFromSuperview()
                            
                            let alertController = UIAlertController (title: "Cache is clear", message: nil, preferredStyle: .alert)
                            
                            let okAction = UIAlertAction(title: "Ok", style: .default) { (_) -> Void in
                            }
                            alertController.addAction(okAction)
                            
                            if let topVC = UIApplication.topViewController() {
                                topVC.present(alertController, animated: true, completion: nil)
                            }
                        }
                    }
                    
                    for fileName in fileNames {
                        
                        if (fileName == "tiles")
                        {
                            let filePathName = "\(documentPath)/\(fileName)"
                            
                            do {
                                
                                try fileManager.removeItem(atPath: filePathName)
                                
                                DispatchQueue.main.async {
                                    
                                    spinner.stopAnimating()
                                    spinner.removeFromSuperview()
                                    
                                    callBack(true)
                                    
                                }
                                
                            } catch {
                                DispatchQueue.main.async {
                                    
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
    
    fileprivate func errorAlert() {
        
        let alertController = UIAlertController (title: NSLocalizedString("Sorry...", comment: ""), message: NSLocalizedString("Something went wrong, please try again later", comment: "") , preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Ok", style: .default) { (_) -> Void in
            
        }
        alertController.addAction(action)
        
        if let topVC = UIApplication.topViewController() {
            topVC.present(alertController, animated: true, completion: nil)
        }
        
    }
    
}


// MARK: - Extensions -

public extension UIApplication {
    class func topViewController(_ controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
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
    fileprivate typealias progressChangedHandler = (_ progress: Double, _ circularView: KYCircularProgress) -> Void
    
    /**
     This closure is called when set value to `progress` property.
     */
    fileprivate var progressChangedClosure: progressChangedHandler?
    
    /**
     Main progress view.
     */
    fileprivate var progressView: KYCircularShapeView!
    
    /**
     Gradient mask layer of `progressView`.
     */
    fileprivate var gradientLayer: CAGradientLayer!
    
    /**
     Guide view of `progressView`.
     */
    fileprivate var progressGuideView: KYCircularShapeView?
    
    /**
     Mask layer of `progressGuideView`.
     */
    fileprivate var guideLayer: CALayer?
    
    /**
     Current progress value. (0.0 - 1.0)
     */
    @IBInspectable fileprivate var progress: Double = 0.0 {
        didSet {
            let clipProgress = max( min(progress, Double(1.0)), Double(0.0) )
            progressView.updateProgress(clipProgress)
            
            progressChangedClosure?(clipProgress, self)
        }
    }
    
    /**
     Progress start angle.
     */
    fileprivate var startAngle: Double = 0.0 {
        didSet {
            progressView.startAngle = startAngle
            progressGuideView?.startAngle = startAngle
        }
    }
    
    /**
     Progress end angle.
     */
    fileprivate var endAngle: Double = 0.0 {
        didSet {
            progressView.endAngle = endAngle
            progressGuideView?.endAngle = endAngle
        }
    }
    
    /**
     Main progress line width.
     */
    @IBInspectable fileprivate var lineWidth: Double = 8.0 {
        didSet {
            progressView.shapeLayer().lineWidth = CGFloat(lineWidth)
        }
    }
    
    /**
     Guide progress line width.
     */
    @IBInspectable fileprivate var guideLineWidth: Double = 8.0 {
        didSet {
            progressGuideView?.shapeLayer().lineWidth = CGFloat(guideLineWidth)
        }
    }
    
    /**
     Progress bar path. You can create various type of progress bar.
     */
    fileprivate var path: UIBezierPath? {
        didSet {
            progressView.shapeLayer().path = path?.cgPath
            progressGuideView?.shapeLayer().path = path?.cgPath
        }
    }
    
    /**
     Progress bar colors. You can set many colors in `colors` property, and it makes gradation color in `colors`.
     */
    fileprivate var colors: [UIColor]? {
        didSet {
            updateColors(colors)
        }
    }
    
    /**
     Progress guide bar color.
     */
    @IBInspectable fileprivate var progressGuideColor: UIColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.2) {
        didSet {
            guideLayer?.backgroundColor = progressGuideColor.cgColor
        }
    }
    
    /**
     Switch of progress guide view. If you set to `true`, progress guide view is enabled.
     */
    @IBInspectable fileprivate var showProgressGuide: Bool = false {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
            configureProgressGuideLayer(showProgressGuide)
        }
    }
    
    required fileprivate init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureProgressLayer()
    }
    
    fileprivate override init(frame: CGRect) {
        super.init(frame: frame)
        configureProgressLayer()
    }
    
    /**
     Create `KYCircularProgress` with progress guide.
     
     :param: frame `KYCircularProgress` frame.
     :param: showProgressGuide If you set to `true`, progress guide view is enabled.
     */
    fileprivate init(frame: CGRect, showProgressGuide: Bool) {
        super.init(frame: frame)
        configureProgressLayer()
        self.showProgressGuide = showProgressGuide
    }
    
    /**
     This closure is called when set value to `progress` property.
     
     :param: completion progress changed closure.
     */
    fileprivate func progressChangedClosure(_ completion: @escaping progressChangedHandler) {
        progressChangedClosure = completion
    }
    
    fileprivate func configureProgressLayer() {
        progressView = KYCircularShapeView(frame: bounds)
        progressView.shapeLayer().fillColor = UIColor.clear.cgColor
        progressView.shapeLayer().path = path?.cgPath
        progressView.shapeLayer().lineWidth = CGFloat(lineWidth)
        progressView.shapeLayer().strokeColor = tintColor.cgColor
        
        gradientLayer = CAGradientLayer(layer: layer)
        gradientLayer.frame = progressView.frame
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.mask = progressView.shapeLayer()
        gradientLayer.colors = colors ?? [UIColor(rgba: 0x9ACDE755).cgColor, UIColor(rgba: 0xE7A5C955).cgColor]
        
        layer.addSublayer(gradientLayer)
    }
    
    fileprivate func configureProgressGuideLayer(_ showProgressGuide: Bool) {
        if showProgressGuide && progressGuideView == nil {
            progressGuideView = KYCircularShapeView(frame: bounds)
            progressGuideView!.shapeLayer().fillColor = UIColor.clear.cgColor
            progressGuideView!.shapeLayer().path = progressView.shapeLayer().path
            progressGuideView!.shapeLayer().lineWidth = CGFloat(guideLineWidth)
            progressGuideView!.shapeLayer().strokeColor = tintColor.cgColor
            
            guideLayer = CAGradientLayer(layer: layer)
            guideLayer!.frame = progressGuideView!.frame
            guideLayer!.mask = progressGuideView!.shapeLayer()
            guideLayer!.backgroundColor = progressGuideColor.cgColor
            guideLayer!.zPosition = -1
            
            progressGuideView!.updateProgress(1.0)
            
            layer.addSublayer(guideLayer!)
        }
    }
    
    fileprivate func updateColors(_ colors: [UIColor]?) {
        var convertedColors: [CGColor] = []
        if let colors = colors {
            for color in colors {
                convertedColors.append(color.cgColor)
            }
            if convertedColors.count == 1 {
                convertedColors.append(convertedColors.first!)
            }
        } else {
            convertedColors = [UIColor(rgba: 0x9ACDE7FF).cgColor, UIColor(rgba: 0xE7A5C9FF).cgColor]
        }
        gradientLayer.colors = convertedColors
    }
}

// MARK: - KYCircularShapeView
private class KYCircularShapeView: UIView {
    var startAngle = 0.0
    var endAngle = 0.0
    
    override class var layerClass : AnyClass {
        return CAShapeLayer.self
    }
    
    fileprivate func shapeLayer() -> CAShapeLayer {
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
        shapeLayer().path = shapeLayer().path ?? layoutPath().cgPath
    }
    
    fileprivate func layoutPath() -> UIBezierPath {
        let halfWidth = CGFloat(frame.width / 2.0)
        return UIBezierPath(arcCenter: CGPoint(x: halfWidth, y: halfWidth), radius: halfWidth - shapeLayer().lineWidth, startAngle: CGFloat(startAngle), endAngle: CGFloat(endAngle), clockwise: true)
    }
    
    fileprivate func updateProgress(_ progress: Double) {
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


