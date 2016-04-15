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
    
    //Method to get Channel details, success and failure block
    
    func getChannelContactDetails(channelId: String, userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getAllContactsChannelAPIUrl(channelId, userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
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
        print("\(userName) \(accessToken)  \(channelName)")
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
    
        //Method to delete Channel details, success and failure block
    func deleteChannelDetails(userName userName: String, accessToken: String, deleteChannelId:String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName, accessToken: accessToken), parameters: ["channelId": deleteChannelId], success: { (operation, response) -> Void in
            
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
    
    func inviteContactList(userName: String, accessToken: String, channelId: String, adduser: NSMutableArray, deleteUser: NSMutableArray, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.inviteContactsChannelAPIUrl(channelId), parameters: ["userName":userName, "access_token":accessToken, "addUser":adduser, "deleteUser":deleteUser], success: { (operation, response) -> Void in
            
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
