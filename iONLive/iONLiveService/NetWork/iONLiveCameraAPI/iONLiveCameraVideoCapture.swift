
import UIKit

class iONLiveCameraVideoCapture: NSObject {
    
    class var sharedInstance: iONLiveCameraVideoCapture {
        
        struct Singleton {
            static let instance = iONLiveCameraVideoCapture()
        }
        return Singleton.instance
    }
    
    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func getiONLiveCameraVideoID( success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func stopIONLiveCameraVideo( success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func startVideoWithSegments(numSegments: Int, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getiONLiveVideoUrl(), parameters: ["numSegments" : numSegments],success: { (operation, response) -> Void in
            
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
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    func deleteAllVideo( success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.getAlliONLiveVideoUrl(), parameters: nil,success: { (operation, response) -> Void in
            
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
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    func deleteVideoWithHlsId(hlsID: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.getiONLiveVideoUrlWithHlsId(hlsId: hlsID), parameters: nil,success: { (operation, response) -> Void in
            
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
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    func downloadm3u8Video(hlsID: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getiONLiveVideom3u8Url(hlsId: hlsID), parameters: nil, success: { (operation, response) -> Void in
            
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
}
