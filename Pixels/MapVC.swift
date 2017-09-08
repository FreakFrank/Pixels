//
//  ViewController.swift
//  Pixels
//
//  Created by Kareem Ismail on 9/7/17.
//  Copyright © 2017 Whatever. All rights reserved.
//

import UIKit
import MapKit

class MapVC: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 2000
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
    }

    @IBAction func centerButtonPressed(_ sender: Any) {
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }

}

extension MapVC: MKMapViewDelegate {
    
    func centerMapOnUserLocation(){
        guard let coordinates = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices(){
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        centerMapOnUserLocation()
    }
}
