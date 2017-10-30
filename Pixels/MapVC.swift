//
//  ViewController.swift
//  Pixels
//
//  Created by Kareem Ismail on 9/7/17.
//  Copyright © 2017 Whatever. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage
import SwiftyJSON

class MapVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var photosView: UIView!
    let locationManager = CLLocationManager()
    var authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadius: Double = 2000
    var spinner: UIActivityIndicatorView?
    var progressLabel: UILabel?
    let screenSize = UIScreen.main.bounds
    var flowLayout = UICollectionViewFlowLayout()
    var photosCollectionView: UICollectionView?
    var imagesUrlArray = [String]()
    var imagesArray = [UIImage]()
    var photosInfoArray = [PhotoInfo]()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        photosCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        photosCollectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PHOTOS_CELL_IDENTIFIER)
        photosCollectionView?.delegate = self
        photosCollectionView?.dataSource = self
        photosCollectionView?.backgroundColor = #colorLiteral(red: 0.8125900697, green: 0.8862745166, blue: 0.7703204131, alpha: 1)
        registerForPreviewing(with: self, sourceView: photosCollectionView!)
        photosView.addSubview(photosCollectionView!)
    }
    
    func addDoubleTap(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MapVC.dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe(){
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animatePhotosView(distance:)))
        swipe.direction = .down
        photosView.addGestureRecognizer(swipe)
    }
    @objc func animatePhotosView(distance: CGFloat){
        mapViewBottomConstraint.constant = distance
        if distance == 0 {
            cancelAllSessions()
        }
        UIView.animate(withDuration: 0.3) { 
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner(){
        removeSpinner()
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        spinner?.startAnimating()
        photosCollectionView?.addSubview(spinner!)
    }
    
    func addProgressLabel(){
        removeProgressLabel()
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: (screenSize.width / 2) - 120, y: 175, width: 240, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 12)
        progressLabel?.textAlignment = .center
        progressLabel?.textColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        photosCollectionView?.addSubview(progressLabel!)
    }
    
    func removeSpinner(){
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func removeProgressLabel() {
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }

    @IBAction func centerButtonPressed(_ sender: Any) {
        
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    

}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: DROP_PIN_IDENTIFIER)
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation(){
        guard let coordinates = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer){
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let dropPin = DroppablePin(coordinate: touchCoordinate, identifier: DROP_PIN_IDENTIFIER)
        removePin()
        addSwipe()
        cancelAllSessions()
        animatePhotosView(distance: -270)
        mapView.addAnnotation(dropPin)
        addSpinner()
        addProgressLabel()
        imagesArray = []
        imagesUrlArray = []
        photosInfoArray = []
        photosCollectionView?.reloadData()
        retrieveAllUrls(forAnnotation: dropPin) { (success) in
            if success {
                self.retrieveImages(handler: { (success) in
                    if success {
                        self.removeSpinner()
                        self.removeProgressLabel()
                        self.photosCollectionView?.reloadData()
                    }
                })
            }
        }
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func removePin(){
        for annotation in mapView.annotations{
            mapView.removeAnnotation(annotation)
        }
    }
    
    func retrieveAllUrls(forAnnotation annotation: DroppablePin, handler: @escaping (_ success: Bool) -> ()){
        
        
        Alamofire.request(flickrUrl(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 50)).responseJSON { (data) in
            if data.result.error == nil {
                guard let json = data.result.value as? Dictionary<String,AnyObject> else {return}
                let photosDict = json["photos"] as! Dictionary<String,AnyObject>
                let photosArray = photosDict["photo"] as! [Dictionary<String,AnyObject>]
                for photo in photosArray {
                    Alamofire.request(photosInfoUrl(forApiKey: API_KEY, forImageId: "\(photo["id"]!)", forImageSecret: "\(photo["secret"]!)")).responseJSON(completionHandler: { (response) in
                        if response.result.error == nil {
                            guard let data = response.data else {return}
                            let json = JSON(data: data)
                            let photoInfo = json["photo"]
                            let photoInfoStruct = PhotoInfo(description: photoInfo["description"]["_content"].stringValue, title: photoInfo["title"]["_content"].stringValue, longitude: photoInfo["location"]["longitude"].doubleValue, latitude: photoInfo["location"]["latitude"].doubleValue, datePosted: photoInfo["dates"]["taken"].stringValue)
                                self.photosInfoArray.append(photoInfoStruct)
                            }
                        else {
                            print(data.result.error as Any)
                        }
                    })
                    let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    self.imagesUrlArray.append(postUrl)
                }
                
                handler(true)
            }
            else {
                debugPrint(data.result.error as Any)
                handler(false)
            }
        }
        
    }
    
    func retrieveImages(handler: @escaping (_ success: Bool) -> ()){
        var numberOfRequests = 0
        for url in imagesUrlArray {
            numberOfRequests += 1
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else {return}
                self.imagesArray.append(image)
                self.progressLabel?.text = "\(self.imagesArray.count)/\(self.imagesUrlArray.count) IMAGES DOWNLOADED"
                if numberOfRequests == self.imagesUrlArray.count{
                    handler(true)
                }
            })
        }
    }
    
    
    func cancelAllSessions(){
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadTask, downloadTask) in
            sessionDataTask.forEach({$0.cancel()})
            downloadTask.forEach({$0.cancel()})
        }
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


extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTOS_CELL_IDENTIFIER, for: indexPath) as? PhotoCell else {return UICollectionViewCell()}

        let imageFromIndex = imagesArray[indexPath.row]
        let image = UIImageView(image: imageFromIndex)
        cell.addSubview(image)
        image.frame = CGRect(x: 0, y: 0, width: cell.frame.width, height: cell.frame.height)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") as? PopVC else {return}
        popVC.initData(forImage: imagesArray[indexPath.row], imageInfo: photosInfoArray[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC : UIViewControllerPreviewingDelegate{
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = photosCollectionView?.indexPathForItem(at: location), let cell = photosCollectionView?.cellForItem(at: indexPath) else {return nil}
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "popVC") as? PopVC else {return nil}
        popVC.initData(forImage: imagesArray[indexPath.row], imageInfo: photosInfoArray[indexPath.row])
        previewingContext.sourceRect = cell.contentView.frame
        return popVC
    }
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: nil)
    }
}























