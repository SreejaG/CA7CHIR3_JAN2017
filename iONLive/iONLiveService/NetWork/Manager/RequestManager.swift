
import Foundation

class RequestManager {
    
    var timeoutInterval: NSTimeInterval {
        return 15.0
    }
    
    class var sharedInstance: RequestManager {
        struct Singleton {
            static let instance = RequestManager()
        }
        return Singleton.instance
    }
    
    func httpManager() -> AFHTTPRequestOperationManager {
        let http = AFHTTPRequestOperationManager()
        let requestSerializer = AFJSONRequestSerializer()
        requestSerializer.timeoutInterval = timeoutInterval
        http.requestSerializer = requestSerializer
        return http
    }
    
    func httpManagerWithApiKey(apiKey: String?) -> AFHTTPRequestOperationManager? {
        let http = AFHTTPRequestOperationManager()
        if (apiKey == nil) {
            return nil
        }
        let requestSerializer = AFJSONRequestSerializer()
        requestSerializer.setValue(apiKey, forHTTPHeaderField: "X-ATTENDWARE-KEY")
        requestSerializer.timeoutInterval = timeoutInterval
        http.requestSerializer = requestSerializer
        return http
    }
    
    func imageHttpManagerWithUrl(url: String) -> AFHTTPRequestOperation? {
        let nsUrl = NSURL(string: url)
        let imageRequest: NSURLRequest = NSURLRequest(URL: nsUrl!, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: timeoutInterval)
        let request: AFHTTPRequestOperation = AFHTTPRequestOperation(request: imageRequest)
        request.responseSerializer = AFImageResponseSerializer() as AFHTTPResponseSerializer
        return request
    }
    
    func validConnection() -> Bool {
        return Connectivity.reachabilityForInternetConnection().currentReachabilityStatus().rawValue != 0
    }
    
    func getFailureErrorMessageFromResponse(error: NSError?) -> String?
    {
        var errorMessage:String?
        if let error = error
        {
            let responseErrorData:NSData? = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData
            if let errorData = responseErrorData
            {
                do {
                    let jsonData = try NSJSONSerialization.JSONObjectWithData(errorData, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    if let errorMsg = jsonData[apiErrorMessageKey]
                    {
                        errorMessage = errorMsg as? String
                    }
                } catch {
                    errorMessage = nil
                }
            }
        }
        return errorMessage
    }
    
    func getFailureErrorCodeFromResponse(error: NSError?) -> String?
    {
        var errorCode:String?
        if let error = error
        {
            let responseErrorData:NSData? = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData
            if let errorData = responseErrorData
            {
                do {
                    let jsonData = try NSJSONSerialization.JSONObjectWithData(errorData, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    if let errorC = jsonData[apiErrorCodeKey]
                    {
                        errorCode = errorC as? String
                    }
                } catch {
                    errorCode = nil
                }
            }
        }
        return errorCode
    }
    
    func getFailureDeveloperMessageFromResponse(error: NSError?) -> String?
    {
        var errorCode:String?
        if let error = error
        {
            let responseErrorData:NSData? = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] as? NSData
            if let errorData = responseErrorData
            {
                do {
                    let jsonData = try NSJSONSerialization.JSONObjectWithData(errorData, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    if let errorC = jsonData[apiDeveloperFailureMessage]
                    {
                        errorCode = errorC as? String
                    }
                } catch {
                    errorCode = nil
                }
            }
        }
        return errorCode
    }
}