//
//  StartupViewController.swift
//  DJISDKSwiftDemo
//
//  Created by DJI on 11/13/15.
//  Copyright © 2015 DJI. All rights reserved.
//

import UIKit
import DJISDK
import Network

class StartupViewController: UIViewController {

    weak var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var productConnectionStatus: UILabel!
    @IBOutlet weak var productModel: UILabel!
    @IBOutlet weak var productFirmwarePackageVersion: UILabel!
    @IBOutlet weak var openComponents: UIButton!
    @IBOutlet weak var bluetoothConnectorButton: UIButton!
    @IBOutlet weak var sdkVersionLabel: UILabel!
    @IBOutlet weak var bridgeModeLabel: UILabel!
    @IBOutlet weak var buttonTrackDrone:UIButton!
    @IBOutlet weak var lblWifiIpAddress:UILabel!
    
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
        
        do {
        let value =  try self.checkReactionnOperation()
            print(value)
        }catch TemperatureError.cold{
            
        }catch TemperatureError.hot{
        
        } catch{
            print(error.localizedDescription)
        }
        
        let rain = #"darshan panchal"#
        print(rain)
    
        
        
        if let wifi = self.getAddress(for: .wifi){
            self.lblWifiIpAddress.text = "Connected Wifi IP \(wifi)"
        }
        
    }
    
    //What's new in Swift 5.3
    enum TemperatureError:Error{
        case cold
        case hot
    }
    func checkReactionnOperation() throws -> String{
        let temp = self.getCurrentTemprature()
        
        if temp < 10{
            throw TemperatureError.cold
        }else if temp > 90{
            throw TemperatureError.hot
        }else{
            return "ok"
        }
    }
    
    
    
    func getCurrentTemprature()->Int{
        return 5
    }
    func getTempratureInCelsis(fer:CGFloat)->CGFloat{
        return 0.0
    }
    func getTempratureInFehrenhit(cel:CGFloat)->CGFloat{
        return 0.0
    }
    
    
    
    func getAddress(for network: Network) -> String? {
        var address: String?

        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        // For each interface ...
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee

            // Check for IPv4 or IPv6 interface:
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                // Check interface name:
                let name = String(cString: interface.ifa_name)
                if name == network.rawValue {

                    // Convert interface address to a human readable string:
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
      
        //Drone Connection listener with key
        self.droneConnectionListenerDJISDKManager()
        //Add timer to reconnect applications once app comes from background
        DispatchQueue.main.async {
            if let wifi = self.getAddress(for: .wifi){
                self.lblWifiIpAddress.text = "Connected Wifi IP \(wifi)"
            }
        }
    }
    
    //Add timer to check current drone connetion status and try to reconnect drone
   func addTimer() {
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    @objc func fireTimer() {
          print("Timer fired!")
          if let _ = self.fetchFlightController(){
            
          }else{
             DispatchQueue.main.async {
                  print("Drone is disconnected")
                  self.droneConnectionListenerDJISDKManager()
              }
          }
    }
    //Fetch connected drone
    fileprivate func fetchFlightController() -> DJIFlightController? {
           if let product = DJISDKManager.product(), product.isKind(of: DJIAircraft.self) {
               
               return (product as! DJIAircraft).flightController
           }
           return nil
       }
    //Drone Connection Listener
    func droneConnectionListenerDJISDKManager(){
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
                                 self.productConnected()
                             }
                         }
                     }
                 })
                 DJISDKManager.keyManager()?.getValueFor(connectedKey, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                     if let unwrappedValue = value {
                         if unwrappedValue.boolValue {
                             // UI goes on MT.
                             DispatchQueue.main.async {
                                 self.productConnected()
                             }
                         }
                     }
                 })
             }
    }
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    @IBAction func buttonTrackDroneSelector(sender:UIButton){
        self.performSegue(withIdentifier: "mapDetail", sender: self.buttonTrackDrone)
    }
    
    func resetUI() {
        self.title = "DJI iOS SDK Sample"
        self.sdkVersionLabel.text = "DJI SDK Version: \(DJISDKManager.sdkVersion())"
        self.openComponents.isEnabled = false; //FIXME: set it back to false
        self.buttonTrackDrone.isEnabled = false; //FIXME: set it back to false
        self.bluetoothConnectorButton.isEnabled = true; 
        self.productModel.isHidden = true
        self.productFirmwarePackageVersion.isHidden = true
        self.bridgeModeLabel.isHidden = !self.appDelegate.productCommunicationManager.enableBridgeMode
        
        if self.appDelegate.productCommunicationManager.enableBridgeMode {
            self.bridgeModeLabel.text = "Bridge: \(self.appDelegate.productCommunicationManager.bridgeAppIP)"
        }
    }
    
    func showAlert(_ msg: String?) {
        // create the alert
        let alert = UIAlertController(title: "", message: msg, preferredStyle: UIAlertController.Style.alert)
        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK : Product connection UI changes
    
    func productConnected() {
        guard let newProduct = DJISDKManager.product() else {
            NSLog("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }

        //Updates the product's model
        self.productModel.text = "Model: \((newProduct.model)!)"
        self.productModel.isHidden = false
        
        //Updates the product's firmware version - COMING SOON
        newProduct.getFirmwarePackageVersion{ (version:String?, error:Error?) -> Void in
            
            self.productFirmwarePackageVersion.text = "Firmware Package Version: \(version ?? "Unknown")"
            
            if let _ = error {
                self.productFirmwarePackageVersion.isHidden = true
            }else{
                self.productFirmwarePackageVersion.isHidden = false
            }
            
            NSLog("Firmware package version is: \(version ?? "Unknown")")
        }
        
        //Updates the product's connection status
        self.productConnectionStatus.text = "Status: Product Connected"
        
        self.openComponents.isEnabled = true;
        self.buttonTrackDrone.isEnabled = true
        self.openComponents.alpha = 1.0;
        NSLog("Product Connected")
        
    }
    
    func productDisconnected() {
        self.productConnectionStatus.text = "Status: No Product Connected"

        self.openComponents.isEnabled = false;
        self.buttonTrackDrone.isEnabled = false
        self.openComponents.alpha = 0.8;
        NSLog("Product Disconnected")
    }
    
}


enum Network: String {
    case wifi = "en0"
    case cellular = "pdp_ip0"
    //... case ipv4 = "ipv4"
    //... case ipv6 = "ipv6"
}


