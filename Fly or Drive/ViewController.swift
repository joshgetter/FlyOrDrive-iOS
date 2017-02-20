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
import ReachabilitySwift
import UIKit
import Foundation
import CoreLocation
import QuartzCore
import GoogleMobileAds
import Firebase
import SwiftyJSON
class ViewController: UIViewController, XMLParserDelegate, UITextFieldDelegate, CLLocationManagerDelegate,UIPickerViewDelegate, UIPickerViewDataSource {
    var locManager = CLLocationManager()
    @IBOutlet weak var goButtonItem: UIBarButtonItem!
    @IBOutlet weak var startLoc: UITextField!
    @IBOutlet weak var endLoc: UITextField!
    @IBOutlet weak var selectCarField: UITextField!
    @IBOutlet weak var getLocButton: UIButton!
    @IBOutlet weak var departureDateField: UITextField!
    @IBOutlet weak var numPassengerField: UITextField!
    @IBOutlet weak var returnDateField: UITextField!
    @IBOutlet weak var adBanner: GADBannerView!
    
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
    var userDefualts = UserDefaults.standard;
    var departureDate = Date();
    var returnDate = Date();
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
    
    
    @IBAction func numPassengersIncrement(_ sender: UIStepper) {
        numPassengers = Int(sender.value);
        numPassengerField.text = String(numPassengers);
    }
    
    @IBAction func editingDepartureDateField(_ sender: AnyObject) {
        let currDate = Date();
        let calendar = Calendar.current
        let oneYear = calendar.date(byAdding: .year, value: 1, to: currDate)
        let components = DateComponents();
        let info = sender.description;
        let tag = sender.tag;
        (components as NSDateComponents).setValue(1, forComponent: NSCalendar.Unit.year);
        //let oneYear = currDate.addingTimeInterval(TimeInterval(du)
        
        if(sender.tag == 1)//Tag represents departure field
        {
        dateViewPicker.datePickerMode = UIDatePickerMode.date;
        dateViewPicker.minimumDate = currDate;
        dateViewPicker.maximumDate = oneYear;
        departureDateField.inputView = dateViewPicker;
        dateViewPicker.addTarget(self, action: #selector(ViewController.handleDatePick(_:)), for: UIControlEvents.valueChanged);
        //handleDatePick(dateViewPicker);
        //let tempDate = dateViewPicker.date;
        }
        if(sender.tag == 2)//Tag represents return field
        {
            returnDateViewPicker.datePickerMode = UIDatePickerMode.date;
            returnDateViewPicker.minimumDate = departureDate;
            returnDateViewPicker.maximumDate = oneYear;
            returnDateField.inputView = returnDateViewPicker;
            returnDateViewPicker.addTarget(self, action: #selector(ViewController.handleDatePick(_:)), for: UIControlEvents.valueChanged);
            //handleDatePick(returnDateViewPicker);
        }
        
    }
    
    @IBAction func getLocatoinPressed(_ sender: AnyObject) {
        locManager.delegate = self
        locManager.requestWhenInUseAuthorization()
        locManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        locManager.startUpdatingLocation();
        if( CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways)
        {
            
            if(getLocButton.isSelected == false)
            {
                getLocButton.isSelected = true;
                startLoc.text = "Current Location";
                startLoc.textColor = UIColor.blue;
                
                gpsLat = (locManager.location?.coordinate.latitude)!;
                gpsLon = (locManager.location?.coordinate.longitude)!;
                if(gpsLat == 0 && gpsLon == 0)
                {
                    self.getLocButton.isSelected = false;
                    self.present(simpleAlert("Oops", Message: "The current location was not found, try entering your location manually."), animated: true, completion: nil);
                }
            }
            else
            {
                getLocButton.isSelected = false;
                startLoc.text = "";
                startLoc.textColor = UIColor.black;
            }
            
        }
        
        
    }
    
    @IBAction func editingCarSelection(_ sender: AnyObject) {
        pickerViewCars.dataSource = self;
        pickerViewCars.delegate = self;
        selectCarField.inputView = pickerViewCars;
        let selectedRow = pickerViewCars.selectedRow(inComponent: 0);
        if(selectedRow == 0)
        {
            pickerViewCars.selectRow(0, inComponent: 0, animated: false);
            pickerView(pickerViewCars, didSelectRow: 0, inComponent: 0);
        }
    }
    
    @IBAction func goButton(_ sender: AnyObject) {
        if(Reachability.init()?.isReachable == false)
        {
            self.present(simpleAlert("Info", Message: "There seems to be a network issue, make sure airplane mode is off and that the device has a network connection."), animated: true, completion: nil);
            return;
        }
        if(startLoc.text?.isEmpty == true || endLoc.text?.isEmpty == true || departureDateField.text?.isEmpty == true || selectCarField.text?.isEmpty == true)
        {
            present(simpleAlert("Oops", Message: "Please make sure the required fields are not blank"), animated: true, completion: nil)
            return;
        }
        if(returnDateField.text?.isEmpty == false)
        {
            if(returnDate.timeIntervalSince(departureDate) < 0)//Return date must be after departure date.
            {
                self.present(simpleAlert("Oops", Message: "Make sure the return date is after the departure date."), animated: true, completion: nil);
                return;
                //Stop spinner.
            }
        }
        
        goButtonItem.isEnabled = false;
        [MBProgressHUD.showAdded(to: self.view, animated: true)];
        let backgroundThread = DispatchQueue.global(qos: .background);
        backgroundThread.async { () -> Void in
            var startLocText = String();
            if(self.gpsLat != 0 && self.gpsLon != 0 && self.getLocButton.isSelected == true)//Use GPS coordinate or calculate it.
            {
                startLocText = String(self.gpsLat) + "," + String(self.gpsLon);
            }
            else
            {
                startLocText = self.startLoc.text!;
            }
            let endLocText = self.endLoc.text;
            let gDirectionsUrlString = "http://maps.googleapis.com/maps/api/directions/json?origin=" + startLocText + "&destination=" + endLocText!;
            let gDirectionsUrlFormatted = gDirectionsUrlString.replacingOccurrences(of: " ", with: "%20")
            let gDirectionsUrl = URL(string: gDirectionsUrlFormatted);
            
            if let webData = try? Data(contentsOf: gDirectionsUrl!){
                var error: NSError?
                let json = JSON(data: webData)
                let status = json["status"].stringValue;
                if(status != "OK") //Something wrong about drive directions
                {
                    DispatchQueue.main.async(execute: { () -> Void in
                        [MBProgressHUD.hide(for: self.view, animated: true)]
                        if(status == "ZERO_RESULTS")//Not possible to drive
                        {

                            let alert = simpleAlert("Oops", Message: "It looks like there is no way to drive there... yet");
                            alert.addAction(UIAlertAction(title: "Show Flight", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                                [MBProgressHUD.showAdded(to: self.view, animated: true)];
                                backgroundThread.async(execute: { () -> Void in
                                    self.continueWithNoDrive = true;
                                self.flightDriveCalculation(false, json: json);
                                })
                    
                            }))
                            self.present(alert, animated: true, completion: nil);
                            if(self.continueWithNoDrive != true) //User chose not to continue with flight cost.
                            {
                                self.goButtonItem.isEnabled = true;
                                return;
                            }
                            
                        }
                        else //Any other error
                        {
                            self.present(simpleAlert("Oops", Message: "It looks like something is wrong right now, try changing your input or trying again later"), animated: true, completion: nil);
                            self.goButtonItem.isEnabled = true;
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
    func flightDriveCalculation(_ flightAndDrive : Bool, json: JSON)
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
            let stopCost = (ceil(driveTimeValue / (Float(self.userDefualts.integer(forKey: "driveHoursPerDay"))))-1) * (Float(self.hotelCostPerNight));
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
            let reverseGeocodeURLStart = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?place_id=\(startPlaceID)&key=AIzaSyCBbrKUVoZId8GB_7m1k_tIatUQBQ63k_I");
            let reverseGeocodeURLEnd = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?place_id=\(endPlaceID)&key=AIzaSyCBbrKUVoZId8GB_7m1k_tIatUQBQ63k_I");
            
            if(gpsLat != 0 && gpsLon != 0 && getLocButton.isSelected == true)
            {
                startLat = String(gpsLat);
                startLon = String(gpsLon);
            }
            else
            {
                if let startLocWebData = try? Data(contentsOf: reverseGeocodeURLStart!){
                    let startLocJson = JSON(data: startLocWebData);
                    startLat = startLocJson["results",0,"geometry","location","lat"].stringValue;
                    startLon = startLocJson["results",0,"geometry","location","lng"].stringValue;
                    
                }
            }
            if let endLocWebData = try? Data(contentsOf: reverseGeocodeURLEnd!){
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
            DispatchQueue.main.async(execute: { () -> Void in
                [MBProgressHUD.hide(for: self.view, animated: true)]
                self.present(simpleAlert("Oops", Message: self.flightDataToTransfer["errors"]!), animated: true, completion: nil);
                self.goButtonItem.isEnabled = true;
                return;
            })
        }
        if(self.flightDataToTransfer["price"]?.isEmpty == true)//Checks if flights are available
        {
            DispatchQueue.main.async(execute: {
                [MBProgressHUD.hide(for: self.view, animated: true)]
                self.present(simpleAlert("Oops", Message: "It looks like there are no flights available for that day or location, try a different date or location"), animated: true, completion: nil);
                self.goButtonItem.isEnabled = true;
                return;
            });
        }
        
        
        DispatchQueue.main.async(execute: {
            if (self.driveDistanceToTransfer.isEmpty == false && self.flightDataToTransfer["price"]?.isEmpty == false)
            {
                [MBProgressHUD.hide(for: self.view, animated: true)]
                [self.performSegue(withIdentifier: "mySegue", sender: self)]
                self.goButtonItem.isEnabled = true;
                
            }
        });
    }
    
    func setupCarToolbars()
    {
        let carToolbar = UIToolbar();
        carToolbar.barStyle = .default;
        carToolbar.sizeToFit();
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(ViewController.handleCarToolbarDone(_:)));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        carToolbar.setItems([spaceButton,doneButton], animated: false);
        carToolbar.isUserInteractionEnabled = true;
        departureDateField.inputAccessoryView = carToolbar;
        returnDateField.inputAccessoryView = carToolbar;
        selectCarField.inputAccessoryView = carToolbar;
        startLoc.inputAccessoryView = carToolbar;
        endLoc.inputAccessoryView = carToolbar;
    }
    
    func handleCarToolbarDone(_ sender: UIBarButtonItem){
        self.view.endEditing(true);
    }
    
    func handleNoDriveOption(){
        continueWithNoDrive = true;
    }
    
    func handleDatePick(_ sender: UIDatePicker)
    {
        let dateFormatter = DateFormatter();
        dateFormatter.dateFormat = "MM/dd/YYYY";
        let info = sender.description;
        let tag = sender.tag;
        if(sender.tag == 1)
        {
            departureDateField.text = "Departure Date: " + dateFormatter.string(from: sender.date);
            departureDate = sender.date;
        }
        if(sender.tag == 2)
        {
            returnDateField.text = "Return Date: " + dateFormatter.string(from: sender.date);
            returnDate = sender.date;
        }
    }
    
    func handleToolbarDone (_ sender: UIBarButtonItem)
    {
        departureDateField.resignFirstResponder();
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if(textField.tag == 3)
        {
            getLocButton.isSelected = false;
            startLoc.textColor = UIColor.black;
        }
        return true;
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if(textField.tag == 3 && textField.text == "Current Location")
        {
            return false;
        }
        return true;
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if(textField.tag == 1)
        {
            if(savedCars.isEmpty)
            {
                let alert = UIAlertController(title: "Oops", message: "It looks like you need to head over to the settings page and add some cars that you'd like to use in cost analysis.", preferredStyle: UIAlertControllerStyle.alert);
                alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil));
                alert.addAction(UIAlertAction(title: "Take me there", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                    self.performSegue(withIdentifier: "settingSegue", sender: self);
                }))
                textField.resignFirstResponder();
                present(alert, animated: true, completion: nil);
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
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
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
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(savedCars[row][0] == "Add a New Car")
        {
            let alert = UIAlertController(title: "Confirm", message: "Want to head over to the settings to add a new car?", preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler: nil));
            alert.addAction(UIAlertAction(title: "Take me there", style: UIAlertActionStyle.default, handler: { (UIAlertAction) -> Void in
                self.performSegue(withIdentifier: "settingSegue", sender: self);
            }))
            selectCarField.resignFirstResponder();
            present(alert, animated: true, completion: nil);
        }
        else
        {
            
            selectedCarMPG = savedCars[row][4];
            selectCarField.text = "\(savedCars[row][0]) \(savedCars[row][1]) \(savedCars[row][2])";
            return;
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return savedCars.count;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        let checkObj = userDefualts.object(forKey: "savedCars");
        if(checkObj != nil)
        {
            savedCars = (userDefualts.object(forKey: "savedCars") as? Array<Array<String>>)!;
            //add add more choice:
            var addMoreChoice = Array<String>();
            addMoreChoice.append("Add a New Car");
            savedCars.append(addMoreChoice);
            let pos = savedCars.count;
            if(pickerViewCars.selectedRow(inComponent: 0) == pos - 1)
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
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if(segue.identifier == "mySegue")
        {
            let destViewController : ViewTwo = segue.destination as! ViewTwo;
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
        //CHANGE BACKGROUND BELOW
        //let backgroundView = UIImageView(frame: UIScreen.mainScreen().bounds)
        //backgroundView.image = UIImage(named: "sky.jpeg");
        //self.view.insertSubview(backgroundView, atIndex: 0);
        //ADS
        adBanner.adUnitID = "ca-app-pub-4082194909024613/8447440283";
        adBanner.rootViewController = self;
        adBanner.load(GADRequest());
        
        // Do any additional setup after loading the view, typically from a nib.
        userDefualts.register(defaults: [
            "driveHoursPerDay" : "24"
            ]);
        setupCarToolbars();
        selectCarField.tag = 1;
        selectCarField.delegate = self;
        dateViewPicker.tag = 1; //Tag represents departure date view picker.
        returnDateViewPicker.tag = 2; //Tag represents return date view picker.
        startLoc.tag = 3; //Tag represents startLocation text field.
        startLoc.delegate = self;
        
    
        
        var gasUrl = URL(string: "http://www.fueleconomy.gov/ws/rest/fuelprices");
        
        if let webData = try? Data(contentsOf: gasUrl!){
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true);
    }
    
}

