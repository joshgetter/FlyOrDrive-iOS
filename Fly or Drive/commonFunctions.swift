//
//  commonFunctions.swift
//  Fly or Drive
//
//  Created by Josh Getter on 1/6/16.
//  Copyright © 2016 Josh Getter. All rights reserved.
//

import Foundation
func simpleAlert(Title: String, Message: String) -> UIAlertController{
    let alert = UIAlertController(title: Title, message: Message, preferredStyle: UIAlertControllerStyle.Alert);
    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil));
    return alert;
}