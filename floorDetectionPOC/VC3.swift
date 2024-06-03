//
//  VC3.swift
//  floorDetectionPOC
//
//  Created by Amit Yadav on 03/06/24.
//

import UIKit
import GoogleMaps
import CoreLocation

class VC3: UIViewController, CLLocationManagerDelegate {

    @IBOutlet var currentAltitude: UILabel!
    @IBOutlet var currentFloor: UILabel!
    var locationManager: CLLocationManager!
    var referenceAltitude: CLLocationDistance?

    @IBOutlet var relativeAltitude: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        referenceAltitude = CLLocationDistance(floatLiteral: 233.5)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let altitude = location.altitude

            // If reference altitude is not set, assume the current altitude is the ground level
            if referenceAltitude == nil {
                referenceAltitude = altitude
                print("Reference altitude set to: \(referenceAltitude!) meters")

            }

            if let referenceAltitude = referenceAltitude {
                DispatchQueue.main.async {
                    self.relativeAltitude.text = "Reference altitude: \(referenceAltitude) meter"
                }
                DispatchQueue.main.async {
                    self.currentAltitude.text = "Current altitude: \(altitude) meter"
                }
                let relativeAltitude = altitude - referenceAltitude
                let floorNumber = calculateFloor(from: relativeAltitude)
                DispatchQueue.main.async {
                    self.currentFloor.text = "Estimated Floor: \(floorNumber)"
                }
                print("Altitude: \(altitude) meters, Relative Altitude: \(relativeAltitude) meters, Estimated Floor: \(floorNumber)")
            }
        }
    }

    func calculateFloor(from relativeAltitude: CLLocationDistance) -> Int {
        let standardFloorHeight: CLLocationDistance = 4 // average floor height in meters
        return Int(ceil(relativeAltitude / standardFloorHeight))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
}
