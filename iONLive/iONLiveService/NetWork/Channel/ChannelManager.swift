
import UIKit

class ChannelManager: NSObject {
    
    class var sharedInstance: ChannelManager {
        struct Singleton {
            static let instance = ChannelManager()
        }
        return Singleton.instance
    }
    
    //Method to get Channel details, success and failure block
    
    func getChannelDetails(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
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
    
    //Method to get Channel details, success and failure block
    
    func getChannelContactDetails(channelId: String, userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getAllContactsChannelAPIUrl(channelId, userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            //Get and parse the response
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
    
    func getChannelNonContactDetails(channelId: String, userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getNonContactsChannelAPIUrl(channelId, userName: userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func addChannelDetails(userName: String, accessToken: String, channelName: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.channelAPIUrl(), parameters: ["userName":userName, "access_token":accessToken, "channelName":channelName], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func updateChannelName(userName: String, accessToken: String, channelName: String, channelId: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.updateChannelsAPIUrl(channelId, userName: userName, accessToken: accessToken), parameters: ["channelName":channelName], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    

    func getMediaInteractionDetails(userName: String, accessToken: String,limit:String,offset:String,success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getMediaInteractionNotifications(userName, accessToken: accessToken, limit: limit, offset: offset), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func postMediaInteractionDetails(userName: String, accessToken: String, notifType: String, mediaDetailId: Int, channelId: Int, type: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().POST(UrlManager.sharedInstance.MediaInteractionUrl(), parameters: ["userName":userName, "access_token":accessToken, "notificationType":notifType, type:mediaDetailId,"channelId":channelId], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getChannelShared(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getChannelSharedDetails(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    func getDataByNotificationId(userName: String, accessToken: String, notificationId : String,success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getNotificationIdData(), parameters:  ["userName":userName, "access_token": accessToken,"notificationId" :notificationId ], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    //Method to delete Channel details, success and failure block
    func deleteChannelDetails(userName userName: String, accessToken: String, deleteChannelId:String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let ChanelIdInt : Int = Int(deleteChannelId)!
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName, accessToken: accessToken), parameters: ["channelId": ChanelIdInt], success: { (operation, response) -> Void in
            
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
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    func inviteContactList(userName: String, accessToken: String, channelId: String, adduser: NSMutableArray, deleteUser: NSMutableArray, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.inviteContactsChannelAPIUrl(channelId), parameters: ["userName":userName, "access_token":accessToken, "addUser":adduser, "deleteUser":deleteUser], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func enableDisableChannels(userName: String, accessToken: String, addChannel: NSMutableArray, deleteChannel: NSMutableArray, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().PUT(UrlManager.sharedInstance.getAllChannelsAPIUrl(userName, accessToken: accessToken), parameters: ["enableChannelId":addChannel, "disableChannelId":deleteChannel], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    //Method to delete Channel details, success and failure block
    func deleteContactDetails(userName userName: String, accessToken: String, channelId:String, contactName: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().DELETE(UrlManager.sharedInstance.getDeleteContactChannelAPIUrl(channelId, userName: userName, accessToken: accessToken, contactName: contactName), parameters: nil, success: { (operation, response) -> Void in
            
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
                var failureErrorDesc:String = ""
                //get the error message from API response if any
                if let errorMessage = requestManager.getFailureErrorCodeFromResponse(error)
                {
                    failureErrorDesc = errorMessage
                }
                failure?(error: error, code:failureErrorDesc)
        })
    }
    
    func getLoggedInDetails(userName: String, accessToken: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getLoggedInDetails(userName, accessToken: accessToken), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getMediaLikeCountDetails(userName: String, accessToken: String, mediaId: String, mediaType: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getMedialikeCountAPI(userName, accessToken: accessToken), parameters: ["id":mediaId, "type": mediaType], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getUpdatedMediaDetails(userName: String, accessToken: String, timestamp: String, success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getUpdatedMediaDetails(userName, accessToken: accessToken,timeStamp: timestamp), parameters:nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    func getOffsetMediaDetails(userName: String, accessToken: String, timestamp: String,success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getOffsetDetails(userName, accessToken: accessToken), parameters:["channelMediaId":timestamp, "limit": "20"], success: { (operation, response) -> Void in
            
            //Get and parse the response
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
    
    func getChannelSharedPullToRefresh(userName: String, accessToken: String, channelSubId : String,success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        let requestManager = RequestManager.sharedInstance
        requestManager.httpManager().GET(UrlManager.sharedInstance.getChannelSharedDetailsPullToRefresh(userName, accessToken: accessToken, channelSubId: channelSubId), parameters: nil, success: { (operation, response) -> Void in
            
            //Get and parse the response
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
