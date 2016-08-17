
import UIKit

class ProfileManager: NSObject,NSURLSessionDelegate,NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    
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
    
    func getSubUserProfileImage(userName: String, accessToken: String, subscriberUserName: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?){
        
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getSubscriberProfileImageAPIUrl(userName, accessToken: accessToken, subscriberUserName: subscriberUserName), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func uploadProfileImage(userName: String, accessToken: String, profileImage: NSData, actualImageUrl: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?){
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.getProfileImageUploadAPIUrl(userName, accessToken: accessToken, actualImageUrl: actualImageUrl), parameters: nil, constructingBodyWithBlock: { (formData: AFMultipartFormData!) -> Void in
            formData.appendPartWithFileData(profileImage, name: "Photo", fileName: "photo.jpg", mimeType: "image/jpeg")
            },success: { (operation, response) -> Void in
                if let responseObject = response as? [String:AnyObject]
                {
                    success?(response: responseObject)
                }
                else
                {
                    failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
                }
                
            }, failure: { (operation, error) -> Void in
                
                var failureErrorCode:String = ""
                if let errorCode = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorCode = errorCode
                }
                failure?(error: error, code:failureErrorCode)
        })
    }
    
    func updateUserDetails(userName: String, accessToken: String, email: String, location: String, mobNo: String,fullName: String, timeZone: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?){
        
        var paramet = NSMutableDictionary()
        if(fullName == ""){
            paramet  = ["email":email,"mobileNumber":mobNo,"timeZone": timeZone]
        }
        else{
            paramet  = ["email":email,"mobileNumber":mobNo,"fullName":fullName,"timeZone": timeZone]
        }
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.getProfileImageAPIUrl(userName, accessToken: accessToken), parameters: paramet, success: { (operation, response) -> Void in
            
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
    
    //Method to get user details, success and failure block
    func getUploadProfileImageURL(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.getProfileUploadAPIUrl(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
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
