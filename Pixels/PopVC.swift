//
//  PopVC.swift
//  Pixels
//
//  Created by Kareem Ismail on 10/23/17.
//  Copyright © 2017 Whatever. All rights reserved.
//

import UIKit
import MapKit
class PopVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    var dataForPassedImage: UIImage!
    var imageInfo: PhotoInfo!
    
    @IBOutlet weak var imageLocation: MKMapView!
    @IBOutlet weak var imageDate: UILabel!
    @IBOutlet weak var imageDescription: UILabel!
    @IBOutlet weak var imageTitle: UILabel!
    func initData(forImage passedImage: UIImage, imageInfo info: PhotoInfo){
        dataForPassedImage = passedImage
        imageInfo = PhotoInfo(description: info.description, title: info.title, longitude: info.longitude, latitude: info.latitude, datePosted: info.datePosted)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loadInfoToView()
        addDoubleTap()

    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PopVC.dismissView))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
    func loadInfoToView(){
        imageView.image = dataForPassedImage
        if imageInfo.description! == "" {
            imageDescription.text = "No Description"
        }
        else {
            imageDescription.text = imageInfo.description!
        }
        if imageInfo.title! == "" {
            imageTitle.text = "No Title"
        }
        else {
            imageTitle.text = imageInfo.title!
        }
        imageDate.text = imageInfo.datePosted!
        centerMapOnImageLocation()
        
    }
    
    @objc func dismissView(){
        dismiss(animated: true, completion: nil)
    }
}

extension PopVC: MKMapViewDelegate {
    func centerMapOnImageLocation(){
        let coordinates = CLLocationCoordinate2D(latitude: imageInfo.latitude!, longitude: imageInfo.longitude!)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, 200, 200)
        imageLocation.setRegion(coordinateRegion, animated: true)
        let dropPin = DroppablePin(coordinate: coordinates, identifier: "")
        imageLocation.addAnnotation(dropPin)
    }
}
