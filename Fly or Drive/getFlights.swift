//
//  getFlights.swift
//  Fly or Drive
//
//  Created by Josh Getter on 12/16/15.
//  Copyright © 2015 Josh Getter. All rights reserved.
//

import Foundation
import CoreLocation
func getAirports(startLat: String, startLon: String, endLat:String, endLon:String, departureDate:NSDate, returnDate:NSDate?, numberOfPassengers: Int)->[String:String]
{
    var startAirports = [(Int,String)]();
    var endAirports = [(Int,String)]();
    var startAirportsUrl = NSURL(string: "http://terminal2.expedia.com/x/geo/features?within=100km&lat=" + startLat + "&lng=" + startLon + "&type=airport&verbose=3&apikey=tz2rt1BRBxDZVt6nvIRuoYnorN211ogo")!;
    var endAirportsUrl = NSURL(string: "http://terminal2.expedia.com/x/geo/features?within=100km&lat=" + endLat + "&lng=" + endLon + "&type=airport&verbose=3&apikey=tz2rt1BRBxDZVt6nvIRuoYnorN211ogo")!;
    
    if let startAirportWebData = NSData(contentsOfURL: startAirportsUrl){
        let startAirportJson = JSON(data:startAirportWebData);
        
        for (index,subJson):(String, JSON) in startAirportJson
        {
            var isMajor : Int?;
            isMajor = subJson["tags","common","majorAirport","value"].intValue;
            if(isMajor == 1)
            {
                let tempString = subJson["tags","iata","airportCode","value"].stringValue;
                if(tempString.isEmpty == false)
                {
                    let tempInt = subJson["tags","score","visits","value"].intValue;
                    let tempTuple = (tempInt,tempString);
                    startAirports.append(tempTuple);
                }
                
            }
            
        }
        
        
    }
    
    if let endAirportWebData = NSData(contentsOfURL: endAirportsUrl){
        let endAirportJson = JSON(data:endAirportWebData);
        
        for (index,subJson):(String, JSON) in endAirportJson
        {
            var isMajor : Int?;
            isMajor = subJson["tags","common","majorAirport","value"].intValue;
            if(isMajor == 1)
            {
                let tempString = subJson["tags","iata","airportCode","value"].stringValue;
                if(tempString.isEmpty == false)
                {
                    let tempInt = subJson["tags","score","visits","value"].intValue;
                    let tempTuple = (tempInt,tempString);
                    endAirports.append(tempTuple);
                }
                
            }
            
        }
        
        
    }
    startAirports.sortInPlace { (lhs: (Int,String), rhs:(Int,String)) -> Bool in
        return lhs.0 > rhs.0;
    };
    endAirports.sortInPlace { (lhs:(Int,String), rhs:(Int,String)) -> Bool in
        return lhs.0 > rhs.0;
    }
    let returnPrice = getFlightData(startAirports, endAirports: endAirports, departureDate: departureDate, returnDate: returnDate, numberOfPassengers: numberOfPassengers);
    if(returnPrice.0 == "no airport" && returnPrice.1 == "no airport")
    {
        return ["errors": "No airports were found there, please try a more specific or different location."];
    }
    let distance = findStraigthDistance(startLat, startLon: startLon, endLat: endLat, endLon: endLon);
    var priceDistanceDuration = (returnPrice.0,returnPrice.1,distance);
    var FlightDictionary:[String:String] =
    [
        "price" : returnPrice.0,
        "duration" : returnPrice.1,
        "distance" : distance
    ];

    return FlightDictionary;
    //Returns (flightPrice, FLightDuration, FlightDistance)
}



func getFlightData(startAirports:[(Int,String)], endAirports:[(Int,String)], departureDate:NSDate, returnDate:NSDate?, numberOfPassengers: Int)->(String,String){
    
    var dateFormatter = NSDateFormatter();
    dateFormatter.dateFormat = "yyyy-MM-dd";
    var flightDuration:Int = 0;
    var flightPrice:String="";
    var totalDuration:String="";
    let headers = [
        "content-type": "application/json",
        "cache-control": "no-cache",
    ]
    var parameters:NSDictionary;
    if(endAirports.isEmpty == true || startAirports.isEmpty == true)
    {
        return ("no airport", "no airport");
    }
    if(returnDate == nil)
    {
        parameters = ["request": [
            "passengers": ["adultCount": "\(numberOfPassengers)"],
            "slice": [
                [
                    "origin": "\(startAirports[0].1)",
                    "destination": "\(endAirports[0].1)",
                    "date": "\(dateFormatter.stringFromDate(departureDate))" //yyyy-mm-dd
                ]
            ],
            "solutions": "1",
            "saleCountry": "US"
            ]]
    }
    else
    {
        parameters = ["request": [
            "passengers": ["adultCount": "\(numberOfPassengers)"],
            "slice": [
                [
                    "origin": "\(startAirports[0].1)",
                    "destination": "\(endAirports[0].1)",
                    "date": "\(dateFormatter.stringFromDate(departureDate))"
                ],
                [
                    "origin": "\(endAirports[0].1)",
                    "destination": "\(startAirports[0].1)",
                    "date": "\(dateFormatter.stringFromDate(returnDate!))"
                ]
            ],
            "solutions": "1",
            "saleCountry": "US"
            ]]
    }
    
    
    let request = NSMutableURLRequest(URL: NSURL(string: "https://www.googleapis.com/qpxExpress/v1/trips/search?key=AIzaSyCBbrKUVoZId8GB_7m1k_tIatUQBQ63k_I")!)
    let session = NSURLSession.sharedSession()
    request.HTTPMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(parameters, options: [])
    
    var response : NSURLResponse?
    var responseData: NSData;
    do
    {
        responseData =  try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response);
        
        let temp = response as? NSHTTPURLResponse
        let tempJson = temp as? NSData;
        let json = try NSJSONSerialization.JSONObjectWithData(responseData, options: [])
        let finalJson = JSON(json)
        flightPrice = finalJson["trips","tripOption",0,"saleTotal"].stringValue;
        flightDuration = finalJson["trips","tripOption",0,"slice",0,"duration"].intValue;
        var totalMinutes:Int = flightDuration % 60;
        var totalHours:Int = flightDuration/60;
        totalDuration = "Flight Duration: " + String(totalHours) + " hours " + String(totalMinutes) + " minutes";
        //var subJson = finalJson["trips","tripOption",0,]
        let copyOfPrice = flightPrice;
    }
    catch let parseError
    {
        print(parseError);
    }
        if(flightPrice.isEmpty == false)
        {
        return (flightPrice,totalDuration);
        }
    

    return (flightPrice,totalDuration);
}

func findStraigthDistance(startLat: String, startLon: String, endLat:String, endLon: String)->String
{
    var startLatDouble = Double(startLat);
    var startLonDouble = Double(startLon);
    var endLatDouble = Double(endLat);
    var endLonDouble = Double(endLon);
    let startLoc = CLLocation(latitude: startLatDouble!, longitude: startLonDouble!);
    let endLoc = CLLocation(latitude: endLatDouble!, longitude: endLonDouble!);
    
    var distanceMeters = startLoc.distanceFromLocation(endLoc);
    var distanceMiles = distanceMeters * 0.000621371;
    var returnMiles = String(Int(distanceMiles)) + " miles";
    return returnMiles;
}





