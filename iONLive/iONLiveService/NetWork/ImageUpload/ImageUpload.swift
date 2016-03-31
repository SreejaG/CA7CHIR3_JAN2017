//
//  ImageUpload.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/16/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ImageUpload: NSObject {
    
    class var sharedInstance: ImageUpload {
        struct Singleton {
            static let instance = ImageUpload()
        }
        return Singleton.instance
    }
    func uploadImageToCloud(userName: String, accessToken: String, image: NSData, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        
        let requestManager = RequestManager.sharedInstance
        let datastring = NSString(data: image, encoding:NSUTF8StringEncoding)
        requestManager.httpManager().PUT(UrlManager.sharedInstance.mediaUploadUrl(), parameters: datastring, success: { (operation, response) -> Void in
            
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
    
    
    func test( userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET("http://192.168.16.60:3000/api/v1/test", parameters: nil, success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
                
                success?(response: responseObject)
                
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            }, failure: {  (operation, error) -> Void in
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
    
    func getSignedURL(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        
        let requestManager = RequestManager.sharedInstance
        
        requestManager.httpManager().POST(UrlManager.sharedInstance.gesMediaObjectCreationUrl(), parameters: ["userName":userName, "access_token":accessToken], success: { (operation, response) -> Void in
            
            print(response)
            if let responseObject = response as? [String:AnyObject]
            {
                
                success?(response: responseObject)
                
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
            }
            
            
            }, failure: {  (operation, error) -> Void in
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
    
    
    
    
    func  setDefaultMediaChannelMapping(userName: String, accessToken: String, objectName: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        
        let requestManager = RequestManager.sharedInstance
        
        requestManager.httpManager().POST(UrlManager.sharedInstance.defaultCHannelMediaMapping(objectName), parameters: ["userName":userName, "access_token":accessToken ], success: { (operation, response) -> Void in
            
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
    
    
    
    func getChannelMediaDetails(channelId : String , userName: String, accessToken: String, limit: String, offset: String , success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getChannelMediaDetails(channelId, userName: userName, accessToken: accessToken, limit: limit, offset: offset), parameters: nil, success: { (operation, response) -> Void in
            
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
    //        requestManager.httpManager().POST(UrlManager.sharedInstance.mediaUploadUrl(), parameters: nil, constructingBodyWithBlock: { (formData: AFMultipartFormData!) -> Void in
    //            formData.appendPartWithFileData(image, name: "photo", fileName : "photo.jpg", mimeType: "image/jpeg")
    //            },  success: { (operation, response) -> Void in
    //
    //            if let responseObject = response as? [String:AnyObject]
    //            {
    //                success?(response: responseObject)
    //
    //            }
    //            else
    //            {
    //                //The response did not match the form we expected, error/fail
    //                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
    //            }
    //
    //
    //            }, failure: { (operation, error) -> Void in
    //                var failureErrorCode:String = ""
    //                //get the error code from API if any
    //                if let errorCode = requestManager.getFailureErrorCodeFromResponse(error)
    //                {
    //                    failureErrorCode = errorCode
    //                }
    //                //The credentials were wrong or the network call failed
    //                failure?(error: error, code:failureErrorCode)
    //        })
    //}
    
    
    //delete media from channel
    func deleteMediasByChannel(userName: String, accessToken: String, mediaIds: NSArray, channelId:NSArray, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.MediaByChannelAPIUrl(userName, accessToken: accessToken), parameters: ["mediaId":mediaIds, "channelId":channelId], success: { (operation, response) -> Void in
            
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

    //Add media to channel
    func addMediaToChannel(userName: String, accessToken: String, mediaIds: NSArray, channelId:NSArray, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.MediaByChannelAPIUrl(userName, accessToken: accessToken), parameters: ["mediaId":mediaIds, "channelId":channelId], success: { (operation, response) -> Void in
            
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
