//
//  ChannelManager.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 02/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ChannelManager: NSObject {
    
    class var sharedInstance: ChannelManager {
        struct Singleton {
            static let instance = ChannelManager()
        }
        return Singleton.instance
    }
    
    //Method to get Channel details, success and failure block
    
    func getChannelDetails(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
          
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
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
    
    func addChannelDetails(userName: String, accessToken: String, channelName: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.channelAPIUrl(), parameters: ["userName":userName, "access_token":accessToken, "channelName":channelName], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
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
    func getMediaInteractionDetails(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getMediaInteractionNotifications(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
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
