//
//  ViewController.swift
//  Fly or Drive
//
//  Created by Josh Getter on 5/3/15.
//  Copyright (c) 2015 Josh Getter. All rights reserved.
//
//TODO app icon and launch screen.
//TODO Error checking (incorrect locations, entering states)

//TODO LATER:
//TODO rental cars (probably check box) and spinner with vehicle sizes?
//TODO Organize Code

import UIKit
import Foundation
import CoreLocation
import QuartzCore
import iAd

class ViewController: UIViewController, NSXMLParserDelegate, UITextFieldDelegate, CLLocationManagerDelegate,UIPickerViewDelegate, UIPickerViewDataSource {
    var locManager = CLLocationManager()
    @IBOutlet weak var goButtonItem: UIBarButtonItem!
    @IBOutlet weak var startLoc: UITextField!
    @IBOutlet weak var endLoc: UITextField!
    @IBOutlet weak var selectCarField: UITextField!
    @IBOutlet weak var getLocButton: UIButton!
    @IBOutlet weak var departureDateField: UITextField!
    @IBOutlet weak var numPassengerField: UITextField!
    @IBOutlet weak var returnDateField: UITextField!

    var selectedCarMPG = String();
    var dateViewPicker = UIDatePicker();
    var returnDateViewPicker = UIDatePicker();
    var driveDistance = "";
    var driveDistanceToTransfer = String();
    var driveTimeToTransfer = String();
    var airportCitiesList = String();
    var gasPrice = String();
    var flightPriceToTransfer:String = "";
    var flightDataToTransfer = [String: String]();
    let hotelCostPerNight = 100;
    var driveCostToTransfer:String = "";
    var userDefualts = NSUserDefaults.standardUserDefaults();
    var departureDate = NSDate();
    var returnDate = NSDate();
    var gpsLat:CLLocationDegrees = 0.0;
    var gpsLon:CLLocationDegrees = 0.0;
    var startLat = String();
    var startLon = String();
    var endLat = String();
    var endLon = String();
    var polyline = String();
    var savedCars = Array<Array<String>>();
    var pickerViewCars = UIPickerView();
    var numPassengers:Int = 1;
    var isRoundTrip = Bool();
    var continueWithNoDrive = Bool();
    
    
    @IBAction func numPassengersIncrement(sender: UIStepper) {
        numPassengers = Int(sender.value);
        numPassengerField.text = String(numPassengers);
    }
    
    @IBAction func editingDepartureDateField(sender: AnyObject) {
        let currDate = NSDate();
        let components = NSDateComponents();
        let info = sender.description;
        let tag = sender.tag;
        components.setValue(1, forComponent: NSCalendarUnit.Year);
        let oneYear = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: currDate, options: NSCalendarOptions(rawValue: 0));
        
        if(sender.tag == 1)//Tag represents departure field
        {
        dateViewPicker.datePickerMode = UIDatePickerMode.Date;
        dateViewPicker.minimumDate = currDate;
        dateViewPicker.maximumDate = oneYear;
        departureDateField.inputView = dateViewPicker;
        dateViewPicker.addTarget(self, action: Selector("handleDatePick:"), forControlEvents: UIControlEvents.ValueChanged);
        //handleDatePick(dateViewPicker);
        //let tempDate = dateViewPicker.date;
        }
        if(sender.tag == 2)//Tag represents return field
        {
            returnDateViewPicker.datePickerMode = UIDatePickerMode.Date;
            returnDateViewPicker.minimumDate = departureDate;
            returnDateViewPicker.maximumDate = oneYear;
            returnDateField.inputView = returnDateViewPicker;
            returnDateViewPicker.addTarget(self, action: Selector("handleDatePick:"), forControlEvents: UIControlEvents.ValueChanged);
            //handleDatePick(returnDateViewPicker);
        }
        
    }
    
    @IBAction func getLocatoinPressed(sender: AnyObject) {
        locManager.delegate = self
        locManager.requestWhenInUseAuthorization()
        locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locManager.startUpdatingLocation();
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways)
        {
            
            if(getLocButton.selected == false)
            {
                getLocButton.selected = true;
                startLoc.text = "Current Location";
                startLoc.textColor = UIColor.blueColor();
                
                gpsLat = (locManager.location?.coordinate.latitude)!;
                gpsLon = (locManager.location?.coordinate.longitude)!;
                if(gpsLat == 0 && gpsLon == 0)
                {
                    self.getLocButton.selected = false;
                    self.presentViewController(simpleAlert("Oops", Message: "The current location was not found, try entering your location manually."), animated: true, completion: nil);
                }
            }
            else
            {
                getLocButton.selected = false;
                startLoc.text = "";
                startLoc.textColor = UIColor.blackColor();
            }
            
        }
        
        
    }
    
    @IBAction func editingCarSelection(sender: AnyObject) {
        pickerViewCars.dataSource = self;
        pickerViewCars.delegate = self;
        selectCarField.inputView = pickerViewCars;
        let selectedRow = pickerViewCars.selectedRowInComponent(0);
        if(selectedRow == 0)
        {
            pickerViewCars.selectRow(0, inComponent: 0, animated: false);
            pickerView(pickerViewCars, didSelectRow: 0, inComponent: 0);
        }
    }
    
    @IBAction func goButton(sender: AnyObject) {
        if(Reachability.isConnectedToNetwork() == false)
        {
            self.presentViewController(simpleAlert("Info", Message: "There seems to be a network issue, make sure airplane mode is off and that the device has a network connection."), animated: true, completion: nil);
            return;
        }
        if(startLoc.text?.isEmpty == true || endLoc.text?.isEmpty == true || departureDateField.text?.isEmpty == true || selectCarField.text?.isEmpty == true)
        {
            presentViewController(simpleAlert("Oops", Message: "Please make sure the required fields are not blank"), animated: true, completion: nil)
            return;
        }
        if(returnDateField.text?.isEmpty == false)
        {
            if(returnDate.timeIntervalSinceDate(departureDate) < 0)//Return date must be after departure date.
            {
                self.presentViewController(simpleAlert("Oops", Message: "Make sure the return date is after the departure date."), animated: true, completion: nil);
                return;
                //Stop spinner.
            }
        }
        
        goButtonItem.enabled = false;
        [MBProgressHUD.showHUDAddedTo(self.view, animated: true)];
        let backgroundThread = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_async(backgroundThread) { () -> Void in
            var startLocText = String();
            if(self.gpsLat != 0 && self.gpsLon != 0 && self.getLocButton.selected == true)//Use GPS coordinate or calculate it.
            {
                startLocText = String(self.gpsLat) + "," + String(self.gpsLon);
            }
            else
            {
                startLocText = self.startLoc.text!;
            }
            let endLocText = self.endLoc.text;
            let gDirectionsUrlString = "http://maps.googleapis.com/maps/api/directions/json?origin=" + startLocText + "&destination=" + endLocText!;
            let gDirectionsUrlFormatted = gDirectionsUrlString.stringByReplacingOccurrencesOfString(" ", withString: "%20")
            let gDirectionsUrl = NSURL(string: gDirectionsUrlFormatted);
            
            if let webData = NSData(contentsOfURL: gDirectionsUrl!){
                var error: NSError?
                let json = JSON(data: webData)
                let status = json["status"].stringValue;
                if(status != "OK") //Something wrong about drive directions
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        [MBProgressHUD.hideHUDForView(self.view, animated: true)]
                        if(status == "ZERO_RESULTS")//Not possible to drive
                        {

                            let alert = simpleAlert("Oops", Message: "It looks like there is no way to drive there... yet");
                            alert.addAction(UIAlertAction(title: "Show Flight", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                                [MBProgressHUD.showHUDAddedTo(self.view, animated: true)];
                                dispatch_async(backgroundThread, { () -> Void in
                                    self.continueWithNoDrive = true;
                                self.flightDriveCalculation(false, json: json);
                                })
                    
                            }))
                            self.presentViewController(alert, animated: true, completion: nil);
                            if(self.continueWithNoDrive != true) //User chose not to continue with flight cost.
                            {
                                self.goButtonItem.enabled = true;
                                return;
                            }
                            
                        }
                        else //Any other error
                        {
                            self.presentViewController(simpleAlert("Oops", Message: "It looks like something is wrong right now, try changing your input or trying again later"), animated: true, completion: nil);
                            self.goButtonItem.enabled = true;
                            return;
                        }
                    })
                    
                }
                else
                {
                    self.flightDriveCalculation(true, json: json);
                }
                
                
                
                
            }
        };
    }
    func flightDriveCalculation(flightAndDrive : Bool, json: JSON)
    {
        if(flightAndDrive == true)//Calculate both
        {
            let driveDistanceTemp = json["routes",0,"legs",0,"distance","value"].stringValue;
            let driveDistanceDouble = (driveDistanceTemp as NSString).doubleValue * 0.000621371;
            self.driveDistanceToTransfer = String(format: "%.2f miles", driveDistanceDouble);
            self.driveTimeToTransfer = json["routes",0,"legs",0,"duration","text"].string!;
            let driveTimeValue = json["routes",0,"legs",0,"duration","value"].float! / 3600;
            self.startLat = json["routes",0,"legs",0,"start_location","lat"].stringValue;
            self.startLon = json["routes",0,"legs",0,"start_location","lng"].stringValue;
            self.endLat = json["routes",0,"legs",0,"end_location","lat"].stringValue;
            self.endLon = json["routes",0,"legs",0,"end_location","lng"].stringValue;
            self.polyline = json["routes",0,"overview_polyline","points"].stringValue;
            let stopCost = (ceil(driveTimeValue / (Float(self.userDefualts.integerForKey("driveHoursPerDay"))))-1) * (Float(self.hotelCostPerNight));
            var driveCost:Float = 0;
            if(returnDateField.text?.isEmpty == false)//Round trip
            {
                self.flightDataToTransfer = getAirports(self.startLat, startLon: self.startLon, endLat: self.endLat, endLon: self.endLon,departureDate: self.departureDate , returnDate: self.returnDate, numberOfPassengers: self.numPassengers);
                
                driveCost = (Float(driveDistanceDouble) / Float(self.selectedCarMPG)!) * Float(self.gasPrice)! + stopCost;
                driveCost = driveCost * 2;
                self.isRoundTrip = true;
            }
            else //one way
            {
                self.flightDataToTransfer = getAirports(self.startLat, startLon: self.startLon, endLat: self.endLat, endLon: self.endLon,departureDate: self.departureDate , returnDate: nil, numberOfPassengers: self.numPassengers);
                
                driveCost = (Float(driveDistanceDouble) / Float(self.selectedCarMPG)!) * Float(self.gasPrice)! + stopCost;
                self.isRoundTrip = false;
            }
            self.driveCostToTransfer = String(format: "%.2f", driveCost);
            flightDriveCalculationsDone();

        }
        else//Only calculate flight (Driving must not be possible)
        {
            let startPlaceID = json["geocoded_waypoints",0,"place_id"].stringValue;
            let endPlaceID = json["geocoded_waypoints", 1, "place_id"].stringValue;
            let reverseGeocodeURLStart = NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?place_id=\(startPlaceID)&key=AIzaSyCBbrKUVoZId8GB_7m1k_tIatUQBQ63k_I");
            let reverseGeocodeURLEnd = NSURL(string: "https://maps.googleapis.com/maps/api/geocode/json?place_id=\(endPlaceID)&key=AIzaSyCBbrKUVoZId8GB_7m1k_tIatUQBQ63k_I");
            
            if(gpsLat != 0 && gpsLon != 0 && getLocButton.selected == true)
            {
                startLat = String(gpsLat);
                startLon = String(gpsLon);
            }
            else
            {
                if let startLocWebData = NSData(contentsOfURL: reverseGeocodeURLStart!){
                    let startLocJson = JSON(data: startLocWebData);
                    startLat = startLocJson["results",0,"geometry","location","lat"].stringValue;
                    startLon = startLocJson["results",0,"geometry","location","lng"].stringValue;
                    
                }
            }
            if let endLocWebData = NSData(contentsOfURL: reverseGeocodeURLEnd!){
                let endLocJson = JSON(data: endLocWebData);
                endLat = endLocJson["results",0,"geometry","location","lat"].stringValue;
                endLon = endLocJson["results",0,"geometry","location","lng"].stringValue;
            }
            
            if(returnDateField.text?.isEmpty == false)//Round trip
            {
                self.flightDataToTransfer = getAirports(self.startLat, startLon: self.startLon, endLat: self.endLat, endLon: self.endLon,departureDate: self.departureDate , returnDate: self.returnDate, numberOfPassengers: self.numPassengers);
                self.isRoundTrip = true;
            }
            else //one way
            {
                self.flightDataToTransfer = getAirports(self.startLat, startLon: self.startLon, endLat: self.endLat, endLon: self.endLon,departureDate: self.departureDate , returnDate: nil, numberOfPassengers: self.numPassengers);
                self.isRoundTrip = false;
            }
            driveCostToTransfer = "Not available";
            driveDistanceToTransfer = "Not available";
            driveTimeToTransfer = "Not available";
            polyline = "";
            flightDriveCalculationsDone();
        }
    }
    func flightDriveCalculationsDone()
    {
        if(self.flightDataToTransfer["errors"]?.isEmpty == false)
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                [MBProgressHUD.hideHUDForView(self.view, animated: true)]
                self.presentViewController(simpleAlert("Oops", Message: self.flightDataToTransfer["errors"]!), animated: true, completion: nil);
                self.goButtonItem.enabled = true;
                return;
            })
        }
        if(self.flightDataToTransfer["price"]?.isEmpty == true)//Checks if flights are available
        {
            dispatch_async(dispatch_get_main_queue(), {
                [MBProgressHUD.hideHUDForView(self.view, animated: true)]
                self.presentViewController(simpleAlert("Oops", Message: "It looks like there are no flights available for that day or location, try a different date or location"), animated: true, completion: nil);
                self.goButtonItem.enabled = true;
                return;
            });
        }
        
        
        dispatch_async(dispatch_get_main_queue(),{
            if (self.driveDistanceToTransfer.isEmpty == false && self.flightDataToTransfer["price"]?.isEmpty == false)
            {
                [MBProgressHUD.hideHUDForView(self.view, animated: true)]
                [self.performSegueWithIdentifier("mySegue", sender: self)]
                self.goButtonItem.enabled = true;
                
            }
        });
    }
    
    func setupCarToolbars()
    {
        let carToolbar = UIToolbar();
        carToolbar.barStyle = .Default;
        carToolbar.sizeToFit();
        let doneButton = UIBarButtonItem(title: "Done", style: .Done, target: self, action: "handleCarToolbarDone:");
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil);
        carToolbar.setItems([spaceButton,doneButton], animated: false);
        carToolbar.userInteractionEnabled = true;
        departureDateField.inputAccessoryView = carToolbar;
        returnDateField.inputAccessoryView = carToolbar;
        selectCarField.inputAccessoryView = carToolbar;
        startLoc.inputAccessoryView = carToolbar;
        endLoc.inputAccessoryView = carToolbar;
    }
    
    func handleCarToolbarDone(sender: UIBarButtonItem){
        self.view.endEditing(true);
    }
    
    func handleNoDriveOption(){
        continueWithNoDrive = true;
    }
    
    func handleDatePick(sender: UIDatePicker)
    {
        var dateFormatter = NSDateFormatter();
        dateFormatter.dateFormat = "MM/dd/YYYY";
        let info = sender.description;
        let tag = sender.tag;
        if(sender.tag == 1)
        {
            departureDateField.text = "Departure Date: " + dateFormatter.stringFromDate(sender.date);
            departureDate = sender.date;
        }
        if(sender.tag == 2)
        {
            returnDateField.text = "Return Date: " + dateFormatter.stringFromDate(sender.date);
            returnDate = sender.date;
        }
    }
    
    func handleToolbarDone (sender: UIBarButtonItem)
    {
        departureDateField.resignFirstResponder();
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if(textField.tag == 3)
        {
            getLocButton.selected = false;
            startLoc.textColor = UIColor.blackColor();
        }
        return true;
    }
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if(textField.tag == 3 && textField.text == "Current Location")
        {
            return false;
        }
        return true;
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if(textField.tag == 1)
        {
            if(savedCars.isEmpty)
            {
                let alert = UIAlertController(title: "Oops", message: "It looks like you need to head over to the settings page and add some cars that you'd like to use in cost analysis.", preferredStyle: UIAlertControllerStyle.Alert);
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil));
                alert.addAction(UIAlertAction(title: "Take me there", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    self.performSegueWithIdentifier("settingSegue", sender: self);
                }))
                textField.resignFirstResponder();
                presentViewController(alert, animated: true, completion: nil);
                return false;
            }
            else
            {
                return true;
            }
        }
        else
        {
            return true;
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if(savedCars[row][0] == "Add a New Car")
        {
            return savedCars[row][0];
        }
        else
        {
            return "\(savedCars[row][0]) \(savedCars[row][1]) \(savedCars[row][2])";
        }
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(savedCars[row][0] == "Add a New Car")
        {
            let alert = UIAlertController(title: "Confirm", message: "Want to head over to the settings to add a new car?", preferredStyle: UIAlertControllerStyle.Alert);
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil));
            alert.addAction(UIAlertAction(title: "Take me there", style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                self.performSegueWithIdentifier("settingSegue", sender: self);
            }))
            selectCarField.resignFirstResponder();
            presentViewController(alert, animated: true, completion: nil);
        }
        else
        {
            
            selectedCarMPG = savedCars[row][4];
            selectCarField.text = "\(savedCars[row][0]) \(savedCars[row][1]) \(savedCars[row][2])";
            return;
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return savedCars.count;
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    
    override func viewWillAppear(animated: Bool) {
        let checkObj = userDefualts.objectForKey("savedCars");
        if(checkObj != nil)
        {
            savedCars = (userDefualts.objectForKey("savedCars") as? Array<Array<String>>)!;
            //add add more choice:
            var addMoreChoice = Array<String>();
            addMoreChoice.append("Add a New Car");
            savedCars.append(addMoreChoice);
            let pos = savedCars.count;
            if(pickerViewCars.selectedRowInComponent(0) == pos - 1)
            {
                pickerViewCars.selectRow(0, inComponent: 0, animated: false);
                pickerView(pickerViewCars, didSelectRow: 0, inComponent: 0);
            }
        }
        if(savedCars.isEmpty)
        {
            selectCarField.text = "";
        }
        
        
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?){
        if(segue.identifier == "mySegue")
        {
            let destViewController : ViewTwo = segue.destinationViewController as! ViewTwo;
            destViewController.driveDistanceText
                = driveDistanceToTransfer;
            destViewController.driveTimeText = driveTimeToTransfer;
            destViewController.flightPrice = flightDataToTransfer["price"]!;
            destViewController.flightDuration = flightDataToTransfer["duration"]!;
            destViewController.flightDistance = flightDataToTransfer["distance"]!;
            destViewController.driveCost = driveCostToTransfer;
            destViewController.startCord = CLLocationCoordinate2DMake(Double(startLat)!, Double(startLon)!);
            destViewController.endCord = CLLocationCoordinate2DMake(Double(endLat)!, Double(endLon)!);
            destViewController.polyline = self.polyline;
            destViewController.isRoundTrip = self.isRoundTrip;
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.canDisplayBannerAds = true;
        // Do any additional setup after loading the view, typically from a nib.
        userDefualts.registerDefaults([
            "driveHoursPerDay" : "24"
            ]);
        setupCarToolbars();
        selectCarField.tag = 1;
        selectCarField.delegate = self;
        dateViewPicker.tag = 1; //Tag represents departure date view picker.
        returnDateViewPicker.tag = 2; //Tag represents return date view picker.
        startLoc.tag = 3; //Tag represents startLocation text field.
        startLoc.delegate = self;
        
    
        
        var gasUrl = NSURL(string: "http://www.fueleconomy.gov/ws/rest/fuelprices");
        
        if let webData = NSData(contentsOfURL: gasUrl!){
            var error: NSError?
            do {
                let xmlDoc = try AEXMLDocument(xmlData: webData)
                gasPrice = xmlDoc.root["regular"].stringValue;
            } catch _ {
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true);
    }
    
}

