# BVOfflineMapManager

[![CI Status](http://img.shields.io/travis/Victor Barskov/BVOfflineMapManager.svg?style=flat)](https://travis-ci.org/Victor Barskov/BVOfflineMapManager)
[![Version](https://img.shields.io/cocoapods/v/BVOfflineMapManager.svg?style=flat)](http://cocoapods.org/pods/BVOfflineMapManager)
[![License](https://img.shields.io/cocoapods/l/BVOfflineMapManager.svg?style=flat)](http://cocoapods.org/pods/BVOfflineMapManager)
[![Platform](https://img.shields.io/cocoapods/p/BVOfflineMapManager.svg?style=flat)](http://cocoapods.org/pods/BVOfflineMapManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 8.0+, Swift 2.2

## Usage 

Swift 2.2: 

To start maps downloading and saving call following methid with passing of initial coordinate lat and lon, radius and zoom: 

```swift
BVOfflineMapManager.shared.startDownloading(lat: Double, lon: Double, zoom: CustomMapZoom, radius: CustomMapRadius)
```
To reload map tiles from online to offline and back call: 

```swift
BVOfflineMapManager.shared.reloadTileOverlay(mapView: MKMapView, overlayType: CustomMapTileOverlayType?)
```

To clear cached maps to free disk space call:

```swift
BVOfflineMapManager.shared.clearMapCache(callBack: (Bool) -> ())
```

## Installation

BVOfflineMapManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BVOfflineMapManager"
```

## Author

Victor Barskov, victor.barskov@gmail.com

## References: 

* [Circular Progress Bar] - circullar bar which useed in the library
* [Custom and OfflineMaps UsingOverlay Tiles] - the library inspired by this article 

## License

BVOfflineMapManager is available under the MIT license. See the LICENSE file for more info.

[Custom and OfflineMaps UsingOverlay Tiles]: <http://www.viggiosoft.com/blog/blog/2014/01/21/custom-and-offline-maps-using-overlay-tiles/>
[Circular Progress Bar]: <https://github.com/kentya6/KYCircularProgress>
