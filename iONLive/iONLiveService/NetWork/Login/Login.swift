//
//  Login.swift
//  iONLive
//
//  Created by Gadgeon on 11/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation

class Login:NSObject
{
    var status:AnyObject?
    var tocken :AnyObject?
    var user :AnyObject?
    var expire:AnyObject?
    
  
    
    
    func createModelFromJson(response:AnyObject?)->Login
    {
        if let json = response as? [String:AnyObject]
        {
            print("success = \(json["status"]),\(json["token"]),\(json["user"])")
            if let _ = json["status"]
            {
                self.status = json["status"]
            }
            if let _ = json["tocken"]
            {
                self.tocken = json["tocken"]
            }
            if let _ = json["user"]
            {
                self.user = json["user"]
            }
            if let _ = json["expire"]
            {
                self.expire = json["expire"]
            }
        }
        
        return self
    }
}