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
    
    private let WEATHER_URL = "https://api.openweathermap.org/data/2.5/find"
    private let APP_ID = "9aea5e4452f904a6271af83832c7ac23"
    private let CITY_COUNT = "10"
    
    private let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var warningLabel: UILabel!
}

//MARK: - Override methods
/***************************************************************/

extension ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationManager()
    }
}

//MARK: - Networking
/***************************************************************/

extension ViewController {
    private func getWeatherData(url: String, parameters: [String : String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON { response in
            if response.result.isSuccess {
                let weatherJSON: JSON = JSON(response.result.value!)
                
                self.updateWeatherData(json: weatherJSON)
            } else {
                print("Error \(String(describing: response.result.error?.localizedDescription))")
                
                self.showError(msg: "Connection Issues")
            }
        }
    }
}

//MARK: - UI Updates
/***************************************************************/

extension ViewController {
    private func updateUI(with data: WeatherData) {
        let markerView = MarkerView(frame: CGRect(x: 0, y: 0, width: 50, height: 70),
                                    picture: data.getIcon(),
                                    temperature: String(data.temperature))
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: data.latitude,
                                                 longitude: data.longtitude)
        marker.icon = markerView.asImage()
        marker.opacity = 0.7
        marker.title = data.city
        marker.map = mapView
        
        hideError()
    }
    
    private func showError(msg: String) {
        self.warningLabel.text = msg
        self.warningLabel.isHidden = false
    }
    
    private func hideError() {
        self.warningLabel.isHidden = true
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
}

//MARK: - JSON Parsing
/***************************************************************/

extension ViewController {
    private func updateWeatherData(json: JSON) {
        let list = json["list"]
        
        guard list.count > 0 else {
            showError(msg: "Weather Unavailable")
            return
        }
        
        for point in list {
            let weatherData = WeatherData(temperature: Int(point.1["main"]["temp"].double! - 273.15),
                                          latitude: point.1["coord"]["lat"].double!,
                                          longtitude: point.1["coord"]["lon"].double!,
                                          city: point.1["name"].stringValue,
                                          condition: point.1["weather"][0]["id"].intValue)
            
            updateUI(with: weatherData)
        }
    }
}

//MARK: - CLLocationManagerDelegate
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
        
        mapView.camera = GMSCameraPosition.camera(withLatitude: latitude,
                                                  longitude: longitude,
                                                  zoom: 12.0)
        
        locationManager.stopUpdatingLocation()
        
        let params: [String : String] = [
            "lat": String(latitude),
            "lon": String(longitude),
            "cnt": CITY_COUNT,
            "lang": "ru",
            "appid": APP_ID]
        
        getWeatherData(url: WEATHER_URL, parameters: params)
        
        hideError()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error.localizedDescription)")
        showError(msg: "Location Unavailable")
    }
}
