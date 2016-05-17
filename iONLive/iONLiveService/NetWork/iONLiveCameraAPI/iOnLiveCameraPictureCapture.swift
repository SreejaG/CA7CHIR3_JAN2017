//
//  iOnLiveCameraPictureCapture.swift
//  iONLive
//
//  Created by Gadgeon on 1/18/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import Foundation

class iOnLiveCameraPictureCapture: NSObject {
    
    class var sharedInstance: iOnLiveCameraPictureCapture {
        struct Singleton {
            static let instance = iOnLiveCameraPictureCapture()
        }
        return Singleton.instance
    }
    
    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func getiONLiveCameraPictureId(scale: String?, burstCount: String?,burstInterval:String?,quality:String?, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.iONLiveCamGetPictureUrl(scale, burstCount: burstCount, burstInterval: burstInterval, quality: quality), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    
    //    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func deleteiONLiveCameraPicture(burstID: String!, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.iONLiveCamDeletePictureUrl(burstID), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func deleteAllIONLiveCameraPicture(success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.iONLiveCamDeleteAllPictureUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func cancelSnaps(success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.iONLiveCamCancelSnapsUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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
}

