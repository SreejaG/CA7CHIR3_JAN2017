//
//  AuthenticationManager.swift
//  iONLive
//
//  Created by Gadgeon on 11/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation


class AuthenticationManager: NSObject {
    
    class var sharedInstance: AuthenticationManager {
        struct Singleton {
            static let instance = AuthenticationManager()
        }
        return Singleton.instance
    }
    
    //Method to authenticate a user with email and password, success and failure block
    func authenticate(email email: String, password: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, message: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.usersLoginAPIUrl(), parameters: ["loginId":email,"password": password], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), message: "The authentication response is malformed")
            }
            
            }, failure: { (operation, error) -> Void in
                
                var failureErrorDesc:String = ""
                //get the error message from API if any
                if let errorMessage = requestManager.getFailureErrorMessageFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                //The credentials were wrong or the network call failed
                failure?(error: error, message:failureErrorDesc)
        })
    }

    func signUp(email email: String, password: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, message: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.usersSignUpAPIUrl(), parameters: ["loginId":email,"password": password,"firstName":"","lastName":"","displayName":"","location":""], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(response: responseObject)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), message: "The authentication response is malformed")
            }
            
            }, failure: { (operation, error) -> Void in
                
                var failureErrorDesc:String = ""
                //get the error message from API if any
                if let errorMessage = requestManager.getFailureErrorMessageFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                //The credentials were wrong or the network call failed
                failure?(error: error, message:failureErrorDesc)
        })
    }
}
