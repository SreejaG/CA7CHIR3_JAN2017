
import UIKit

class ImageUpload: NSObject {
    
    class var sharedInstance: ImageUpload {
        struct Singleton {
            static let instance = ImageUpload()
        }
        return Singleton.instance
    }
    
    func uploadImageToCloud(userName: String, accessToken: String, image: NSData, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        let datastring = NSString(data: image as Data, encoding:String.Encoding.utf8.rawValue)
        
        requestManager.httpManager().put(UrlManager.sharedInstance.mediaUploadUrl(), parameters: datastring, success: { (operation, response) -> Void in
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
    
    func test( userName: String, accessToken: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get("http://192.168.16.60:3000/api/v1/test", parameters: nil, success: { (operation, response) -> Void in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: {  (operation, error) -> Void in
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
    
    func getSignedURL(userName: String, accessToken: String,  mediaType : String, videoDuration: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        var params = NSMutableDictionary()
        if(mediaType == "video")
        {
            params = ["userName":userName, "access_token":accessToken ,"mediaType": mediaType, "videoDuration": videoDuration]
        }
        else{
            params = ["userName":userName, "access_token":accessToken ,"mediaType": mediaType]
        }
        
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().post(UrlManager.sharedInstance.gesMediaObjectCreationUrl(), parameters: params , success: { (operation, response) -> Void in
            
            if var responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
                responseObject.removeAll()
            }
            else
            {
                //The response did not match the form we expected, error/fail
                failure?(NSError(domain: "Response error", code: 1, userInfo: nil), "ResponseInvalid")
            }
            
        }, failure: {  (operation, error) -> Void in
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
    
    func  setDefaultMediaChannelMapping(userName: String, accessToken: String, objectName: String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        
        requestManager.httpManager().post(UrlManager.sharedInstance.defaultCHannelMediaMapping(objectName: objectName), parameters: ["userName":userName, "access_token":accessToken ], success: { (operation, response) -> Void in
            
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
    
    func getChannelMediaDetails(channelId : String , userName: String, accessToken: String, limit: String, offset: String , success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getChannelMediaDetails(channelId: channelId, userName: userName, accessToken: accessToken, limit: limit, offset: offset), parameters: nil, success: { (operation, response) -> Void in
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
    
    func getOwnerChannelMediaDetails(channelId : String , userName: String, accessToken: String, limit: String, offset: String , success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getOwnerChannelMediaDetails(channelId: channelId, userName: userName, accessToken: accessToken, limit: limit, offset: offset), parameters: nil, success: { (operation, response) -> Void in
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
    
    func getSubscribedChannelMediaDetails(userName: String, accessToken: String, limit: String, offset: String , success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getSubscribedChannelMediaDetails(userName: userName, accessToken: accessToken, limit: limit, offset: offset), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    //delete media from channel
    func deleteMediasByChannel(userName: String, accessToken: String, mediaIds: NSArray, channelId:NSArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().delete(UrlManager.sharedInstance.MediaByChannelAPIUrl(userName: userName, accessToken: accessToken), parameters: ["mediaId":mediaIds, "channelId":channelId], success: { (operation, response) -> Void in
            
            if var responseObject = response as? [String:AnyObject]
            {
                success?(responseObject as AnyObject?)
                responseObject.removeAll()
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
    
    //Add media to channel
    func addMediaToChannel(userName: String, accessToken: String, mediaIds: NSArray, channelId:NSArray, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().put(UrlManager.sharedInstance.MediaByChannelAPIUrl(userName: userName, accessToken: accessToken), parameters: ["mediaId":mediaIds, "channelId":channelId], success: { (operation, response) -> Void in
            
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
    
    
    func getChannelMediaDetailsDuringScrollingDown(channelId : String , userName: String, accessToken: String, channelMediaDetailId: String, limit: String , success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.getChannelMediaDetailsDuringScrollingAPI(), parameters: ["channelId":channelId, "userName":userName,"access_token":accessToken,"channelMediaId":channelMediaDetailId,"limit":limit], success: { (operation, response) -> Void in
            
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
    
    func getInfinteScrollChannelMediaDetails(channelId : String , userName: String, accessToken: String ,channelMediaId : String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.infiniteScrollMediaDetails(), parameters: ["channelId": channelId,"userName":userName, "access_token":accessToken ,"channelMediaId" : channelMediaId ,"limit" : 20], success: { (operation, response) -> Void in
            
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
    
    func getPullToRefreshChannelMediaDetails(channelId : String , userName: String, accessToken: String ,channelMediaId : String, success: ((_ response: AnyObject?)->())?, failure: ((_ error: NSError?, _ code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().get(UrlManager.sharedInstance.pullToRefreshMediaDetails(channelId: channelId), parameters: ["userName":userName, "access_token":accessToken ,"channelMediaId" : channelMediaId], success: { (operation, response) -> Void in
            
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
}
