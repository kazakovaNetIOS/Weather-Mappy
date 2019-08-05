//
//  ViewController.swift
//  Weather Mappy
//
//  Created by Natalia Kazakova on 04/08/2019.
//  Copyright © 2019 Natalia Kazakova. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    let WEATHER_URL = "https://api.openweathermap.org/data/2.5/find"
    let APP_ID = "9aea5e4452f904a6271af83832c7ac23"
    let CITY_COUNT = "10"
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var warningLabel: UILabel!
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    func getWeatherData(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                let weatherJSON: JSON = JSON(response.result.value!)
                
                self.updateWeatherData(json: weatherJSON)
            } else {
                print("Error \(String(describing: response.result.error))")
                
                self.warningLabel.text = "Connection Issues"
                self.warningLabel.isHidden = false
            }
        }
    }
    
    //MARK: - JSON Parsing
    /***************************************************************/
    
    func updateWeatherData(json: JSON) {
        let list = json["list"]
        
        guard list.count > 0 else {
            warningLabel.text = "Weather Unavailable"
            warningLabel.isHidden = false
            return
        }
        
        for point in list {
            let weatherModel = WeatherModel(temperature: Int(point.1["main"]["temp"].double! - 273.15),
                                            latitude: point.1["coord"]["lat"].double!,
                                            longtitude: point.1["coord"]["lon"].double!,
                                            condition: point.1["weather"][0]["id"].intValue)
            
            updateUIWithWeatherData(with: weatherModel)
        }
    }
    
    //MARK: - UI Updates
    /***************************************************************/
    
    func updateUIWithWeatherData(with weatherModel: WeatherModel) {
        let markerView = MarkerView(frame: CGRect(x: 0, y: 0, width: 50, height: 70),
                                    picture: weatherModel.getIcon(),
                                    temperature: String(weatherModel.temperature))
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: weatherModel.latitude,
                                                 longitude: weatherModel.longtitude)
        marker.icon = markerView.asImage()
        marker.opacity = 0.7
        marker.map = mapView
        
        warningLabel.isHidden = true
    }
}

//MARK: - Location Manager Delegate Methods
/***************************************************************/

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        mapView.camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 12.0)
        
        locationManager.stopUpdatingLocation()
        
        let params: [String : String] = [
            "lat": String(latitude),
            "lon": String(longitude),
            "cnt": CITY_COUNT,
            "lang": "ru",
            "appid": APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
        
        warningLabel.isHidden = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        warningLabel.text = "Location Unavailable"
        warningLabel.isHidden = false
    }
}
