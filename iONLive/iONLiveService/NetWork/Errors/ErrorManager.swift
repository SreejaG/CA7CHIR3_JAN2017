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
    
    class var sharedInstance: ErrorManager {
        struct Singleton {
            static let instance = ErrorManager()
        }
        return Singleton.instance
    }
    
    func serverError() {
        alert("Something went wrong :-/", message: "Something bad happened, we're looking into it now.")
    }
    
    func inValidResponseError() {
        alert("Invalid Response", message: "Something bad happened, we're looking into it now.")
    }
    
    func streamingError()
    {
        alert("Streaming Error", message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    
    func liveStreamFetchingError()
    {
        alert("Live Stream Fetching Error", message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    
    
    func loginInvalidEmail()
    {
        alert("Invalid Email", message: "Please provide a valid email address.")
    }
    
    func loginError() {
        alert("Login Error", message: "We're sorry but there was an error retrieving your account. Please try again.")
    }
    
    func signUpError() {
        alert("SignUp Error", message: "We're sorry but there was an error creating your account. Please try again.")
    }
    
    func loginNoEmailEnteredError()
    {
        alert("Login Error", message: "Please enter your username")
    }
    
    func loginNoPasswordEnteredError()
    {
        alert("Login Error", message: "Please enter your password")
    }
 
    func noNetworkConnection() {
        alert("Network Error", message: "Oops, it looks like you don't have a working internet connection. Please connect and try again.")
    }
    
    func authenticationIssue() {
        alert("Authentication Error", message: "We're sorry but there was an error retrieving your account. Please try login again.")
    }
    
    func memoryWarning() {
        alert("Low Memory Warning", message: "Your device is running low on available memory.\n\nPlease remove any registration lists and close any apps that are not needed at this time.")
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
    
}