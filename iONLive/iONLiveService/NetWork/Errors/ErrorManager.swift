//
//  ErrorManager.swift
//  iONLive
//
//  Created by Gadgeon on 11/23/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import Foundation
import UIKit

class ErrorManager: NSObject, UIAlertViewDelegate {
    
    let loginErrorTitle = "Login Error"
    let signUpErrorTitle = "SignUp Error"
    let StreamingErrortitle = "Streaming Error"
    
    class var sharedInstance: ErrorManager {
        struct Singleton {
            static let instance = ErrorManager()
        }
        return Singleton.instance
    }
    
    //PRAGMA MARK:- General Errors
    
    func serverError() {
        alert("Something went wrong :-/", message: "Something bad happened, we're looking into it now.")
    }
    
    func inValidResponseError() {
        alert("Invalid Response", message: "Something bad happened, we're looking into it now.")
    }
    
    func invalidRequest()
    {
        alert("Error", message:"Invalid request")
    }
    
    func operationFailed()
    {
        alert("Error", message:"Operation failed")
    }
    //PRAGMA MARK:- Login Errors
    
    func loginInvalidEmail()
    {
        alert("Invalid Email", message: "Please provide a valid email address.")
    }
    
    func loginError() {
        alert(loginErrorTitle, message: "We're sorry but there was an error retrieving your account. Please try again.")
    }
    
    func loginNoEmailEnteredError()
    {
        alert(loginErrorTitle, message: "Please enter your username")
    }
    
    func loginNoPasswordEnteredError()
    {
        alert(loginErrorTitle, message: "Please enter your password")
    }
    
    func authenticationIssue() {
        alert("Authentication Error", message: "We're sorry but there was an error retrieving your account. Please try login again.")
    }
    
    func invalidUserNameOrPaswd()
    {
        alert(loginErrorTitle, message:"Invalid username or password")
    }
    
    func invalidUserError()
    {
        alert(loginErrorTitle, message: "Invalid user")
    }
    
    //PRAGMA MARK:- Sign up errors
    
    func signUpError() {
        alert(signUpErrorTitle, message: "We're sorry but there was an error creating your account. Please try again.")
    }
    
    func userAlreadyRegError()
    {
        alert(signUpErrorTitle, message: "This user has already been registered")
    }
    
    func noEmailEnteredError()
    {
        alert("No Email", message: "Please enter your Email")
    }
    
    //PRAGMA MARK:- Connectivity errors
    
    func noNetworkConnection() {
        alert("Network Error", message: "Oops, it looks like you don't have a working internet connection. Please connect and try again.")
    }
    
    //PRAGMA MARK:- Streaming errors
    
    func streamingError()
    {
        alert(StreamingErrortitle, message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    
    func liveStreamFetchingError()
    {
        alert("Live Stream Fetching Error", message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    
    func invalidTockenError()
    {
        alert("Invalid Tocken", message:"Invalid Tocken error. Please try again")
    }
    
    func tockenExpired()
    {
        alert("Tocken Expired", message:"Tocken expired error. please try again")
    }
    
    func tockenMissingError()
    {
        alert("Tocken Missing", message: "Tocken missing error. Please try again")
    }
    
    func invalidStream()
    {
        alert("Error", message:"Invalid stream")
    }
    
    func alert(var title: String?, var message: String?) {
        if title as String? == nil {
            title = "Error"
        }
        
        if message as String? == nil {
            message = "\nWe're sorry, but an error occurred. Please try again."
        }
        
        UIAlertView(title: title, message: "\n"+(message)!, delegate: self, cancelButtonTitle: "OK").show()
    }
    
    //PRAGMA MARK:- Error code mapping
    
    func mapErorMessageToErrorCode(errorCode:String)
    {
        switch errorCode
        {
         case "USER001": //userAllreadyRegisterd
            userAlreadyRegError()
            break
        case "USER002":  //invalidUserNameOrPassword
            invalidUserNameOrPaswd()
            break
        case "USER003": //invalidUser
            invalidUserError()
            break
        case "USER004": //invalidToken
            invalidTockenError()
            break
        case "USER005": //tokenExpired
            tockenExpired()
            break
        case "USER006": //missingToken
            tockenMissingError()
            break
        case "STREAM001": //invalidStreamToken
            invalidStream()
            break
        case "GENERAL001": //invalidRequest
            invalidRequest()
            break
        case "GENERAL002": //operationFailed
            operationFailed()
            break
        case"ResponseInvalid":
            inValidResponseError()
            break
        case "WOWZA001":  //"Wowza stream empty."
            //Currently avoiding alert when live steam is empty.
            break
        default:
            serverError()
            break
        }
    }
}