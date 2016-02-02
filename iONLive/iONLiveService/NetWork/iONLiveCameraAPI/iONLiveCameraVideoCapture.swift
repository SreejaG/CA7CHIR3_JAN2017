//
//  iONLiveCameraVideoCapture.swift
//  iONLive
//
//  Created by Vinitha on 2/1/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCameraVideoCapture: NSObject {

    class var sharedInstance: iONLiveCameraVideoCapture {
        
        struct Singleton {
            static let instance = iONLiveCameraVideoCapture()
        }
        return Singleton.instance
    }
    
    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func getiONLiveCameraVideoID( success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                
                var failureErrorCode:String = ""
                //get the error code from API if any
                if let errorCode = requestManager.getFailureDeveloperMessageFromResponse(error)
                {
                    failureErrorCode = errorCode
                }
                //The parameters were wrong or the network call failed
                failure?(error: error, code:failureErrorCode)
        })
    }
    
    func stopIONLiveCameraVideo( success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                
                var failureErrorCode:String = ""
                //get the error code from API if any
                if let errorCode = requestManager.getFailureDeveloperMessageFromResponse(error)
                {
                    failureErrorCode = errorCode
                }
                //The parameters were wrong or the network call failed
                failure?(error: error, code:failureErrorCode)
        })
    }

    
    func updateVideoSegements(numSegments numSegments: Int, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: ["numSegments" : numSegments],success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    func deleteVideo(hlsID hlsID: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: ["hlsID" : hlsID],success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: { (operation, error) -> Void in
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
}