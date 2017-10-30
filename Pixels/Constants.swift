//
//  Constants.swift
//  Pixels
//
//  Created by Kareem Ismail on 9/14/17.
//  Copyright © 2017 Whatever. All rights reserved.
//

import Foundation


let DROP_PIN_IDENTIFIER = "droppablePin"

let PHOTOS_CELL_IDENTIFIER = "photosCell"

let API_KEY = "45c545f1f42778903c900eb2c90e792d"

func flickrUrl(forApiKey key: String, withAnnotation annotation: DroppablePin, andNumberOfPhotos number: Int) -> String{
    
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(key)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    
}

func photosInfoUrl(forApiKey key: String, forImageId id: String, forImageSecret secret: String ) -> String{
    
    return "https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=\(key)&photo_id=\(id)&secret=\(secret)&format=json&nojsoncallback=1"
    
}
