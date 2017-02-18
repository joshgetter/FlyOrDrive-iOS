//
//  Settings.swift
//  Fly or Drive
//
//  Created by Josh Getter on 12/24/15.
//  Copyright © 2015 Josh Getter. All rights reserved.
//

import Foundation
import UIKit


var carMPG = String();

class Settings: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate{
    var settings = UserDefaults.standard;
    var savedCars = Array<Array<String>>();
    @IBOutlet weak var saveCarButton: UIButton!
    @IBOutlet weak var drivingHoursLabel: UILabel!
    @IBOutlet weak var drivingHoursSlider: UISlider!
    
    var pickerView = UIPickerView();
    var pickerViewMake = UIPickerView();
    var pickerViewModel = UIPickerView();
    var pickerViewOptions = UIPickerView();
    
    var carYears = [String]();
    var carMakes = [String]();
    var carModels = [String]();
    var carOptions = [String]();
    
    var selectedCarYear = String();
    var selectedCarMake = String();
    var selectedCarModel = String();
    var selectedCarOptions = String();
    var selectedCarMPG = String();
    
    var yearUrl = URL(string: "http://www.fueleconomy.gov/ws/rest/vehicle/menu/year");

    @IBOutlet weak var carMakeTextField: UITextField!
    @IBOutlet weak var carYearTextField: UITextField!
    @IBOutlet weak var carModelTextField: UITextField!
    @IBOutlet weak var carOptionsTextField: UITextField!
    @IBAction func carYearEditing(_ sender: AnyObject) {
        pickerView.delegate = self;
        pickerView.dataSource = self;
        carYearTextField.inputView = self.pickerView;
        /*selectedCarYear = carYears[0];
        carYearTextField.text = "Car Year: " + selectedCarYear;*/
        if(pickerView.selectedRow(inComponent: 0) == 0)
        {
        pickerView.selectRow(0, inComponent: 0, animated: true);
        self.pickerView(pickerView, didSelectRow: 0, inComponent: 0);
        }
    }
    
    @IBAction func carMakeEditing(_ sender: AnyObject) {
        pickerViewMake.delegate = self;
        pickerViewMake.dataSource = self;
        carMakeTextField.inputView = self.pickerViewMake;
        if(pickerViewMake.selectedRow(inComponent: 0) == 0)
        {
            pickerViewMake.selectRow(0, inComponent: 0, animated: true);
            self.pickerView(pickerViewMake, didSelectRow: 0, inComponent: 0);
        }
    }
    
    @IBAction func carModelEditing(_ sender: AnyObject) {
        pickerViewModel.delegate = self;
        pickerViewModel.dataSource = self;
        carModelTextField.inputView = self.pickerViewModel;
        if(pickerViewModel.selectedRow(inComponent: 0) == 0)
        {
            pickerViewModel.selectRow(0, inComponent: 0, animated: false);
            self.pickerView(pickerViewModel, didSelectRow: 0, inComponent: 0);
        }
    }
    @IBAction func carOptionsEditing(_ sender: AnyObject) {
        pickerViewOptions.delegate = self;
        pickerViewOptions.dataSource = self;
        carOptionsTextField.inputView = self.pickerViewOptions;
        if(pickerViewOptions.selectedRow(inComponent: 0) == 0)
        {
            pickerViewOptions.selectRow(0, inComponent: 0, animated: false);
            self.pickerView(pickerViewOptions, didSelectRow: 0, inComponent: 0);
        }
    }
    @IBAction func finishedEditingYear(_ sender: AnyObject) {
       if(selectedCarYear.isEmpty == false)
       {
        carMakeTextField.isUserInteractionEnabled = true;
        carMakeTextField.text = "Car Make:";
        }
        else
       {
        carMakeTextField.isUserInteractionEnabled = false;
        carMakeTextField.placeholder = "Select a Car Year First";
        
        }
    }
    @IBAction func finishedEditingMake(_ sender: AnyObject) {
        if(selectedCarMake.isEmpty == false)
        {
            carModelTextField.isUserInteractionEnabled = true;
            carModelTextField.text = "Car Model:";
        }
        else
        {
            carModelTextField.isUserInteractionEnabled = false;
            carModelTextField.placeholder = "Select a Car Model First";
        }
    }
    @IBAction func finishedEditingModel(_ sender: AnyObject) {
    if(selectedCarModel.isEmpty == false)
        {
            carOptionsTextField.isUserInteractionEnabled = true;
            carOptionsTextField.text = "Car Options:";
        }
        else
        {
            carOptionsTextField.isUserInteractionEnabled = false;
            carOptionsTextField.placeholder = "Select a Car Option First";
        }
    }
    func setupCarToolbars()
    {
        let carToolbar = UIToolbar();
        carToolbar.barStyle = .default;
       
        carToolbar.sizeToFit();
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(Settings.handleCarToolbarDone(_:)));
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil);
        carToolbar.setItems([spaceButton,doneButton], animated: false);
        carToolbar.isUserInteractionEnabled = true;
        carYearTextField.inputAccessoryView = carToolbar;
        carMakeTextField.inputAccessoryView = carToolbar;
        carModelTextField.inputAccessoryView = carToolbar;
        carOptionsTextField.inputAccessoryView = carToolbar;
    }
    func handleCarToolbarDone(_ sender: UIBarButtonItem){
        self.view.endEditing(true);
    }
    
    @IBAction func saveCarButtonPressed(_ sender: AnyObject) {
        let temp = carOptionsTextField.text;
        if(carOptionsTextField.text?.isEmpty == false && selectedCarMPG.isEmpty == false && carOptionsTextField.text != "Car Options:") //Checks that submission is valid
        {
        var tempArray = Array<String>();
        tempArray.append(selectedCarYear);
        tempArray.append(selectedCarMake);
        tempArray.append(selectedCarModel);
        tempArray.append(selectedCarOptions);
        tempArray.append(selectedCarMPG);
        if(!savedCars.contains(where: {$0 == tempArray})) //Checks if this car is saved already.
        {
            if(savedCars.count <= 5)
            {
            savedCars.append(tempArray);
            settings.set(savedCars, forKey: "savedCars");
            self.present(simpleAlert("Info", Message: "Car Saved!"), animated: true, completion: nil);
    
            }
            else
            {
                self.present(simpleAlert("Info", Message: "Maximum number of saved cars has been reached."), animated: true, completion: nil);
            }
        }
        else
        {
            self.present(simpleAlert("Info", Message: "This car is already saved."), animated: true, completion: nil);
        }
        }
        else
        {
            self.present(simpleAlert("Info", Message: "Please make sure all car fields are completed."), animated: true, completion: nil);
        }

    }
        @IBAction func clearCarsButton(_ sender: AnyObject) {
        savedCars.removeAll();
        settings.set(savedCars, forKey: "savedCars");
        }
    func loadDefaults(){
        let drivingHoursPerDay = settings.integer(forKey: "driveHoursPerDay");
        if(settings.object(forKey: "savedCars") != nil)
        {
            savedCars = settings.object(forKey: "savedCars") as! Array<Array<String>>;
        }
        drivingHoursSlider.value = Float(drivingHoursPerDay);
        drivingHoursLabel.text = "Driving hours per day: " + String(drivingHoursPerDay);
    }
    @IBAction func drivingHoursChange(_ sender: AnyObject) {
        let sliderValInt = (Int(drivingHoursSlider.value));
        drivingHoursLabel.text = "Driving hours per day: " + String(sliderValInt);
        drivingHoursSlider.value = Float(sliderValInt);
    }
    override func viewWillDisappear(_ animated: Bool) {
        settings.set(Int(drivingHoursSlider.value), forKey: "driveHoursPerDay");
        
    }
    override func viewDidLoad() {
        loadDefaults();
        setupCarToolbars();
        carMakeTextField.isUserInteractionEnabled = false;
        carModelTextField.isUserInteractionEnabled = false;
        carOptionsTextField.isUserInteractionEnabled = false;
        carYearTextField.text = "Car Year:";
        carMakeTextField.placeholder = "Select a Car Year First";
        carModelTextField.placeholder = "Select a Car Make First";
        carOptionsTextField.placeholder = "Select a Car Model First";
        
        pickerView.tag = 1;
        pickerViewMake.tag = 2;
        pickerViewModel.tag = 3;
        pickerViewOptions.tag = 4;
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async { () -> Void in
            if let webData = try? Data(contentsOf: self.yearUrl!){
                do {
                    let xmlDoc = try AEXMLDocument(xmlData: webData)
                    for child1 in xmlDoc.root.children{
                        let currString = child1["text"].stringValue;
                        self.carYears.append(currString);
                    }
                } catch _ {
                }
            }
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if(pickerView.tag == 1)
        {
            return carYears[row];
        }
        if(pickerView.tag == 2)
        {
            return carMakes[row];
        }
        if(pickerView.tag == 3)
        {
            return carModels[row];
        }
        if(pickerView.tag == 4)
        {
            return carOptions[row];
        }
        return carYears[row];
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            if(pickerView.tag == 1){
                self.selectedCarYear = self.carYears[row];
                self.carYearTextField.text = "Car Year: " + self.selectedCarYear;
                self.carMakes.removeAll();
                let makeUrl = URL(string: "http://www.fueleconomy.gov/ws/rest/vehicle/menu/make?year=\(self.selectedCarYear)");
                
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async(execute: { () -> Void in
                    if let webData = try? Data(contentsOf: makeUrl!){
                        var error: NSError?
                        do {
                            let xmlDoc = try AEXMLDocument(xmlData: webData)
                            for child2 in xmlDoc.root.children{
                                let currString = child2["text"].stringValue;
                                self.carMakes.append(currString);
                            }
                        } catch _ {
                        }
                    }
                })
                
                self.carMakeTextField.text = nil;
                self.carMakeTextField.isUserInteractionEnabled = false;
                self.selectedCarMake = "";
                self.pickerViewMake.selectRow(0, inComponent: 0, animated: true);
                self.carModels.removeAll();
                self.carModelTextField.text = nil;
                self.carModelTextField.isUserInteractionEnabled = false;
                self.selectedCarModel = "";
                self.pickerViewModel.selectRow(0, inComponent: 0, animated: true);
                self.pickerViewModel.reloadAllComponents();
                self.selectedCarOptions = "";
                self.carOptionsTextField.text = nil;
                self.carOptionsTextField.isUserInteractionEnabled = false;
                self.carOptions.removeAll();
            }
            if(pickerView.tag == 2){
                self.selectedCarMake = self.carMakes[row];
                self.carMakeTextField.text = "Car Make: " + self.selectedCarMake;
                self.carModels.removeAll();
                let unformattedUrl = "http://www.fueleconomy.gov/ws/rest/vehicle/menu/model?year=\(self.selectedCarYear)&make=\(self.selectedCarMake)";
                let formattedUrl = unformattedUrl.replacingOccurrences(of: " ", with: "%20");
                let modelUrl = URL(string: formattedUrl);
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async(execute: { () -> Void in
                    if let webData = try? Data(contentsOf: modelUrl!){
                        var error: NSError?
                        do {
                            let xmlDoc = try AEXMLDocument(xmlData: webData)
                            for child3 in xmlDoc.root.children{
                                let currString = child3["text"].stringValue;
                                self.carModels.append(currString);
                            }
                        } catch _ {
                        }
                    }
                })
                
                self.selectedCarModel = "";
                self.selectedCarOptions = "";
                self.carModelTextField.text = nil;
                self.carOptionsTextField.text = nil;
                self.carModelTextField.isUserInteractionEnabled = false;
                self.carOptionsTextField.isUserInteractionEnabled = false;
                self.carOptions.removeAll();
                self.pickerViewModel.selectRow(0, inComponent: 0, animated: true);
                self.pickerViewOptions.selectRow(0, inComponent: 0, animated: true);
            }
            if(pickerView.tag == 3){
                self.selectedCarModel = self.carModels[row];
                self.carModelTextField.text = "Car Model: " + self.selectedCarModel;
                self.carOptions.removeAll();
                let unformattedUrl = "http://www.fueleconomy.gov/ws/rest/vehicle/menu/options?year=\(self.selectedCarYear)&make=\(self.selectedCarMake)&model=\(self.selectedCarModel)";
                let formattedUrl = unformattedUrl.replacingOccurrences(of: " ", with: "%20");
                let optionsUrl = URL(string: formattedUrl);
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async(execute: { () -> Void in
                    if let webData = try? Data(contentsOf: optionsUrl!){
                        var error: NSError?
                        do {
                            let xmlDoc = try AEXMLDocument(xmlData: webData)
                            for child4 in xmlDoc.root.children{
                                let currString = child4["text"].stringValue;
                                self.carOptions.append(currString);
                            }
                        } catch _ {
                        }
                    }
                })
                self.selectedCarOptions = "";
                self.carOptionsTextField.text = nil;
                self.carOptionsTextField.isUserInteractionEnabled = false;
                
            }
            if(pickerView.tag == 4){
                var vehicleId = String();
                self.selectedCarOptions = self.carOptions[row];
                self.carOptionsTextField.text = "Car Options: " + self.selectedCarOptions;
                let unformattedUrl = "http://www.fueleconomy.gov/ws/rest/vehicle/menu/options?year=\(self.selectedCarYear)&make=\(self.selectedCarMake)&model=\(self.selectedCarModel)";
                let formattedUrl = unformattedUrl.replacingOccurrences(of: " ", with: "%20");
                let optionsUrl = URL(string: formattedUrl);
                DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.low).async(execute: { () -> Void in
                    if let webData = try? Data(contentsOf: optionsUrl!){
                        var error: NSError?
                        do {
                            let xmlDoc = try AEXMLDocument(xmlData: webData)
                            
                            vehicleId = xmlDoc.root.children[row]["value"].stringValue;
                            
                        } catch _ {
                        }
                    }
                    let mpgString = "http://www.fueleconomy.gov/ws/rest/vehicle/\(vehicleId)";
                    let mpgUrl = URL(string: mpgString);
                    if let webData2 = try? Data(contentsOf: mpgUrl!){
                        var error: NSError?
                        do {
                            let xmlDoc = try AEXMLDocument(xmlData: webData2)
                            self.selectedCarMPG = xmlDoc.root["comb08"].stringValue;
                        } catch _ {
                        }
                    }
                    
                })
            }
            
        
        
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView.tag == 1)
        {
            return carYears.count;
        }
        if(pickerView.tag == 2){
            return carMakes.count;
        }
        if(pickerView.tag == 3){
            return carModels.count;
        }
        if(pickerView.tag == 4){
            return carOptions.count;
        }
        return carYears.count;
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return false;
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destViewController : ViewController = segue.destination as! ViewController;
        destViewController.savedCars = savedCars;
    }
    
    
}
