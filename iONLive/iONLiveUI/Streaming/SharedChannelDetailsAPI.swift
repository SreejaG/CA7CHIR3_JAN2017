
import UIKit

class SharedChannelDetailsAPI: NSObject {
    class var sharedInstance: SharedChannelDetailsAPI
    {
        struct Singleton
        {
            static let instance = SharedChannelDetailsAPI()
            private init() {}
        }
        return Singleton.instance
    }
    var operationQueue = NSOperationQueue()
    
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var selectedSharedChannelMediaSource: [[String:AnyObject]] = [[String:AnyObject]]()
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    let streamTockenKey = "wowza_stream_token"
    let channelIdkey = "ch_detail_id"
    let notificationKey = "notification"
    let channelNameKey = "channel_name"
    let userIdKey = "user_name"
    let thumbImageKey = "thumbImage"
    let actualImageKey = "actualImage"
    var userName:String!
    var channelName :String = String()
    
    func cancelOpratn()
    {
    }
    
    func getSubscribedChannelData(channelId : String , selectedChannelName : String ,selectedChannelUserName :String , sharedCount : String)
    {
        if(channelName != "")
        {
            if channelName == selectedChannelName
            {
                selectedSharedChannelMediaSource.removeAll()
                imageDataSource.removeAll()
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
                channelName = selectedChannelName
                userName = selectedChannelUserName
                ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "21", offset: "0", success: { (response) -> () in
                    self.authenticationSuccessHandler(response)
                }) { (error, message) -> () in
                    self.authenticationFailureHandler(error, code: message)
                }
            }
            else{
                selectedSharedChannelMediaSource.removeAll()
                imageDataSource.removeAll()
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
                channelName = selectedChannelName
                userName = selectedChannelUserName
                ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "21", offset: "0", success: { (response) -> () in
                    self.authenticationSuccessHandler(response)
                }) { (error, message) -> () in
                    self.authenticationFailureHandler(error, code: message)
                }
            }
        }
        else{
            selectedSharedChannelMediaSource.removeAll()
            imageDataSource.removeAll()
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            channelName = selectedChannelName
            userName = selectedChannelUserName
            ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "21", offset: "0", success: { (response) -> () in
                self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
            }
        }
    }
    
    func infiniteScroll(channelId : String , selectedChannelName : String ,selectedChannelUserName :String , channelMediaId : String)
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        ImageUpload.sharedInstance.getInfinteScrollChannelMediaDetails(channelId, userName: selectedChannelUserName, accessToken: accessToken, channelMediaId: channelMediaId, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
            
        }
    }
    
    func getMedia(channelId : String , selectedChannelName : String ,selectedChannelUserName :String , sharedCount : String)
    {
        selectedSharedChannelMediaSource.removeAll()
        imageDataSource.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        channelName = selectedChannelName
        userName = selectedChannelUserName
        ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "21", offset: "0", success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
        }
    }
    
    func pullToRefresh (channelId : String ,selectedChannelUserName :String , channelMediaId : String)
    {
        let accessToken = NSUserDefaults .standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        ImageUpload.sharedInstance.getPullToRefreshChannelMediaDetails(channelId, userName: selectedChannelUserName, accessToken: accessToken, channelMediaId: channelMediaId, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        imageDataSource.removeAll()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrl =  responseArr[index].valueForKey("gcs_object_name_SignedUrl") as! String
                let infiniteScrollId  = responseArr[index].valueForKey("channel_media_detail_id")?.stringValue
                var notificationType : String = String()
                let time = responseArr[index].valueForKey("created_time_stamp") as! String
                if let notifType =  responseArr[index].valueForKey("notification_type") as? String
                {
                    if notifType != ""
                    {
                        notificationType = (notifType as? String)!.lowercaseString
                    }
                    else{
                        notificationType = "shared"
                    }
                }
                else{
                    notificationType = "shared"
                }
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,infiniteScrollIdKey: infiniteScrollId!,notificationKey:notificationType,"createdTime":time])
            }
            
            let responseArrLive = json["LiveDetail"] as! [AnyObject]
            
            for var liveIndex = 0 ; liveIndex < responseArrLive.count ; liveIndex++
            {
                let streamTocken = responseArrLive[liveIndex].valueForKey("wowza_stream_token")as! String
                let mediaUrl = responseArrLive[liveIndex].valueForKey("signedUrl") as! String
                let mediaId = responseArrLive[liveIndex].valueForKey("live_stream_detail_id")?.stringValue
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.timeZone = NSTimeZone(name: "UTC")
                let currentDate = dateFormatter.stringFromDate(NSDate())
                var notificationType : String = String()
                
                if let notifType =   responseArrLive[liveIndex]["notification_type"] as? String
                {
                    if notifType != ""
                    {
                        notificationType = (notifType as? String)!.lowercaseString
                    }
                    else{
                        notificationType = "shared"
                    }
                }
                else{
                    notificationType = "shared"
                }
                
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                        if(self.selectedSharedChannelMediaSource.count > 0)
                        {
                            if (self.selectedSharedChannelMediaSource[0][self.mediaTypeKey] as! String != "live")
                            {
                                self.selectedSharedChannelMediaSource.insert([self.mediaIdKey:mediaId!, self.mediaUrlKey:mediaUrl, self.thumbImageKey:result ,self.streamTockenKey:streamTocken,self.actualImageKey:mediaUrl,self.notificationKey:notificationType,self.mediaTypeKey:"live",infiniteScrollIdKey: "", self.userIdKey:self.userName, self.channelNameKey:self.channelName,"createdTime":currentDate], atIndex: 0)
                            }
                        }
                        else{
                            self.selectedSharedChannelMediaSource.insert([self.mediaIdKey:mediaId!, self.mediaUrlKey:mediaUrl, self.thumbImageKey:result ,self.streamTockenKey:streamTocken,self.actualImageKey:mediaUrl,self.notificationKey:notificationType,self.mediaTypeKey:"live",infiniteScrollIdKey: "", self.userIdKey:self.userName, self.channelNameKey:self.channelName,"createdTime":currentDate], atIndex: 0)
                        }
                    })
                }
            }
            
            if(imageDataSource.count > 0){
                if(self.selectedSharedChannelMediaSource.count > 0)
                {
                    if (self.selectedSharedChannelMediaSource[0][self.mediaTypeKey] as! String != "live")
                    {
                        self.selectedSharedChannelMediaSource.removeAtIndex(0)
                    }
                }
                
                let operation2 : NSBlockOperation = NSBlockOperation (block: {
                    self.downloadMediaFromGCS()
                })
                self.operationQueue.addOperation(operation2)
            }
            else{
                if self.selectedSharedChannelMediaSource.count > 0
                {
                    NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelMediaDetail", object: "success")
                }
                else{
                    NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelMediaDetail", object: "success")
                }
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelMediaDetail", object: "failure")
        if !RequestManager.sharedInstance.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        
        // Data object to fetch weather data
        do {
            let data = try NSData(contentsOfURL: downloadURL,options: NSDataReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData)
                {
                    mediaImage = mediaImage1
                }
                completion(result: mediaImage)
            }
            else
            {
                completion(result:UIImage(named: "thumb12")!)
            }
            
        } catch {
            completion(result:UIImage(named: "thumb12")!)
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    
    func downloadMediaFromGCS(){
        for var i = 0; i < imageDataSource.count; i++
        {
            var imageForMedia : UIImage = UIImage()
            if(imageDataSource.count > 0)
            {
                let mediaIdForFilePath = "\(imageDataSource[i][mediaIdKey] as! String)thumb"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                if fileExistFlag == true{
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                    imageForMedia = mediaImageFromFile!
                }
                else{
                    let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
                    if(mediaUrl != ""){
                        let url: NSURL = convertStringtoURL(mediaUrl)
                        downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                            if(result != UIImage()){
                                let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                }
                                else{
                                    FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                                }
                                imageForMedia = result
                            }
                            else{
                                imageForMedia = UIImage(named: "thumb12")!
                            }
                        })
                    }
                }
            }
            
            if(imageDataSource.count > 0 )
            {
                if(i < imageDataSource.count)
                {
                    self.selectedSharedChannelMediaSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.thumbImageKey:imageForMedia,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,infiniteScrollIdKey: self.imageDataSource[i][infiniteScrollIdKey]!,self.streamTockenKey:"",self.notificationKey:self.imageDataSource[i][self.notificationKey]!,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
                }
            }
        }
        
        if(imageDataSource.count > 0 )
        {
            if(selectedSharedChannelMediaSource.count > 0)
            {
                let type = selectedSharedChannelMediaSource[0][self.mediaTypeKey] as! String
                if type == "live"
                {
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    let currentDate = dateFormatter.stringFromDate(NSDate())
                    selectedSharedChannelMediaSource[0]["createdTime"] = currentDate
                }
            }
            if(selectedSharedChannelMediaSource.count > 0){
                selectedSharedChannelMediaSource.sortInPlace({ p1, p2 in
                    let time1 = p1["createdTime"] as! String
                    let time2 = p2["createdTime"] as! String
                    return time1 > time2
                })
            }
        }
        NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelMediaDetail", object: "success")
    }
}
