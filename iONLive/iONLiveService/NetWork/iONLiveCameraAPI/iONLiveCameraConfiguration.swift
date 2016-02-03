//
//  iONLiveCameraConfiguration.swift
//  iONLive
//
//  Created by Vinitha on 2/3/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class iONLiveCameraConfiguration: NSObject {

    class var sharedInstance: iONLiveCameraConfiguration {
        
        struct Singleton {
            static let instance = iONLiveCameraConfiguration()
        }
        return Singleton.instance
    }
    
    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func getiONLiveCameraConfiguration(scale: String?, quality: String?,singleClick:String?,doubleClick:String? , success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        
        requestManager.httpManager().GET(UrlManager.sharedInstance.getIONLiveCameraConfigUrl(scale, quality: quality, singleClick: singleClick, doubleClick: doubleClick), parameters: nil, success: { (operation, response) -> Void in
            
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

    func putIONLiveCameraConfiguration(scale: String?, quality: String?,singleClick:String?,doubleClick:String? , success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.getIONLiveCameraConfigUrl(scale, quality: quality, singleClick: singleClick, doubleClick: doubleClick), parameters: nil,success: { (operation, response) -> Void in
            
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
    
//    func putIONLiveCameraConfiguration(scale: String?, quality: String?,singleClick:String?,doubleClick:String? , success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
//    {
//        let requestManager = RequestManager.sharedInstance
//        
//        requestManager.httpManager().PUT(UrlManager.sharedInstance.getIONLiveCameraConfigUrl(scale, quality: quality, singleClick: singleClick, doubleClick: doubleClick), parameters: nil, success: { (operation, response) -> Void in
//            
//            //Get and parse the response
//            if let responseObject = response as? [String:AnyObject]
//            {
//                //call the success block that was passed with response data
//                success?(response: responseObject)
//            }
//            else
//            {
//                //The response did not match the form we expected, error/fail
//                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
//            }
//            
//            }, failure: { (operation, error) -> Void in
//                
//                var failureErrorCode:String = ""
//                //get the error code from API if any
//                if let errorCode = requestManager.getFailureDeveloperMessageFromResponse(error)
//                {
//                    failureErrorCode = errorCode
//                }
//                //The parameters were wrong or the network call failed
//                failure?(error: error, code:failureErrorCode)
//        })
//    }
}
