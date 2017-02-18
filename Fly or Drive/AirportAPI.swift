//
//  OAuth.swift
//  Fly or Drive
//
//  Created by Josh Getter on 2/17/17.
//  Copyright © 2017 Josh Getter. All rights reserved.
//
import SwiftyJSON
import p2_OAuth2
import Foundation

class AirportAPI{
    //TODO store in defaults for use after app closes
    var airportToken = String()
    
    func getToken() -> String{
        let CLIENTKEY = "5xsdqfuc4cme9p3c7fk8py9m"
        let CLIENTSECRET = "SRx43a47Xr"
        let GRANTTYPE = "client_credentials"
        let url = URL(string: "https://api.lufthansa.com/v1/oauth/token")
        var request = URLRequest(url: url!)
        let paramString = "client_id=" + CLIENTKEY + "&client_secret=" + CLIENTSECRET + "&grant_type=" + GRANTTYPE
        request.httpBody = paramString.data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        var response : URLResponse?
        do{
            var responseData = try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)
            let json = JSON(data: responseData)
            airportToken = json["access_token"].rawString()!
        }
        catch let parseError
        {
            print(parseError);
        }
        return airportToken
    }
    
    func GetAirports(startLat: String, startLon: String, endLat:String, endLon:String)->(origin: [String], dest: [String]){
        if(airportToken.isEmpty){getToken()}
        var argsArray = [(lat: String, lon: String)]()
        argsArray.append(lat: startLat, lon: startLon)
        argsArray.append(lat: endLat, lon: endLon)
        
        var tupleArray = [[String](),[String]()]
        let baseURL = "https://api.lufthansa.com/v1/references/airports/nearest/"
        let paramString = "Authorization=Bearer " + airportToken
        
        var originCodes = [String]()
        var destCodes = [String]()
        for arg in argsArray{ //Make both requests
            let requestUrlString = baseURL + arg.lat + "," + arg.lon + "?lang=EN"
            let requestUrl = URL(string: requestUrlString)
            var request = URLRequest(url: requestUrl!)
            request.cachePolicy = .reloadIgnoringCacheData
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer " + airportToken, forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            var responseHeader : URLResponse?
            do{
                var responseData = try NSURLConnection.sendSynchronousRequest(request, returning: &responseHeader)
                let json = JSON(data: responseData)
                var airportJson = json["NearestAirportResource", "Airports", "Airport"].arrayValue
                for airport in airportJson{
                    if(originCodes.count < 5){
                        originCodes.append(airport["AirportCode"].stringValue)
                    }else{
                        destCodes.append(airport["AirportCode"].stringValue)
                    }
                }
                print(json)
            }
            catch let error{
                print(error)
            }
        }
        return (originCodes, destCodes)
    }
    
}

