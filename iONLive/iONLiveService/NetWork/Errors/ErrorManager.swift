

import Foundation
import UIKit

class ErrorManager: NSObject, SwiftAlertViewDelegate {
    
    let loginErrorTitle = "Login Error"
    let signUpErrorTitle = "Sign Up Error"
    let StreamingErrortitle = "Streaming Error"
    let ContactErrortitle = "Contact Error"
    
    class var sharedInstance: ErrorManager {
        struct Singleton {
            static let instance = ErrorManager()
        }
        return Singleton.instance
    }
    
    func serverError() {
        alert("Something went wrong :-/", message: "Something bad happened")
    }
    
    func inValidResponseError() {
        alert("Invalid Response", message: "Something bad happened")
    }
    
    func subscriptionEmpty ()
    {
        alert("Shared Channel Empty", message: "No Sharing Data.")
        
    }
    
    func invalidRequest()
    {
        alert("Error", message:"Invalid request")
    }
    
    func operationFailed()
    {
        alert("Error", message:"Operation failed")
    }
    
    func updationFailed()
    {
        alert("Error", message:"Updation failed")
    }
    
    func invalidImage()
    {
        alert("Invalid Email", message:"Please provide a valid image")
    }
    
    func loginInvalidEmail()
    {
        alert("Invalid Email", message: "Please provide a valid email address.")
    }
    func withouCodeMobNumber()
    {
        alert("Missing Code", message: "Mobile Number should be in the format +Country Code Mobile Number (+918967543467)")
    }
    
    func loginError() {
        alert(loginErrorTitle, message: "We're sorry but there was an error retrieving your account. Please try again.")
    }
    
    func loginNoEmailEnteredError()
    {
        alert(loginErrorTitle, message: "Please enter your username")
    }
    
    func loginNoFullnameEnteredError()
    {
        alert(loginErrorTitle, message: "Please enter your full name")
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
    
    func newPaswrdEmpty ()
    {
        alert("New Password Empty", message: "Please enter your password")
    }
    
    func confirmPaswrdEmpty ()
    {
        alert("Re-enter Password Empty", message: "Please Re-enter your password")
    }
    
    
    func signUpError() {
        alert(signUpErrorTitle, message: "We're sorry but there was an error creating your account. Please try again.")
    }
    
    func addContactError() {
        alert(ContactErrortitle, message: "We're sorry but there was an error adding your contacts. Please try again.")
    }
    
    func userAlreadyRegError()
    {
        alert(signUpErrorTitle, message: "This user has already been registered")
    }
    
    func noEmailEnteredError()
    {
        alert("No Email", message: "Please enter your Email")
    }
    
    func InvalidPwdEnteredError()
    {
        alert("Invalid Password", message: "Password must contain atleast 8 characters and atmost 40 characters")
    }
    
    func InvalidChannelEnteredError()
    {
        alert("Invalid Channel", message: "Channel Name must contain atmost 15 characters")
    }
    
    func noNumberInPassword()
    {
        alert("Invalid Password", message: "Password must contain atleast 1 digit")
    }
    
    func InvalidUsernameEnteredError()
    {
        alert("Invalid Username", message: "Username must contain atleast 5 charactes and atmost 15 characters")
    }
    
    func noSpaceInUsername()
    {
        alert("Invalid Username", message: "Username should not contain white spaces")
    }
    
    func signUpNoEmailEnteredError()
    {
        alert(signUpErrorTitle, message: "Please enter your email Id")
    }
    
    func signUpNoUsernameEnteredError()
    {
        alert(signUpErrorTitle, message: "Please enter your username")
    }
    
    func emptyCountryError()
    {
        alert(signUpErrorTitle, message: "Please select your country")
    }
    
    func emptyMobileError()
    {
        alert(signUpErrorTitle, message: "Please enter your mobile number")
    }
    
    func emptyCodeError()
    {
        alert(signUpErrorTitle, message: "Please enter your country code")
    }
    
    func emptyCountryCodeError()
    {
        alert(signUpErrorTitle, message: "Please enter your country code")
    }
    
    func signUpNoCodeEnteredError()
    {
        alert(signUpErrorTitle, message: "Please enter your verification code")
    }
    
    func signUpNoPasswordEnteredError()
    {
        alert(signUpErrorTitle, message: "Please enter your password")
    }
    func resetPassworderror()
    {
        alert("Password Error", message: "Please enter your password")

    }
    func failedToUpdatepassword()
    {
        alert("Error", message: "Failed to update password")
 
    }
    func missingFullNameError()
    {
        alert("Missing Fullname", message: "Please enter your Full name")
    }
    
    func noNetworkConnection() {
        alert("Network Error", message: "Oops, it looks like you don't have a working internet connection. Please connect and try again.")
    }
    
    func streamingError()
    {
        alert(StreamingErrortitle, message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    
    func liveStreamFetchingError()
    {
        alert("Live Stream Fetching Error", message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    func liveStreamStopped()
    {
        alert("Live Stream Stopped", message: " live stream stopped by user")
    }
    func invalidTockenError()
    {
        alert("Invalid Token", message:"Invalid Token error. Please try again")
    }
    
    func passwordMismatch()
    {
        alert("Password Mismatch", message:"The new and re-enter passwords should be same")
    }
    
    func tockenExpired()
    {
        alert("Token Expired", message:"Token expired error. please try again")
    }
    
    func tockenMissingError()
    {
        alert("Token Missing", message: "Token missing error. Please try again")
    }
    
    func invalidStream()
    {
        alert("Error", message:"Invalid stream")
    }
    
    func verificationCodeMismatchError()
    {
        alert("Code Mismatch", message: "Verification code mismatch error. Please try again")
    }
    
    func alert(var title: String?, var message: String?) {
        if title as String? == nil {
            title = "Error"
        }
        
        if message as String? == nil {
            message = "\nWe're sorry, but an error occurred. Please try again."
        }
        let alertView = SwiftAlertView(title: title, message: "\n"+(message)!, delegate: self, cancelButtonTitle: nil)
        alertView.appearType = SwiftAlertViewAppearType.FadeIn
        alertView.disappearType = SwiftAlertViewDisappearType.FadeOut
        alertView.appearTime = 0.2
        alertView.disappearTime = 0.2
        
        alertView.show()
        self.performSelector(#selector(ErrorManager.dismissAlert(_:)), withObject: alertView, afterDelay: 2)
    }
    
    // MARK: SwiftAlertViewDelegate
    
    func alertView(alertView: SwiftAlertView, clickedButtonAtIndex buttonIndex: Int) {
    }
    
    func didPresentAlertView(alertView: SwiftAlertView) {
    }
    
    func didDismissAlertView(alertView: SwiftAlertView) {
    }
    
    func dismissAlert(alert : SwiftAlertView){
        alert.dismiss()
    }
    
    func NoArchiveId()
    {
        alert("Failed", message: "Failed to get channel details")
    }
    
    
    func channelAlreayExist()
    {
        alert("Channel Exist", message: "Channel name already exists")
    }
    
    
    func unsubscribedUserChannel()
    {
        alert("Unsubscribed User", message: "channel is not subscribed")
    }
    
    func invalidUserChannel()
    {
        alert("Invalid User", message: "sorry! you dont have the permission to access the channel")
    }
    
    func invalidChannelId()
    {
        alert("Invalid Channel", message: "Channel details invalid")
    }
    
    func invalidChannel()
    {
        alert("Invalid Channel", message: "Channel is invalid")
    }
    
    func invalidChannelName()
    {
        alert("Invalid Channel", message: "Channel name invalid")
    }
    
    func invalidGCSName()
    {
        alert("Invalid GCS", message: "GCS name invalid")
    }
    
    func invalidBucket()
    {
        alert("Invalid Bucket", message: "Bucket name invalid")
    }
    
    func invalidEmail()
    {
        alert("Invalid Email", message: "Email Id invalid")
    }
    
    func invalidVerification()
    {
        alert("Invalid Verification", message: "Verification method invalid")
    }
    
    func invalidMobileNo()
    {
        alert("Invalid mobile Numer", message: "Mobile number invalid/already registered")
    }
    
    func unregisteredContact()
    {
        alert("Invalid Contacts", message: "Unregistered Contact List")
    }
    
    func mobileExist()
    {
        alert(signUpErrorTitle, message: "Mobile number already exists")
    }
    
    func invalidContacts()
    {
        alert("Invalid Contacts", message: "Invalid Contact List")
    }
    
    func emptyContact()
    {
        alert("No Contacts", message: "Contact List Empty")
    }
    func streamAvailable() {
        alert("Live Stream", message: "Someone shared a stream")
    }
    func emptyMedia()
    {
        alert("No Media", message: "Oops! No media, Please take some pictures or invite Ca7ch contacts...")
    }
    func noShared()
    {
        alert("No Shared Media", message: "No Shared Images available")
        
    }
    func installFailure()
    {
        alert("Install Failed", message: "Ooops, The CA7CH is not installed properly, please reinstall the application once again...")
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
        case "USER007": //missmatchVerificationCode
            verificationCodeMismatchError()
            break
        case "USER008": //missmatchVerificationCode
            invalidMobileNo()
            break
        case "USER009": //missmatchVerificationCode
            invalidVerification()
            break
        case "USER010": //missmatchVerificationCode
            invalidEmail()
            break
        case "USER012":
            mobileExist()
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
        case "GENERAL004":
            invalidImage()
            break
        case "GENERAL005":
            updationFailed()
            break
        case"ResponseInvalid":
            inValidResponseError()
            break
        case "WOWZA001":  //"Wowza stream empty."
            break
        case"CHANNEL001":
            channelAlreayExist()
            break
        case"CHANNEL002":
            invalidChannelId()
            break
        case"CHANNEL003":
            invalidChannel()
            break
        case"CHANNEL004":
            invalidChannelName()
            break
        case"CHANNEL005":
            unsubscribedUserChannel()
            break
        case"CHANNEL006":
            invalidUserChannel()
            break
        case"CONTACT002":
            unregisteredContact()
            break
        case"CONTACT001":
            emptyContact()
            break
        case"CONTACT003":
            invalidContacts()
            break
        case"GCS001":
            invalidBucket()
            break
        case"MEDIA002":
            emptyMedia()
            break
        case"MEDIA003":
            emptyMedia()
            break
        case"MEDIA001":
            invalidGCSName()
            break
        default:
            alert("Error", message: "\(errorCode)")
            break
        }
    }
}