//
//  AlitimeterManager.swift
//  floorDetectionPOC
//
//  Created by user on 31/05/24.
//

import CoreMotion
import UIKit
 
class AltitudeManager {
    private let altimeter = CMAltimeter()
    private var startingAltitude: Double?
    private let averageFloorHeight: Double = 3.4 // Average height per floor in meters
 
    func startMonitoring() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            print("Altimeter not available on this device.")
            return
        }
 
        altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] (data, error) in
            guard let self = self, let data = data else {
                print("No data received or an error occurred.")
                return
            }
 
            if self.startingAltitude == nil {
                self.startingAltitude = data.relativeAltitude.doubleValue
            }
 
            let altitudeChange = data.relativeAltitude.doubleValue - (self.startingAltitude ?? 0.0)
            let currentFloor = Int(round(altitudeChange / self.averageFloorHeight))
 
            print("Current floor: \(currentFloor)")
        }
    }
 
    func stopMonitoring() {
        altimeter.stopRelativeAltitudeUpdates()
    }
}

