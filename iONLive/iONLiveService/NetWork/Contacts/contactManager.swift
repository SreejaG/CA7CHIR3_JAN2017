
import UIKit

class contactManager: NSObject {
    
    class var sharedInstance: contactManager
    {
        struct Singleton
        {
            static let instance = contactManager()
        }
        return Singleton.instance
    }
    
    //Method to add contact details, success and failure block
    func addContactDetails(userName: String, accessToken: String, userContacts: NSArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.contactAPIUrl(), parameters: ["userName": userName, "access_token": accessToken, "contactList": userContacts], success: { (operation, response) -> Void in
            
            if let responseObject = response as? [String:AnyObject]
            {
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
    
    //Method to get contact details, success and failure block
    func getContactDetails(userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getContactDataAPIUrl(userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
            if let responseObject = response as? [String:AnyObject]
            {
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
    
    //Method to invite contact details, success and failure block
    func inviteContactDetails(userName: String, accessToken: String, contacts: NSArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.getContactDataAPIUrl(userName: userName, accessToken: accessToken), parameters: ["contactList":contacts], success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
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
}
