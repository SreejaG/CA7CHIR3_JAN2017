
import UIKit

class GlobalStreamList: NSObject {
    let actualImageKey = "actualImage"
    
    let userIdKey = "user_name"
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    let timeKey = ""
    let thumbImageKey = "thumbImage"
    let streamTockenKey = "wowza_stream_token"
    let imageKey = "image"
    let typeKey = "type"
    let imageType = "imageType"
    let timestamp = "last_updated_time_stamp"
    let channelIdkey = "ch_detail_id"
    let channelNameKey = "channel_name"
    let notificationKey = "notification"
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var GlobalStreamDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var operationQueue = NSOperationQueue()
    var operation2 : NSBlockOperation = NSBlockOperation()
    
    class var sharedInstance: GlobalStreamList
    {
        struct Singleton
        {
            static let instance = GlobalStreamList()
            private init() {
            }
        }
        return Singleton.instance
    }
    
    func cancelOperationQueue()
    {
        operationQueue.cancelAllOperations()
        operation2.cancel()
    }
    
    func initialiseCloudData( startOffset : Int ,endValueLimit :Int){
        imageDataSource.removeAll()
        GlobalStreamDataSource.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let startValue = "\(startOffset)"
        let endValueCount = String(endValueLimit)
        ImageUpload.sharedInstance.getSubscribedChannelMediaDetails(userId, accessToken: accessToken, limit: endValueCount, offset: startValue, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandlerStream(error, code: message)
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["objectJson"] as! [  AnyObject]
            if(responseArr.count == 0)
            {
                NSUserDefaults.standardUserDefaults().setValue("Empty", forKey: "EmptyMedia")
            }
            for index in 0 ..< responseArr.count
            {
                NSUserDefaults.standardUserDefaults().setValue("NotEmpty", forKey: "EmptyMedia")
                print(responseArr)
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let userid = responseArr[index].valueForKey(userIdKey) as! String
                let time = responseArr[index].valueForKey("last_updated_time_stamp") as! String
                let channelName =  responseArr[index].valueForKey("channel_name") as! String
                let channelIdSelected =  responseArr[index].valueForKey("channel_detail_id")?.stringValue
                let notificationType : String = "likes"
//                if let notifType =  responseArr[index].valueForKey("notification_type") as? String
//                {
//                    if notifType != ""
//                    {
//                        notificationType = notifType.lowercaseString
//                    }
//                    else{
//                        notificationType = "shared"
//                    }
//                }
//                else{
//                    notificationType = "shared"
//                }
               
                let actualUrlBeforeNullChk =  UrlManager.sharedInstance.getFullImageForStreamMedia(mediaId!)
                let actualUrl = nullToNil(actualUrlBeforeNullChk) as! String
                
                let mediaUrlBeforeNullChk =  UrlManager.sharedInstance.getMediaURL(mediaId!)
                let mediaUrl = nullToNil(mediaUrlBeforeNullChk) as! String
                let pulltorefreshId = responseArr[index].valueForKey(pullTorefreshKey)?.stringValue
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,userIdKey:userid,timestamp:time,channelNameKey:channelName, pullTorefreshKey : pulltorefreshId!, channelIdkey:channelIdSelected!,"createdTime":time])
            }
            if(imageDataSource.count > 0){
                operation2 = NSBlockOperation (block: {
                    self.downloadMediaFromGCS()
                })
                self.operationQueue.addOperation(operation2)
            }
            else{
                NSNotificationCenter.defaultCenter().postNotificationName("stream", object: "failure")
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func authenticationFailureHandlerStream(error: NSError?, code: String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("stream", object: "failure")
        if !RequestManager.sharedInstance.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                
            }
            else{
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
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
    
    func downloadMediaFromGCS(){
        for i in 0 ..< imageDataSource.count
        {
//            let mediaIdS = "\(imageDataSource[i][mediaIdKey] as! String)"
            if imageDataSource[i][mediaIdKey] != nil
            {
                var imageForMedia : UIImage = UIImage()
                let mediaIdForFilePath = "\(self.imageDataSource[i][self.mediaIdKey] as! String)thumb"
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                if fileExistFlag == true{
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                    imageForMedia = mediaImageFromFile!
                    if(self.imageDataSource.count > 0)
                    {
                        self.GlobalStreamDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.thumbImageKey:imageForMedia ,self.streamTockenKey:"",self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.userIdKey:self.imageDataSource[i][self.userIdKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,self.timestamp :self.imageDataSource[i][self.timestamp]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.channelNameKey:self.imageDataSource[i][self.channelNameKey]!,self.channelIdkey:self.imageDataSource[i][self.channelIdkey]!,pullTorefreshKey:self.imageDataSource[i][pullTorefreshKey] as! String,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
                    }
                }
                else{
                    if(imageDataSource.count > 0)
                    {
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
                                        imageForMedia = result
                                        if(self.imageDataSource.count > 0)
                                        {
                                            self.GlobalStreamDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.thumbImageKey:imageForMedia ,self.streamTockenKey:"",self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.userIdKey:self.imageDataSource[i][self.userIdKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,self.timestamp :self.imageDataSource[i][self.timestamp]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.channelNameKey:self.imageDataSource[i][self.channelNameKey]!,self.channelIdkey:self.imageDataSource[i][self.channelIdkey]!,pullTorefreshKey:self.imageDataSource[i][pullTorefreshKey] as! String,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
                                        }
                                        
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
            }
        }
        if(GlobalStreamDataSource.count > 0){
            GlobalStreamDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[timestamp] as! String
                let time2 = p2[timestamp] as! String
                return time1 > time2
            })
        }
        NSNotificationCenter.defaultCenter().postNotificationName("stream", object: "success")
    }
    
    func getPullToRefreshData()
    {
        imageDataSource.removeAll()
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        let sortList : Array = GlobalStreamList.sharedInstance.GlobalStreamDataSource
        var subIdArray : [Int] = [Int]()
        for i in 0  ..< sortList.count 
        {
            let subId = sortList[i][pullTorefreshKey] as! String
            subIdArray.append(Int(subId)!)
        }
        if(subIdArray.count > 0)
        {
            let subid = subIdArray.maxElement()!
            ChannelManager.sharedInstance.getUpdatedMediaDetails(userId, accessToken:accessToken,timestamp : "\(subid)",success: { (response) in
                self.authenticationSuccessHandler(response)
                
            }) { (error, message) in
                self.authenticationFailureHandlerStream(error, code: message)
            }
        }
    }
    
    func getMediaByOffset(subId : String)
    {
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        GlobalStreamList.sharedInstance.imageDataSource.removeAll()
        ChannelManager.sharedInstance.getOffsetMediaDetails(userId, accessToken:accessToken,timestamp : subId ,success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandlerStream(error, code: message)
        }
    }
}
