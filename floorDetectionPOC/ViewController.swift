//
//  ViewController.swift
//  floorDetectionPOC
//
//  Created by user on 31/05/24.
//
import UIKit
import CoreMotion
 
class ViewController: UIViewController {
    
    var altimeterManager: CMAltimeter?
    let motionManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    
    @IBOutlet var altitudeChangefromStarting: UILabel!
    @IBOutlet var newAltitiude: UILabel!
    @IBOutlet weak var altimeterLabel: UILabel!
    
    var startingAltitude: Double?  // Declare startingAltitude property
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestMotionPermission()
    }
    
    func requestMotionPermission() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionManager.startActivityUpdates(to: OperationQueue.main) { [weak self] (activity: CMMotionActivity?) in
                // Permission granted, now start altimeter updates
                self?.startAltimeterUpdates()
            }
        } else {
            // Motion activity not available
            print("Motion activity not available")
        }
        
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: Date()) { [weak self] (pedometerData: CMPedometerData?, error: Error?) in
                // Permission granted, now start altimeter updates
                self?.startAltimeterUpdates()
            }
        } else {
            // Pedometer not available
            print("Pedometer not available")
        }
    }
    
    func startAltimeterUpdates() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else {
            print("Altimeter not available")
            return
        }
        
        altimeterManager = CMAltimeter()
        altimeterManager?.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] altitudeData, error in
            guard let self = self, let altitudeData = altitudeData else { return }
            let relativeAltitude = altitudeData.relativeAltitude.doubleValue
            print("relative altitude: \(relativeAltitude)")
            // Assuming a standard floor height of 3.5 meters
            let averageFloorHeight = 3.0
            
            if self.startingAltitude == nil {
                // Set the starting altitude
                self.startingAltitude = relativeAltitude
            }
        
            let altitudeChange = relativeAltitude - (self.startingAltitude ?? 0.0)
            
            // Estimate the current floor based on the average floor height
            let currentFloor = Int(round(altitudeChange / averageFloorHeight))
            // Format the altitude change with unit
           
 
            // Format the altitude change with unit
            let altitudeChangeString = String(format: "%.2f m", altitudeChange)
 
            // Calculate the difference in altitude from the starting point
            let altitudeChangeFromStarting = (self.startingAltitude ?? 0.0) - relativeAltitude
 
            // Format the difference in altitude with unit
            let altitudeChangeFromStartingString = String(format: "%.2f m", altitudeChangeFromStarting)
 
            // Update UI with current floor and altitude change
            DispatchQueue.main.async {
                self.altimeterLabel.text = "Current Floor: \(currentFloor)"
                self.newAltitiude.text = "Altitude Change: \(altitudeChangeString)"
                self.altitudeChangefromStarting.text = "From Starting: \(altitudeChangeFromStartingString)"
            }
        }
    }
 
 
}

