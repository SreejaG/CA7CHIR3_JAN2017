
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
        alert(title: "Something went wrong :-/", message: "Something bad happened")
    }
    
    func inValidResponseError() {
        alert(title: "Invalid Response", message: "Something bad happened")
    }
    
    func subscriptionEmpty ()
    {
        alert(title: "Shared Channel Empty", message: "No Sharing Data.")
    }
    
    func invalidRequest()
    {
        alert(title: "Error", message:"Invalid request")
    }
    
    func operationFailed()
    {
        alert(title: "Error", message:"Operation failed")
    }
    
    func updationFailed()
    {
        alert(title: "Error", message:"Updation failed")
    }
    
    func invalidImage()
    {
        alert(title: "Invalid Email", message:"Please provide a valid image")
    }
    
    func loginInvalidEmail()
    {
        alert(title: "Invalid Email", message: "Please provide a valid email address.")
    }
    
    func withouCodeMobNumber()
    {
        alert(title: "Missing Code", message: "Mobile Number should be in the format +Country Code Mobile Number (+918967543467)")
    }
    
    func loginError() {
        alert(title: loginErrorTitle, message: "We're sorry but there was an error retrieving your account. Please try again.")
    }
    
    func loginNoEmailEnteredError()
    {
        alert(title: loginErrorTitle, message: "Please enter your username")
    }
    
    func loginNoFullnameEnteredError()
    {
        alert(title: loginErrorTitle, message: "Please enter your full name")
    }
    
    func loginNoPasswordEnteredError()
    {
        alert(title: loginErrorTitle, message: "Please enter your password")
    }
    
    func authenticationIssue() {
        alert(title: "Authentication Error", message: "We're sorry but there was an error retrieving your account. Please try login again.")
    }
    
    func invalidUserNameOrPaswd()
    {
        alert(title: loginErrorTitle, message:"Invalid username or password")
    }
    
    func invalidUserError()
    {
        alert(title: loginErrorTitle, message: "Invalid user")
    }
    
    func newPaswrdEmpty ()
    {
        alert(title: "New Password Empty", message: "Please enter your password")
    }
    
    func confirmPaswrdEmpty ()
    {
        alert(title: "Re-enter Password Empty", message: "Please Re-enter your password")
    }
    
    func probelmTitleEmpty ()
    {
        alert(title: "Problem Title Empty", message: "Please enter a Title for Problem")
    }
    
    func descOfProblemEmpty()
    {
        alert(title: "Description Empty", message: "Please enter a brief Description")
    }
    
    func signUpError() {
        alert(title: signUpErrorTitle, message: "We're sorry but there was an error creating your account. Please try again.")
    }
    
    func addContactError() {
        alert(title: ContactErrortitle, message: "We're sorry but there was an error adding your contacts. Please try again.")
    }
    
    func userAlreadyRegError()
    {
        alert(title: signUpErrorTitle, message: "This user has already been registered")
    }
    
    func noEmailEnteredError()
    {
        alert(title: "No Email", message: "Please enter your Email")
    }
    
    func InvalidPwdEnteredError()
    {
        alert(title: "Invalid Password", message: "Password must contain atleast 8 characters and atmost 40 characters")
    }
    
    func InvalidChannelEnteredError()
    {
        alert(title: "Invalid Channel", message: "Channel Name must contain atleast 3 characters and atmost 15 characters")
    }
    
    func noNumberInPassword()
    {
        alert(title: "Invalid Password", message: "Password must contain atleast 1 digit")
    }
    
    func InvalidUsernameEnteredError()
    {
        alert(title: "Invalid Username", message: "Username must contain atleast 5 charactes and atmost 15 characters")
    }
    
    func noSpaceInUsername()
    {
        alert(title: "Invalid Username", message: "Username should not contain white spaces")
    }
    
    func signUpNoEmailEnteredError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your email Id")
    }
    
    func signUpNoUsernameEnteredError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your username")
    }
    
    func emptyCountryError()
    {
        alert(title: signUpErrorTitle, message: "Please select your country")
    }
    
    func emptyMobileError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your mobile number")
    }
    
    func emptyCodeError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your country code")
    }
    
    func emptyCountryCodeError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your country code")
    }
    
    func signUpNoCodeEnteredError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your verification code")
    }
    
    func signUpNoPasswordEnteredError()
    {
        alert(title: signUpErrorTitle, message: "Please enter your password")
    }
    func resetPassworderror()
    {
        alert(title: "Password Error", message: "Please enter your password")
        
    }
    func failedToUpdatepassword()
    {
        alert(title: "Error", message: "Failed to update password")
        
    }
    func missingFullNameError()
    {
        alert(title: "Missing Fullname", message: "Please enter your Full name")
    }
    
    func noNetworkConnection() {
        alert(title: "Network Error", message: "Oops, it looks like you don't have a working internet connection. Please connect and try again.")
    }
    
    func streamingError()
    {
        alert(title: StreamingErrortitle, message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    
    func liveStreamFetchingError()
    {
        alert(title: "Live Stream Fetching Error", message: "\nWe're sorry, but an error occurred. Please try again.")
    }
    func liveStreamStopped()
    {
        alert(title: "Live Stream Stopped", message: " live stream stopped by user")
    }
    func invalidTockenError()
    {
        alert(title: "Invalid Token", message:"Invalid Token error. Please try again")
    }
    
    func passwordMismatch()
    {
        alert(title: "Password Mismatch", message:"The new and re-enter passwords should be same")
    }
    
    func tockenExpired()
    {
        alert(title: "Token Expired", message:"Token expired error. please try again")
    }
    
    func tockenMissingError()
    {
        alert(title: "Token Missing", message: "Token missing error. Please try again")
    }
    
    func invalidStream()
    {
        alert(title: "Error", message:"Invalid stream")
    }
    
    func verificationCodeMismatchError()
    {
        alert(title: "Code Mismatch", message: "Verification code mismatch error. Please try again")
    }
    
    func alert(title: String?, message: String?) {
        var title = title
        var message = message
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
        self.perform(#selector(ErrorManager.dismissAlert(alert:)), with: alertView, afterDelay: 2)
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
        alert(title: "Failed", message: "Failed to get channel details")
    }
    
    func channelAlreayExist()
    {
        alert(title: "Channel Exist", message: "Channel name already exists")
    }
    
    
    func unsubscribedUserChannel()
    {
        alert(title: "Unsubscribed User", message: "channel is not subscribed")
    }
    
    func invalidUserChannel()
    {
        alert(title: "Invalid User", message: "sorry! you dont have the permission to access the channel")
    }
    
    func invalidChannelId()
    {
        alert(title: "Invalid Channel", message: "Channel details invalid")
    }
    
    func invalidChannel()
    {
        alert(title: "Invalid Channel", message: "Channel is invalid")
    }
    
    func invalidChannelName()
    {
        alert(title: "Invalid Channel", message: "Channel name invalid")
    }
    
    func invalidGCSName()
    {
        alert(title: "Invalid GCS", message: "GCS name invalid")
    }
    
    func uploadFailed()
    {
        alert(title: "Deletion Failed", message: "Deleting media before upload")
    }
    
    func invalidBucket()
    {
        alert(title: "Invalid Bucket", message: "Bucket name invalid")
    }
    
    func invalidEmail()
    {
        alert(title: "Invalid Email", message: "Email Id invalid")
    }
    
    func invalidVerification()
    {
        alert(title: "Invalid Verification", message: "Verification method invalid")
    }
    
    func invalidMobileNo()
    {
        alert(title: "Invalid mobile Numer", message: "Mobile number invalid/already registered")
    }
    
    func unregisteredContact()
    {
        alert(title: "Invalid Contacts", message: "Unregistered Contact List")
    }
    
    func mobileExist()
    {
        alert(title: signUpErrorTitle, message: "Mobile number already exists")
    }
    
    func invalidContacts()
    {
        alert(title: "Invalid Contacts", message: "Invalid Contact List")
    }
    
    func emptyContact()
    {
        alert(title: "No Contacts", message: "Contact List Empty")
    }
    
    func streamAvailable() {
        alert(title: "Live Stream", message: "Someone shared a stream")
    }
    
    func emptyMedia()
    {
        alert(title: "No Media", message: "Oops! No media, Please take some pictures or invite Ca7ch contacts...")
    }
    
    func noShared()
    {
        alert(title: "No Shared Media", message: "No Shared Images available")
        
    }
    func installFailure()
    {
        alert(title: "Install Failed", message: "Ooops, The CA7CH is not installed properly, please reinstall the application once again...")
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
        case"MEDIA004":
            uploadFailed()
            break
        default:
            alert(title: "Error", message: "\(errorCode)")
            break
        }
    }
}
