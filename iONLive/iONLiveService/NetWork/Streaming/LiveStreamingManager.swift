
import Foundation

class LiveStreamingManager: NSObject {
    
    class var sharedInstance: LiveStreamingManager {
        struct Singleton {
            static let instance = LiveStreamingManager()
        }
        return Singleton.instance
    }
    
    //PRAGMA MARK:- initialiseLiveStreaming
    //Method to initialize live streaming with userid, tocken, success and failure block
    func initialiseLiveStreaming(loginId: String, tocken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.liveStreamingAPIUrl(), parameters: ["userName":loginId,"access_token": tocken], success: { (operation, response) -> Void in
            
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
            //The credentials were wrong or the network call failed
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    //PRAGMA MARK:- startLiveStreaming
    //Method to start live streaming with user tocken and stream tocken, success and failure block
    func startLiveStreaming(loginId: String, accesstocken: String,streamTocken:String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.liveStreamingAPIUrl() + "/" + streamTocken, parameters: ["userName":loginId,"access_token":accesstocken,"action":"startStream"],success: { (operation, response) -> Void in
            
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
    
    //PRAGMA MARK:- stopLiveStreaming
    //Method to start live streaming with user tocken and stream tocken, success and failure block
    func stopLiveStreaming(loginId: String, accesstocken: String,streamTocken:String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.liveStreamingAPIUrl() + "/" + streamTocken, parameters: ["userName":loginId,"access_token":accesstocken,"action":"stopStream"],success: { (operation, response) -> Void in
            
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
    
    //PRAGMA MARK:- getAllLiveStreams
    func getAllLiveStreams(loginId: String, accesstocken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.liveStreamingAPIUrl(), parameters: ["userName":loginId,"access_token":accesstocken], success: { (operation, response) -> Void in
            
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
            
        },failure: { (operation, error) -> Void in
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
    
    //PRAGMA MARK:- Default Stream Mapping
    func defaultStreamMapping(loginId: String, accesstocken: String, streamTockn: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.liveStreamingAPIUrl() + "/" + streamTockn, parameters: ["userName":loginId,"access_token":accesstocken], success: { (operation, response) -> Void in
            
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
            
        },failure: { (operation, error) -> Void in
            var failureErrorDesc:String = ""
            //get the error message from API response if any
            if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error: error as NSError?)
            {
                failureErrorDesc = errorMessage
            }
            failure?(error as NSError?, failureErrorDesc)
        })
    }
}
