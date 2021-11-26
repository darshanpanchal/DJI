//
//  MapViewController.swift
//  DJISDKSwiftDemo
//
//  Created by IPS on 30/07/20.
//  Copyright © 2020 DJI. All rights reserved.
//

import UIKit
import MapKit
import DJISDK
import CoreLocation

class MapViewController: UIViewController,CLLocationManagerDelegate,MKMapViewDelegate
 {

    
    
    
    @IBOutlet var listeningCoordinatesLabel:UILabel!
    @IBOutlet var lblLat:UILabel!
    @IBOutlet var lblLong:UILabel!
    @IBOutlet var lblAltitude:UILabel!
    @IBOutlet var lblSerialNumber:UILabel!
    
    @IBOutlet var mapView:MKMapView!
    
    let locationManager = CLLocationManager()

    var lastUpdateLocation:CLLocationCoordinate2D?
    var timer:Timer?
    
  
    
    fileprivate func configureLocationMap() {
        //For use in background
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        if let centerPoint = mapView.userLocation.location?.coordinate{
            mapView.setCenter(centerPoint, animated: true)
        }
    }
    
    fileprivate func addTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(DJISDKManager.getLogPath())

       
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            
            //configure apple map with drone location marker
            self.configureLocationMap()
            
            //ConfigureDrone Tracking
            self.configureDroneTrackingDelegate()
        }
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.timer?.invalidate()
    }
    func configureDroneTrackingDelegate(){
            //get conneected drone and assign delegate to track it
            if let flightController = self.fetchFlightController(){
            DispatchQueue.main.asyncAfter(deadline: .now() +  5.0) {
               flightController.delegate = self
                flightController.getSerialNumber { (number, error) in
                    DispatchQueue.main.async {
                        self.lblSerialNumber.text = "\(number ?? "")"
                    }
                }
                
            }
            }
            guard let droneLocationKey = DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation) else {
              return
            }
                  
            guard let droneLocationValue = DJISDKManager.keyManager()?.getValueFor(droneLocationKey) else {
              return
            }

            print(DJISDKManager.getLogPath())
            let droneLocation = droneLocationValue.value as! CLLocation
            let droneCoordinates = droneLocation.coordinate

            if !CLLocationCoordinate2DIsValid(droneCoordinates) {
              return
            }
            DispatchQueue.main.async {
            self.listeningCoordinatesLabel.text = "Drone Tracking Started...";
            self.addPinonMapWithLocation(locValue: droneCoordinates)
            }
    }
    
    fileprivate func fetchFlightController() -> DJIFlightController? {
        if let product = DJISDKManager.product(), product.isKind(of: DJIAircraft.self) {
            
            return (product as! DJIAircraft).flightController
        }
        return nil
    }

    @objc func fireTimer() {
        print("Timer fired!")
        if let flightController = self.fetchFlightController(){
            self.configureDroneTrackingDelegate()
        }else{
           DispatchQueue.main.async {
                print("Drone is disconnected")
                //self.showAlert("Drone is disconnected")
                self.droneConnectionRequest()
            }
        }
    }
    func droneConnectionRequest(){
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
                  NSLog("Error creating the connectedKey")
                  return;
              }
              
              DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                  DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                      if newValue != nil {
                          if newValue!.boolValue {
                              // At this point, a product is connected so we can show it.
                              
                              // UI goes on MT.
                              DispatchQueue.main.async {
                                  if let flightController = self.fetchFlightController(){
                                    flightController.delegate = self
                                  }
                              }
                          }
                      }
                  })
              }
    }
    func showAlert(_ msg: String?) {
        
        // create the alert
        let alert = UIAlertController(title: "Drone Connection", message: msg, preferredStyle: UIAlertController.Style.alert)
        // add the actions (buttons)
        alert.addAction(UIAlertAction.init(title: "Ok", style: .default, handler: { (_ ) in
            self.addTimer()
        }))
        self.present(alert, animated: true) {
            self.timer?.invalidate()
         }
    }
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
   
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        if let _ = self.lastUpdateLocation{
            
        }else{
           DispatchQueue.main.async {
//                self.addPinonMapWithLocation(locValue: locValue)
            }
            
        }
      
       
        
    }
    func addPinonMapWithLocation(locValue:CLLocationCoordinate2D){
                if let lastLocation = self.lastUpdateLocation{
//                    if locValue.latitude == lastLocation.latitude && lastLocation.longitude == lastLocation.longitude{
//                        return
//                    }
                    let fromLocation = CLLocation.init(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
                    let toLocation = CLLocation.init(latitude: locValue.latitude, longitude: locValue.longitude)
                    let distanceInMeters =  fromLocation.distance(from: toLocation) / 1000.0
                    print(distanceInMeters)
//                    guard distanceInMeters >= 0.5  else {
//                        return
//                    }
                      
                }else{
                    let span = DeviceType.isIpad() ? MKCoordinateSpan.init(latitudeDelta: 0.02, longitudeDelta: 0.02) : MKCoordinateSpan.init(latitudeDelta: 0.02, longitudeDelta: 0.02)
//                    let span = MKCoordinateSpan.init(latitudeDelta: 0.0001, longitudeDelta: 0.0001)
                    let region = MKCoordinateRegion(center: locValue, span: span)
                    mapView.setRegion(region, animated: true)
                }
        
        
                if self.mapView.annotations.count > 0{
                    let allAnnotation = mapView.annotations
                    self.mapView.removeAnnotations(allAnnotation)
                }
        
               mapView.mapType = MKMapType.standard

               let annotation = MKPointAnnotation()
               annotation.coordinate = locValue
//               annotation.title = "DJI"
//               annotation.subtitle = "Phantom 4"
               mapView.addAnnotation(annotation)
               self.lastUpdateLocation = locValue
        
               DispatchQueue.main.async {
                   self.lblLat.text = "\(locValue.latitude)"
                   self.lblLong.text = "\(locValue.longitude)"
               }
    }
}

extension MapViewController:DJIFlightControllerDelegate{
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        
        print(state.orientationMode)
        print(state.gpsSignalLevel)
        print(state.isFlying)
        print(state.altitude)
        if let updatedLocation = state.aircraftLocation?.coordinate{
            DispatchQueue.main.async {
                self.lblAltitude.text = "\(state.altitude)"
                self.addPinonMapWithLocation(locValue: updatedLocation)
            }
            
        }
    }
}
class DeviceType{
    class func isIpad()->Bool
    {
        return UIDevice.current.userInterfaceIdiom == .pad ? true : false
    }
}
