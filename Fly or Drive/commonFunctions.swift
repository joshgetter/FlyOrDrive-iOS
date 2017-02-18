//
//  commonFunctions.swift
//  Fly or Drive
//
//  Created by Josh Getter on 1/6/16.
//  Copyright © 2016 Josh Getter. All rights reserved.
//

import Foundation
func simpleAlert(_ Title: String, Message: String) -> UIAlertController{
    let alert = UIAlertController(title: Title, message: Message, preferredStyle: UIAlertControllerStyle.alert);
    alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil));
    return alert;
}
