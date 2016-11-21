
import Foundation

class iOnLiveCameraPictureCapture: NSObject {
    
    class var sharedInstance: iOnLiveCameraPictureCapture {
        struct Singleton {
            static let instance = iOnLiveCameraPictureCapture()
        }
        return Singleton.instance
    }
    
    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func getiONLiveCameraPictureId(scale: String?, burstCount: String?,burstInterval:String?,quality:String?, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.iONLiveCamGetPictureUrl(scale: scale, burstCount: burstCount, burstInterval: burstInterval, quality: quality), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    //Method to get burst id of the image from connected iONLIve Cam, success and failure block
    func deleteiONLiveCameraPicture(burstID: String!, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.iONLiveCamDeletePictureUrl(burstId: burstID), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func deleteAllIONLiveCameraPicture(success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.iONLiveCamDeleteAllPictureUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    func cancelSnaps(success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.iONLiveCamCancelSnapsUrl(), parameters: nil, success: { (operation, response) -> Void in
            
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

