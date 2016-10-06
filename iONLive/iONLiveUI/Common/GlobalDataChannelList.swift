
import UIKit

class GlobalDataChannelList: NSObject {
    
    var globalChannelDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var channelDetailsDict : [[String:AnyObject]] = [[String:AnyObject]]()
    
    var operationQueueObjInChannelList = NSOperationQueue()
    var operationInChannelList = NSBlockOperation()
    
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
            self.authenticationFailureHandlerChannel(error, code: message)
            
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
    
    func authenticationFailureHandlerChannel(error: NSError?, code: String)
    {
        var codeString : String = String()
        
        if !RequestManager.sharedInstance.validConnection() {
            codeString = "noNetwork"
        }
        else if code.isEmpty == false {
            codeString = code
        }
        else{
            if(UIApplication.sharedApplication().applicationState == .Inactive)
            {
                codeString = "Nothing"
            }
            else{
                codeString = "ResponseError"
            }
        }
        NSNotificationCenter.defaultCenter().postNotificationName("stopInitialising", object: codeString)
    }
    
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
            
            self.globalChannelDataSource.append([channelIdKey: channelId!,channelNameKey: channelName,mediaIdKey: mediaId,totalMediaKey: mediaSharedCount!,createdTimeKey: createdTime,sharedOriginalKey: sharedBool,sharedTemporaryKey: sharedBool, tImageURLKey: url])
        }
        
        if(self.globalChannelDataSource.count > 0){
            sortChannelList()
            operationInChannelList  = NSBlockOperation (block: {
                self.downloadMediaFromGCS()
            })
            self.operationQueueObjInChannelList.addOperation(operationInChannelList)
        }
    }
    
    func downloadMediaFromGCS(){
        var url: NSURL = NSURL()
        for i in 0 ..< globalChannelDataSource.count
        {
            var imageForMedia : UIImage = UIImage()
            let mediaIdForFilePath = "\(globalChannelDataSource[i][mediaIdKey] as! String)thumb"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                if let mediaUrl = globalChannelDataSource[i][tImageURLKey]
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
            self.globalChannelDataSource[i][tImageKey] = imageForMedia
        }
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
    
    func sortChannelList(){
        globalChannelDataSource.sortInPlace({ p1, p2 in
            let time1 = p1[createdTimeKey] as! String
            let time2 = p2[createdTimeKey] as! String
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
            let channelIdChk = element[channelIdKey] as! String
            let sharedIndicator = element[sharedTemporaryKey] as! Int
            for i in 0 ..< globalChannelDataSource.count
            {
                let chanelId = globalChannelDataSource[i][channelIdKey] as! String
                if channelIdChk == chanelId
                {
                    globalChannelDataSource[i][sharedOriginalKey] = sharedIndicator
                    globalChannelDataSource[i][sharedTemporaryKey] = sharedIndicator
                }
            }
        }
    }
    
}
