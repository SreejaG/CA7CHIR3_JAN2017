
import Foundation

class AuthenticationManager: NSObject {
    class var sharedInstance: AuthenticationManager {
        struct Singleton {
            static let instance = AuthenticationManager()
        }
        return Singleton.instance
    }
    
    //Method to authenticate a user with email and password, success and failure block
    func authenticate(email: String, password: String, gcmRegId:String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.usersLoginAPIUrl(), parameters: ["userName":email,"password": password, "gcmRegistrationId": gcmRegId], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error code from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func signUp(email: String, password: String, userName: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.usersSignUpAPIUrl(), parameters: ["email":email,"password": password,"userName": userName], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error message from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    //verification code generation
    func generateVerificationCodes(userName: String, location: String, mobileNumber: String, verificationMethod: String, offset: String, countryCode: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.usersSignUpAPIUrl(), parameters: ["location":location,"mobileNumber":mobileNumber,"userName":userName,"verificationMethod":verificationMethod,"timeZone":offset, "countryCode":countryCode], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error message from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func generateVerificationCodeForResetPassword(mobileNumber: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.getPasswordUrl(), parameters: ["mobileNumber":mobileNumber], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error message from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func validateVerificationCode(userName: String, verificationCode: String, gcmRegId: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getUserRelatedDataAPIUrl(userName: userName), parameters: ["verificationCode":verificationCode,"gcmRegistrationId":gcmRegId], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error message from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    func resetPassword(mobileNumber: String, newPassword: String, verificationCode: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getPasswordUrl(), parameters: ["mobileNumber":mobileNumber,"newPassword":newPassword,"verificationCode":verificationCode], success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
                //call the success block that was passed with response data
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: { (operation, error) -> Void in
            
            var failureErrorCode:String = ""
            //get the error message from API if any
            if let errorCode = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
}
