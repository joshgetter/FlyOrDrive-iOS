//
//  OAuth.swift
//  Fly or Drive
//
//  Created by Josh Getter on 2/17/17.
//  Copyright © 2017 Josh Getter. All rights reserved.
//
import SwiftyJSON
import Foundation

class AirportAPI{
    //TODO store in defaults for use after app closes
    static var airportToken = String()
    private var tokenAttempts = 0
    static func getToken(){
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
            AirportAPI.airportToken = json["access_token"].rawString()!
            UserDefaults.standard.register(defaults: ["airportToken" : airportToken]) //Update airportToken in defaults (to persist between sessions)
        }
        catch let parseError
        {
            print(parseError);
        }
    }
    
    static func GetAirports(startLat: String, startLon: String, endLat:String, endLon:String)->(origin: [String], dest: [String])?{
        if(AirportAPI.airportToken.isEmpty){getToken()}
        var argsArray = [(lat: String, lon: String)]()
        argsArray.append(lat: startLat, lon: startLon)
        argsArray.append(lat: endLat, lon: endLon)
        
        let baseURL = "https://api.lufthansa.com/v1/references/airports/nearest/"
        var originCodes = [String]()
        var destCodes = [String]()
        for arg in argsArray{ //Make both requests
            let requestUrlString = baseURL + arg.lat + "," + arg.lon + "?lang=EN"
            let requestUrl = URL(string: requestUrlString)
            var request = URLRequest(url: requestUrl!)
            request.cachePolicy = .reloadIgnoringCacheData
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer " + AirportAPI.airportToken, forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            var responseHeader : URLResponse?
            do{
                var responseData = try NSURLConnection.sendSynchronousRequest(request, returning: &responseHeader)
                if(responseHeader == nil){
                    getToken()
                    return GetAirports(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon)
                }
                let statusCode = (responseHeader as! HTTPURLResponse).statusCode
                if((400...406).contains(statusCode)){
                    getToken()
                    return GetAirports(startLat: startLat, startLon: startLon, endLat: endLat, endLon: endLon)
                }
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
                let vc = UIApplication.shared.keyWindow?.rootViewController
                vc?.present(simpleAlert("Oops", Message: "An error has occured please try again later"), animated: true, completion: nil);
                return (nil)
            }
        }
        return (originCodes, destCodes)
    }
    
}

