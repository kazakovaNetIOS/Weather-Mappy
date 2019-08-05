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
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var warningLabel: UILabel!
    
    private let locationManager = CLLocationManager()
    private var weatherDataModel = WeatherDataModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    //MARK: - Networking
    /***************************************************************/
    
    func getWeatherData(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                print("Success! Get the weather data")
                
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
        for point in json["list"] {
            
            if let tempResult = point.1["main"]["temp"].double,
                let lat = point.1["coord"]["lat"].double,
                let lon = point.1["coord"]["lon"].double{
                weatherDataModel = WeatherDataModel()
                weatherDataModel.latitude = lat
                weatherDataModel.longtitude = lon
                weatherDataModel.temperature = Int(tempResult - 273.15)
                weatherDataModel.city = point.1["name"].stringValue
                weatherDataModel.condition = point.1["weather"][0]["id"].intValue
                weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
                
                updateUIWithWeatherData()
            } else {
                warningLabel.text = "Weather Unavailable"
                warningLabel.isHidden = false
            }
        }
    }
    
    //MARK: - UI Updates
    /***************************************************************/
    
    func updateUIWithWeatherData() {
        let markerView = MarkerView(frame: CGRect(x: 0, y: 0, width: 50, height: 70),
                                    picture: weatherDataModel.weatherIconName,
                                    temperature: String(weatherDataModel.temperature))
        let markerImage = markerView.asImage()
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: weatherDataModel.latitude,
                                                 longitude: weatherDataModel.longtitude)
        marker.icon = markerImage
        marker.opacity = 0.7
        marker.map = mapView
        
        warningLabel.isHidden = true
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
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
        locationManager.delegate = nil
        
        let params: [String : String] = [
            "lat": String(latitude),
            "lon": String(longitude),
            "cnt": "2",
            "lang": "ru",
            "appid": APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        //        cityLabel.text = "Location Unavailable"
    }
}
