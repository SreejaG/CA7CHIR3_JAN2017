//
//  IONLiveCameraStatusUtility.swift
//  iONLive
//
//  Created by Vinitha on 2/4/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class IONLiveCameraStatusUtility: NSObject {
    
    let iONLiveCameraStatusManager = iONLiveCameraStatus.sharedInstance
    
    var freememStatus = ""
    var spaceLeftStatus = ""
    var batteryLevelStatus = ""
    var catalogDataSourceStatus : [String]?
    var videoDataSourceStatus : [String]?
    
    
    func getCatalogStatus() -> [String]?
    {
        getCameraStatus()
        return catalogDataSourceStatus
    }
    
    func getVideoStatus() -> [String]?
    {
        getCameraStatus()
        return catalogDataSourceStatus
    }
    
    func getCameraStatus()
    {
        
        iONLiveCameraStatusManager.getiONLiveCameraStatus({ (response) -> () in
            
            self.iONLiveCamGetStatusSuccessHandler(response)
            
            }) { (error, code) -> () in
                
                ErrorManager.sharedInstance.alert("Status Failed", message: "Failure to get status ")
        }
    }
    
    //PRAGMA MARK:- API Handlers
    
    func iONLiveCamGetStatusSuccessHandler(response:AnyObject?)
    {
        print("entered status")
        if let json = response as? [String: AnyObject]
        {
            print("success")
            if let freemem = json["freemem"]
            {
                freememStatus = (freemem as? String)!
            }
            if let spaceLeft = json["spaceLeft"]
            {
                spaceLeftStatus = (spaceLeft as? String)!
            }
            if let batteryLevel = json["batteryLevel"]
            {
                batteryLevelStatus = (batteryLevel as? String)!
            }
            if let catalog = json["catalog"]
            {
                catalogDataSourceStatus = catalog as? [String]
            }
            if let video = json["video"]
            {
                videoDataSourceStatus = video as? [String]
            }
        }
    }
}
