//
//  VC2.swift
//  floorDetectionPOC
//
//  Created by user on 03/06/24.
//

import UIKit
import CoreLocation

class VC2: UIViewController, CLLocationManagerDelegate {
    var locationManager: CLLocationManager!
    var currentLatitude: CLLocationDegrees?
    var currentLongitude: CLLocationDegrees?
    var currentAltitude: CLLocationDistance?

    @IBOutlet weak var currentAlt: UILabel!
    @IBOutlet weak var currentFloor: UILabel!
    @IBOutlet weak var bsaeAlti: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLatitude = location.coordinate.latitude
            currentLongitude = location.coordinate.longitude
            currentAltitude = location.altitude
            print("Current Location: \(currentLatitude!), \(currentLongitude!)")
            print("Current Altitude: \(currentAltitude!) meters")

            DispatchQueue.main.async {
                self.currentAlt?.text = "Current Altitude: \(self.currentAltitude!) meters"
            }

            // After obtaining the current altitude, get the base altitude
            if let latitude = currentLatitude, let longitude = currentLongitude {
                getBaseAltitude(latitude: latitude, longitude: longitude) { [weak self] baseAltitude in
                    guard let self = self else { return }
                    if let baseAltitude = baseAltitude, let currentAltitude = self.currentAltitude {
                        print("Base Altitude: \(baseAltitude) meters")

                        DispatchQueue.main.async {
                            self.bsaeAlti?.text = "Base Altitude: \(baseAltitude) meters"
                            self.calculateCurrentFloor(currentAltitude: currentAltitude, baseAltitude: baseAltitude)
                        }
                    }
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    // Step 2: Get the Base Altitude
    func getBaseAltitude(latitude: CLLocationDegrees, longitude: CLLocationDegrees, completion: @escaping (Double?) -> Void) {
        let apiKey = "AIzaSyArJ8bQTUnA2zLyHb1xbKBV07yOveRhu3U"
        let urlString = "https://maps.googleapis.com/maps/api/elevation/json?locations=\(latitude),\(longitude)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let elevation = firstResult["elevation"] as? Double {
                    completion(elevation)
                } else {
                    completion(nil)
                }
            } catch let error {
                print("JSON Error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        
        task.resume()
    }

    // Step 3: Calculate the Current Floor
    func calculateCurrentFloor(currentAltitude: Double, baseAltitude: Double) {
        let floorHeight = 3.0 // Assume average floor height in meters
        
        let altitudeDifference = currentAltitude - baseAltitude
        let currentFloor = altitudeDifference / floorHeight
        
        DispatchQueue.main.async {
            self.currentFloor?.text = "Estimated Current Floor: \(Int(currentFloor))"
            print("Estimated Current Floor: \(Int(currentFloor))")
        }
    }
}
