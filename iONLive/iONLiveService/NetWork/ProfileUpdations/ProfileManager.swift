//
//  ProfileManager.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 25/02/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ProfileManager: NSObject {

    class var sharedInstance: ProfileManager {
        struct Singleton {
            static let instance = ProfileManager()
        }
        return Singleton.instance
    }
    
    //Method to get user details, success and failure block
    func getUserDetails(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getProfileDataAPIUrl(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
           
            //Get and parse the response
            if let responseObject = response as? [[String:AnyObject]]
            {
                //call the success block that was passed with response data
//                self.getUserProfileImage(userName, accessToken: accessToken, success: success, failure: failure)
                
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
                if let errorCode = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorCode = errorCode
                }
                //The credentials were wrong or the network call failed
                failure?(error: error, code:failureErrorCode)
        })
        
    }
    
    
    
    
    func getUserProfileImage(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?){
        
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getProfileImageAPIUrl(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [[String:AnyObject]]
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
                if let errorCode = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorCode = errorCode
                }
                //The credentials were wrong or the network call failed
                failure?(error: error, code:failureErrorCode)
        })

    }

}
