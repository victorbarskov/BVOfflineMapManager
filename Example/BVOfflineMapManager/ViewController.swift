//
//  ViewController.swift
//  BVOfflineMapManager
//
//  Created by Victor Barskov on 12/19/2016.
//  Copyright (c) 2016 Victor Barskov. All rights reserved.
//

import UIKit
import MapKit
import BVOfflineMapManager

class ViewController: UIViewController {
    
    // MARK: - Properties -
    
    var overlayType: CustomMapTileOverlayType?
    var locationManager = CLLocationManager()
    var center = CLLocationCoordinate2D()
    var reachability: Reachability?
    
    // MARK: - IBOutlets -
    
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBAction func segmentChanged(sender: AnyObject) {
        
        overlayType = CustomMapTileOverlayType(rawValue: segmentControl.selectedSegmentIndex)!
        
        BVOfflineMapManager.shared.reloadTileOverlay(mapView, overlayType: overlayType)
        
    }
    
    @IBAction func clear(sender: UIButton) {
        
        
        BVOfflineMapManager.shared.clearMapCache { (success) in
            if success {
                print("Cache has been successfully cleared")
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    let alertController = UIAlertController (title: "Cache is clear", message: nil, preferredStyle: .Alert)
                    
                    let okAction = UIAlertAction(title: "Ok", style: .Default) { (_) -> Void in
                    }
                    alertController.addAction(okAction)
                    
                    if let topVC = UIApplication.topViewController() {
                        topVC.presentViewController(alertController, animated: true, completion: nil)
                    }
                }
            }
        }
        
    }
    
    @IBAction func downloadMap(sender: UIButton) {
        BVOfflineMapManager.shared.startDownloading(center.latitude, lon: center.longitude, zoom: .Deep, radius: .Mile)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        segmentControl.selectedSegmentIndex = CustomMapTileOverlayType.Apple.rawValue
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        reachable()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func reachable() {
        
        do {
            reachability = try  Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }
        
        reachability!.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            dispatch_async(dispatch_get_main_queue()) {
                
                if reachability.isReachableViaWiFi() {
                    
                    print("Reachable via WiFi")
                    
                    self.overlayType = .Apple
                    BVOfflineMapManager.shared.reloadTileOverlay(self.mapView, overlayType: self.overlayType)
                    
                    self.downloadButton.hidden = false
                    
                } else {
                    
                    print("Reachable via Cellular")
                    
                    self.downloadButton.hidden = true
                    self.overlayType = CustomMapTileOverlayType.Apple
                    BVOfflineMapManager.shared.reloadTileOverlay(self.mapView, overlayType: self.overlayType)
                    
                }
            }
        }
        
        reachability!.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            dispatch_async(dispatch_get_main_queue()) {
                
                self.overlayType = .Offline
                self.downloadButton.hidden = true
                BVOfflineMapManager.shared.reloadTileOverlay(self.mapView, overlayType: self.overlayType)
                print("Not reachable")
                
            }
        }
        
        do {
            try reachability!.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    
    func locationManager(_manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15))
        self.mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation()
    }
    

    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        manager.stopUpdatingLocation()
    }
}


extension ViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        center = mapView.centerCoordinate
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        guard let tileOverlay = overlay as? MKTileOverlay else {
            return MKOverlayRenderer()
        }
        return MKTileOverlayRenderer(tileOverlay: tileOverlay)
    }

}

