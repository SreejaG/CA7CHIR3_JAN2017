
import UIKit

class GlobalDataChannelList: NSObject {
    
    var globalChannelDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    //    var channelDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var channelDetailsDict : [[String:AnyObject]] = [[String:AnyObject]]()
    
    let channelDetailIdKey = "channel_detail_id"
    let mediaDetailIdKey = "media_detail_id"
    let channelNameKey = "channel_name"
    let totalMediaCountKey = "total_media_count"
    let createdTimeStampKey = "created_timeStamp"
    let sharedIndicatorOriginalKey = "orgSelected"
    let sharedIndicatorTemporaryKey = "tempSelected"
    let thumbImageKey = "thumbImage"
    let thumbImageURLKey = "thumbImage_URL"
    
    class var sharedInstance: GlobalDataChannelList
    {
        struct Singleton
        {
            static let instance = GlobalDataChannelList()
            private init() {}
        }
        return Singleton.instance
    }
    
    func initialise()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
    }
    
    func getChannelDetails(userName: String, token: String)
    {
        ChannelManager.sharedInstance.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
            //  self.authenticationFailureHandler(error, code: message)
            return
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            channelDetailsDict.removeAll()
            channelDetailsDict = json["channels"] as! [[String:AnyObject]]
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    //    func authenticationFailureHandler(error: NSError?, code: String)
    //    {
    //        print("message = \(code) andError = \(error?.localizedDescription) ")
    //
    //        if !RequestManager.sharedInstance.validConnection() {
    //            ErrorManager.sharedInstance.noNetworkConnection()
    //        }
    //        else if code.isEmpty == false {
    //
    //            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
    //            }
    //            else{
    //                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
    //            }
    //        }
    //        else{
    //            ErrorManager.sharedInstance.inValidResponseError()
    //        }
    //    }
    
    func setChannelDetails()
    {
        globalChannelDataSource.removeAll()
        
        for element in channelDetailsDict{
            let channelId = element["channel_detail_id"]?.stringValue
            var mediaId = String()
            var url = String()
            if let m =  element["media_detail_id"]?.stringValue
            {
                mediaId = m
                let thumbUrlBeforeNullChk = element["thumbnail_Url"] as! String
                url = nullToNil(thumbUrlBeforeNullChk) as! String
            }
            else{
                url = "empty"
            }
            let channelName = element["channel_name"] as! String
            let mediaSharedCount = element["total_no_media_shared"]?.stringValue
            let createdTime = element["last_updated_time_stamp"] as! String
            let sharedBool = Int(element["channel_shared_ind"] as! Bool)
            
            self.globalChannelDataSource.append([channelDetailIdKey: channelId!,channelNameKey: channelName,mediaDetailIdKey: mediaId,totalMediaCountKey: mediaSharedCount!,createdTimeStampKey: createdTime,self.sharedIndicatorOriginalKey: sharedBool,sharedIndicatorTemporaryKey: sharedBool, thumbImageURLKey: url])
            
            //            channelDataSource.append([channelDetailIdKey:channelId!, mediaDetailIdKey: mediaId, channelNameKey:channelName, totalMediaCountKey:mediaSharedCount!, createdTimeStampKey: createdTime,sharedIndicatorOriginalKey:sharedBool, sharedIndicatorTemporaryKey:sharedBool,thumbImageURLKey:url])
        }
        if(self.globalChannelDataSource.count > 0){
            sortChannelList()
            
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.downloadMediaFromGCS()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                })
            })
        }
    }
    
    func downloadMediaFromGCS(){
        var url: NSURL = NSURL()
        
        for var i = 0; i < globalChannelDataSource.count; i++
        {
            var imageForMedia : UIImage = UIImage()
            let mediaIdForFilePath = "\(globalChannelDataSource[i][mediaDetailIdKey] as! String)thumb"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                if let mediaUrl = globalChannelDataSource[i][thumbImageURLKey]
                {
                    url = convertStringtoURL(mediaUrl as! String)
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
                            imageForMedia =  UIImage(named: "thumb12")!
                        }
                    })
                }
                else{
                    imageForMedia =  UIImage(named: "thumb12")!
                }
            }
            self.globalChannelDataSource[i][thumbImageKey] = imageForMedia
            
            //            self.globalChannelDataSource.append([self.channelDetailIdKey: self.channelDataSource[i][channelDetailIdKey]!,self.channelNameKey: self.channelDataSource[i][self.channelNameKey]!,self.totalMediaCountKey: self.channelDataSource[i][self.totalMediaCountKey]!,createdTimeStampKey: channelDataSource[i][createdTimeStampKey]!,self.sharedIndicatorOriginalKey: self.channelDataSource[i][sharedIndicatorOriginalKey]!,self.sharedIndicatorTemporaryKey: self.channelDataSource[i][sharedIndicatorTemporaryKey]!,self.thumbImageKey: imageForMedia, self.thumbImageURLKey: self.channelDataSource[i][thumbImageURLKey]!])
        }
        //        sortChannelList()
    }
    
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
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
    }
    
    func sortChannelList(){
        globalChannelDataSource.sortInPlace({ p1, p2 in
            let time1 = p1[createdTimeStampKey] as! String
            let time2 = p2[createdTimeStampKey] as! String
            return time1 > time2
        })
        NSNotificationCenter.defaultCenter().postNotificationName("removeActivityIndicatorMyChannelList", object:nil)
        
        autoDownloadChannelDetails()
    }
    
    func autoDownloadChannelDetails()
    {
        GlobalChannelToImageMapping.sharedInstance.globalData(globalChannelDataSource)
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func enableDisableChannelList(dataSource : [[String:AnyObject]])  {
        for element in dataSource
        {
            let channelIdChk = element[channelDetailIdKey] as! String
            let sharedIndicator = element[sharedIndicatorTemporaryKey] as! Int
            for var i = 0; i < globalChannelDataSource.count;i++
            {
                let chanelId = globalChannelDataSource[i][channelDetailIdKey] as! String
                if channelIdChk == chanelId
                {
                    globalChannelDataSource[i][sharedIndicatorOriginalKey] = sharedIndicator
                    globalChannelDataSource[i][sharedIndicatorTemporaryKey] = sharedIndicator
                }
            }
        }
    }
    
}
