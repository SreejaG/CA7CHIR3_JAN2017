
import UIKit

class iONCamLiveStatusManager: NSObject {
    class var sharedInstance: iONLiveCameraStatus {
        struct Singleton {
            static let instance = iONLiveCameraStatus()
        }
        return Singleton.instance
    }
    
    func getiONLiveStreamStatus( success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getIONLiveCameraStatusUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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
            if let errorCode = requestManager.getFailureDeveloperMessageFromResponse(error: error as NSError?)
            {
                failureErrorCode = errorCode
            }
            //The parameters were wrong or the network call failed
            failure?(error as NSError?, failureErrorCode)
        })
    }
    
    //    func putIONLiveCameraStreamConfiguration(action: String?, resolution: String?,framerate:String?, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    //    {
    //        let requestManager = RequestManager.sharedInstance
    //        requestManager.httpManager().PUT(UrlManager.sharedInstance.getIONLiveCameraStreamConfigUrl(action, resolution: resolution, framerate: framerate), parameters: nil,success: { (operation, response) -> Void in
    //
    //            //Get and parse the response
    //            if let responseObject = response as? [String:AnyObject]
    //            {
    //                //call the success block that was passed with response data
    //                success?(response: responseObject)
    //            }
    //            else
    //            {
    //                //The response did not match the form we expected, error/fail
    //                failure?(error: NSError(domain: "Response error", code: 1, userInfo: nil), code: "ResponseInvalid")
    //            }
    //
    //            }, failure: { (operation, error) -> Void in
    //                var failureErrorDesc:String = ""
    //                //get the error message from API response if any
    //                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
    //                {
    //                    failureErrorDesc = errorMessage
    //                }
    //                failure?(error: error, code:failureErrorDesc)
    //        })
    //    }
    //
    
}
