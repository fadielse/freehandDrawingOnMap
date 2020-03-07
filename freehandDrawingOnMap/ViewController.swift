//
//  ViewController.swift
//  freehandDrawingOnMap
//
//  Created by Fadilah Hasan on 06/03/20.
//  Copyright © 2020 Fadilah Hasan. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    
    let dummyLocation = CLLocationCoordinate2D(latitude: CLLocationDegrees(-6.220544), longitude: CLLocationDegrees(106.919685))
    
    lazy var canvasView: CanvasView = {
        var overlayView = CanvasView(frame: self.mapView.frame)
        overlayView.isUserInteractionEnabled = true
        overlayView.delegate = self
        return overlayView
    }()
    
    var isDrawing: Bool = false
    var locations: [CLLocation] = [] {
        didSet {
            generateMarkers()
        }
    }
    var drawCoordinates: [CLLocationCoordinate2D] = []
    var markersInsideShape: [GMSMarker] = []
    var randomMarkers: [GMSMarker] = []
    var userDrawablePolygons: [GMSPolygon] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.camera(withTarget: dummyLocation, zoom: 16.0)
        mapView.camera = camera
        locations = getMockLocationsFor(location: CLLocation(latitude: dummyLocation.latitude, longitude: dummyLocation.longitude), itemCount: 200)
    }
    
    @IBAction func buttonDrawTapped(_ sender: UIButton) {
        isDrawing = !isDrawing
        if isDrawing {
            sender.setImage(#imageLiteral(resourceName: "ic-cancel"), for: .normal)
            mapView.addSubview(canvasView) /// Prepare to drawing
        } else {
            sender.setImage(#imageLiteral(resourceName: "ic-draw"), for: .normal)
            resetMapView()
        }
    }
    
    func generateMarkers() {
        for location in locations {
            let position = location.coordinate
            let marker = GMSMarker(position: position)
            marker.title = "Location: \(position.latitude), \(position.longitude)"
            marker.icon = #imageLiteral(resourceName: "ic-pin")
            marker.map = mapView
            randomMarkers.append(marker)
        }
    }
    
    func getMockLocationsFor(location: CLLocation, itemCount: Int) -> [CLLocation] {
        
        func getBase(number: Double) -> Double {
            return round(number * 1000)/1000
        }
        
        func randomCoordinate() -> Double {
            return Double(arc4random_uniform(140)) * 0.0001
        }
        
        let baseLatitude = getBase(number: location.coordinate.latitude - 0.007)
        let baseLongitude = getBase(number: location.coordinate.longitude - 0.008)
        
        var items: [CLLocation] = []
        
        for _ in 0 ..< itemCount {
            let randomLat = baseLatitude + randomCoordinate()
            let randomLong = baseLongitude + randomCoordinate()
            let location = CLLocation(latitude: randomLat, longitude: randomLong)
            
            items.append(location)
        }
        
        return items
    }
    
    func resetMapView() {
        userDrawablePolygons.removeAll()
        markersInsideShape.removeAll()
        markersInsideShape.removeAll()
        randomMarkers.removeAll()
        mapView.clear()
        generateMarkers()
    }
    
    func createPolygonFromTheDrawablePoints() {
        let numberOfPoints = self.drawCoordinates.count
        
        /// Do not draw in mapview a single point
        if numberOfPoints > 2 {
            addPolyGonInMapView(drawableLoc: drawCoordinates)
            drawCoordinates = []
            self.canvasView.image = nil
            self.canvasView.removeFromSuperview()
        }
    }
    
    func addPolyGonInMapView(drawableLoc: [CLLocationCoordinate2D]) {
        isDrawing = true
        let path = GMSMutablePath()
        
        for loc in drawableLoc {
            path.add(loc)
        }
        
        let newpolygon = GMSPolygon(path: path)
        newpolygon.strokeWidth = 3
        newpolygon.strokeColor = UIColor(red: 20.0/255.0, green: 119.0/255.0, blue: 234.0/255.0, alpha: 0.75)
        newpolygon.fillColor = UIColor(red: 156.0/255.0, green: 202.0/255.0, blue: 254.0/255.0, alpha: 0.4)
        newpolygon.map = mapView
        userDrawablePolygons.append(newpolygon)
        
        if drawableLoc.count > 2 {
            let coordinateBounds = GMSCoordinateBounds(path: newpolygon.path!)
            mapView.animate(with: .fit(coordinateBounds)) /// Adjust map zoom to the polygon that has been drawn to the screen
        }
    }
    
    func getMarkerInsidePolygon() {
        if userDrawablePolygons.count <= 0 {
            return
        }
        
        let myPolygon = userDrawablePolygons[0].path
        markersInsideShape.removeAll()
        
        /// Validate all markers that are not included in the polygon and delete from the map
        for marker in randomMarkers {
            if (GMSGeometryContainsLocation(marker.position, myPolygon!, true)) {
                markersInsideShape.append(marker)
            } else {
                marker.map = nil
            }
        }
    }
}

// MARK: GET DRAWABLE COORDINATES

extension ViewController: NotifyTouchEvents {
    
    func touchBegan(touch: UITouch) {
        self.drawCoordinates.append(translateCoordinate(withTouch: touch))
    }
    
    func touchMoved(touch: UITouch) {
        self.drawCoordinates.append(translateCoordinate(withTouch: touch))
    }
    
    func touchEnded(touch: UITouch) {
        self.drawCoordinates.append(translateCoordinate(withTouch: touch))
        /// 1
        createPolygonFromTheDrawablePoints()
        /// 2
        getMarkerInsidePolygon()
    }
    
    func translateCoordinate(withTouch touch: UITouch) -> CLLocationCoordinate2D {
        let location = touch.location(in: self.mapView)
        return self.mapView.projection.coordinate(for: location)
    }
}
