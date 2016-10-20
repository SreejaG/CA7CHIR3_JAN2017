
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
    var userName:String!
    var channelName :String = String()
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
                ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
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
                ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
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
            ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
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
        ImageUpload.sharedInstance.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: "27", offset: "0", success: { (response) -> () in
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
                
                print(responseArr)
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let infiniteScrollId  = responseArr[index].valueForKey("channel_media_detail_id")?.stringValue
                var notificationType : String = " likes"
                let time = responseArr[index].valueForKey("created_time_stamp") as! String
                let actualUrl =  UrlManager.sharedInstance.getFullImageForStreamMedia(mediaId!)
                let mediaUrl =  UrlManager.sharedInstance.getMediaURL(mediaId!)
                
                var vDuration = String()
                
                if(mediaType == "video"){
                    let videoDurationStr = responseArr[index].valueForKey("video_duration") as! String
                    vDuration = FileManagerViewController.sharedInstance.getVideoDurationInProperFormat(videoDurationStr)
                }
                else{
                    vDuration = ""
                }
              
                imageDataSource.append([stream_mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, stream_mediaTypeKey:mediaType,actualImageKey:actualUrl,infiniteScrollIdKey: infiniteScrollId!,notificationKey:notificationType,"createdTime":time,videoDurationKey:vDuration])
            }
            
            let responseArrLive = json["LiveDetail"] as! [AnyObject]
            
            for liveIndex in 0  ..< responseArrLive.count 
            {
                let streamTocken = responseArrLive[liveIndex].valueForKey("wowza_stream_token")as! String
                let mediaId = responseArrLive[liveIndex].valueForKey("live_stream_detail_id")?.stringValue
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                dateFormatter.timeZone = NSTimeZone(name: "UTC")
                let currentDate = dateFormatter.stringFromDate(NSDate())
                var notificationType : String = ""
                let mediaUrl =  UrlManager.sharedInstance.getLiveThumbUrlApi(mediaId!)
                var vDuration = String()
                vDuration = ""
                if(mediaUrl != ""){
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                        if(self.selectedSharedChannelMediaSource.count > 0)
                        {
                            if (self.selectedSharedChannelMediaSource[0][stream_mediaTypeKey] as! String != "live")
                            {
                                self.selectedSharedChannelMediaSource.insert([stream_mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, stream_thumbImageKey:result ,stream_streamTockenKey:streamTocken,actualImageKey:mediaUrl,notificationKey:notificationType,stream_mediaTypeKey:"live",infiniteScrollIdKey: "", userIdKey:self.userName, stream_channelNameKey:self.channelName,"createdTime":currentDate,videoDurationKey:vDuration], atIndex: 0)
                            }
                        }
                        else{
                            self.selectedSharedChannelMediaSource.insert([stream_mediaIdKey:mediaId!, mediaUrlKey:mediaUrl,stream_thumbImageKey:result ,stream_streamTockenKey:streamTocken,actualImageKey:mediaUrl,notificationKey:notificationType,stream_mediaTypeKey:"live",infiniteScrollIdKey: "", userIdKey:self.userName, stream_channelNameKey:self.channelName,"createdTime":currentDate,videoDurationKey:vDuration], atIndex: 0)
                        }
                        NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelMediaDetail", object: "success")
                    })
                }
            }
            
            if(imageDataSource.count > 0){
                if(self.selectedSharedChannelMediaSource.count > 0)
                {
                }
                
                let operation2 : NSBlockOperation = NSBlockOperation (block: {
                    self.downloadMediaFromGCS()
                })
                self.operationQueue.addOperation(operation2)
            }
            else{
                NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelMediaDetail", object: "failure")
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
                else{
                    
                    mediaImage = UIImage(named: "thumb12")!
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
        for i in 0 ..< imageDataSource.count
        {
            var imageForMedia : UIImage = UIImage()
            if(imageDataSource.count > 0 && imageDataSource.count > i)
            {
                let mediaIdForFilePath = "\(imageDataSource[i][stream_mediaIdKey] as! String)thumb"
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
                    self.selectedSharedChannelMediaSource.append([stream_mediaIdKey:self.imageDataSource[i][stream_mediaIdKey]!, mediaUrlKey:imageForMedia,stream_mediaTypeKey:self.imageDataSource[i][stream_mediaTypeKey]!,stream_thumbImageKey:imageForMedia,actualImageKey:self.imageDataSource[i][actualImageKey]!,infiniteScrollIdKey: self.imageDataSource[i][infiniteScrollIdKey]!,stream_streamTockenKey:"",notificationKey:self.imageDataSource[i][notificationKey]!,"createdTime":self.imageDataSource[i]["createdTime"] as! String,                videoDurationKey:self.imageDataSource[i][videoDurationKey] as! String])
                }
            }
        }
        
        if(imageDataSource.count > 0 )
        {
            if(selectedSharedChannelMediaSource.count > 0)
            {
                let type = selectedSharedChannelMediaSource[0][stream_mediaTypeKey] as! String
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
