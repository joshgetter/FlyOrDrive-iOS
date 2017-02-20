//
//  getFlights.swift
//  Fly or Drive
//
//  Created by Josh Getter on 12/16/15.
//  Copyright © 2015 Josh Getter. All rights reserved.
//
import SwiftyJSON
import Foundation
import CoreLocation
func getAirports(_ startLat: String, startLon: String, endLat:String, endLon:String, departureDate:Date, returnDate:Date?, numberOfPassengers: Int)->[String:String]
{
    let airports = AirportAPI.GetAirports(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon)
    
    let returnPrice = getFlightData(startAirports: airports!.origin, endAirports: airports!.dest, departureDate: departureDate, returnDate: returnDate, numberOfPassengers: numberOfPassengers);
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



func getFlightData(startAirports:[String], endAirports:[String], departureDate:Date, returnDate:Date?, numberOfPassengers: Int)->(String,String){
    
    var dateFormatter = DateFormatter();
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
                    "origin": startAirports[0],
                    "destination": endAirports[0],
                    "date": "\(dateFormatter.string(from: departureDate))" //yyyy-mm-dd
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
                    "origin": startAirports[0],
                    "destination": endAirports[0],
                    "date": "\(dateFormatter.string(from: departureDate))"
                ],
                [
                    "origin": endAirports[0],
                    "destination": startAirports[0],
                    "date": "\(dateFormatter.string(from: returnDate!))"
                ]
            ],
            "solutions": "1",
            "saleCountry": "US"
            ]]
    }
    
    
    let request = NSMutableURLRequest(url: URL(string: "https://www.googleapis.com/qpxExpress/v1/trips/search?key=AIzaSyCBbrKUVoZId8GB_7m1k_tIatUQBQ63k_I")!)
    let session = URLSession.shared
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
    
    var response : URLResponse?
    var responseData: Data;
    do
    {
        responseData =  try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response);
        
        let temp = response as? HTTPURLResponse
        let tempJson = temp as? Data;
        let json = try JSONSerialization.jsonObject(with: responseData, options: [])
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

func findStraigthDistance(_ startLat: String, startLon: String, endLat:String, endLon: String)->String
{
    let startLatDouble = Double(startLat);
    let startLonDouble = Double(startLon);
    let endLatDouble = Double(endLat);
    let endLonDouble = Double(endLon);
    let startLoc = CLLocation(latitude: startLatDouble!, longitude: startLonDouble!);
    let endLoc = CLLocation(latitude: endLatDouble!, longitude: endLonDouble!);
    
    let distanceMeters = startLoc.distance(from: endLoc);
    let distanceMiles = distanceMeters * 0.000621371;
    let returnMiles = String(Int(distanceMiles)) + " miles";
    return returnMiles;
}





