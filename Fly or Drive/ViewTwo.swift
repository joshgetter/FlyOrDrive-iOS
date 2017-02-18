//
//  ViewTwo.swift
//  Fly or Drive
//
//  Created by Josh Getter on 5/7/15.
//  Copyright (c) 2015 Josh Getter. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps
import CoreLocation
import GoogleMobileAds
import Firebase
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

class ViewTwo: UIViewController{
    
    @IBAction func backButtonClick(_ sender: AnyObject) {
        
    }
    @IBOutlet weak var adBanner: GADBannerView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    @IBOutlet weak var googleMap: GMSMapView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var carYearTextField: UITextField!
    @IBOutlet weak var driveTimeLabel: UILabel!
    @IBOutlet weak var driveDistanceLabel: UILabel!
    @IBOutlet weak var flightCostLabel: UILabel!
    @IBOutlet weak var flightDurationLabel: UILabel!
    @IBOutlet weak var flightDistanceLabel: UILabel!
    @IBOutlet weak var driveCostLabel: UILabel!

    
    var carYearsToTransfer = [String]();
    var driveDistanceText = String();
    var driveTimeText = String();
    var driveCost = String();
    var selectedYear = String();
    var flightPrice = String();
    var flightDuration = String();
    var flightDistance = String();
    var startCord = CLLocationCoordinate2D();
    var endCord = CLLocationCoordinate2D();
    var polyline = String();
    var isRoundTrip = Bool();
    
    override func viewDidLoad() {
        adBanner.adUnitID = "ca-app-pub-4082194909024613/8447440283"
        adBanner.rootViewController = self
        adBanner.load(GADRequest())
        //let flightpriceNS = NSString(string: flightPrice);
        //let cleanFlightPrice = flightpriceNS.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).joinWithSeparator("");
        let cleanFlightPrice = flightPrice.replacingOccurrences(of: "USD", with: "");
        driveDistanceLabel.text = "Drive Distance: " + driveDistanceText;
        driveTimeLabel.text = "Drive Time: " + driveTimeText;
        if(isRoundTrip == true)
        {
            if(driveCost == "Not available")
            {
                driveCostLabel.text = "Drive Cost: " + driveCost;
            }
            else
            {
                driveCostLabel.text = "Drive Cost (Round Trip): USD" + driveCost;
            }
            flightCostLabel.text = "Flight Cost (Round Trip): " + flightPrice;
        }
        else
        {
            if(driveCost == "Not available")
            {
                driveCostLabel.text = "Drive Cost: " + driveCost;
            }
            else
            {
                driveCostLabel.text = "Drive Cost: USD" + driveCost;
            }
            flightCostLabel.text = "Flight Cost: " + flightPrice;
        }
        flightDistanceLabel.text = "Flight Distance: " + flightDistance;
        flightDurationLabel.text = flightDuration;
        
        flightCostLabel.numberOfLines = 0;
        driveTimeLabel.numberOfLines = 0;
        driveDistanceLabel.numberOfLines = 0;
        flightDurationLabel.numberOfLines = 0;
        flightDistanceLabel.numberOfLines = 0;
        driveCostLabel.numberOfLines = 0;
        
        flightCostLabel.sizeToFit();
        flightDistanceLabel.sizeToFit();
        flightDurationLabel.sizeToFit();
        driveDistanceLabel.sizeToFit();
        driveTimeLabel.sizeToFit();
        driveCostLabel.sizeToFit();
        
        if(polyline.isEmpty == false)
        {
        let path = GMSPath(fromEncodedPath: polyline);
        let polyLinePath = GMSPolyline(path: path);
        polyLinePath.strokeColor = UIColor.blue;
        polyLinePath.map = googleMap;
        }
        
        let flightPath = GMSMutablePath();
        flightPath.add(startCord);
        flightPath.add(endCord);
        let flightPolyLine = GMSPolyline(path: flightPath);
        flightPolyLine.strokeColor = UIColor.red;
        flightPolyLine.map = googleMap;
        
        let bounds = GMSCoordinateBounds(coordinate: startCord, coordinate: endCord);
        let inset = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50);
        let camera = googleMap.camera(for: bounds, insets: inset);
        googleMap.camera = camera!;
        let startMarker = GMSMarker();
        startMarker.position = startCord;
        startMarker.appearAnimation = GMSMarkerAnimation.pop
        let endMarker = GMSMarker();
        endMarker.position = endCord;
        endMarker.appearAnimation = GMSMarkerAnimation.pop;
        startMarker.map = googleMap;
        endMarker.map = googleMap;
        
        if(Float(driveCost) < Float(cleanFlightPrice) && driveCost != "Not available")
        {
            self.title = "Drive!"
        }
        else
        {
            self.title = "Fly!"
        }
        
    }
    
    
    
}
