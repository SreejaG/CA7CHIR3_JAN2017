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
        return catalogDataSourceStatus
    }
    
    func getVideoStatus() -> [String]?
    {
        return videoDataSourceStatus
    }
    
    func getiONLiveCameraStatus( success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        iONLiveCameraStatusManager.getiONLiveCameraStatus({ (response) -> () in
            
            self.iONLiveCamGetStatusSuccessHandler(response)
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            
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
