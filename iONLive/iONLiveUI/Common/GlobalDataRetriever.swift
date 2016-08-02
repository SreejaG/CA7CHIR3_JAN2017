
import UIKit

class GlobalDataRetriever: NSObject
{
    class var sharedInstance: GlobalDataRetriever
    {
        struct Singleton
        {
            static let instance = GlobalDataRetriever()
            private init() {}
        }
        return Singleton.instance
    }
    
    let mediaDetailIdKey = "media_detail_id"
    let thumbImageURLKey = "thumbImage_URL"
    let fullImageURLKey = "fullImage_URL"
    let thumbImageKey = "thumbImage"
    let notificationTypeKey = "notification_type"
    let createdTimeStampKey = "created_timeStamp"
    let mediaTypeKey = "media_type"
    let uploadProgressKey = "upload_progress"
    let channelMediaDetailIdKey = "channel_media_detail_id"
    let channelDetailIdKey = "channel_detail_id"
    let totalMediaCountKey = "total_media_count"
    
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var userName : String = String()
    var accessToken : String = String()
    
    var globalDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    func initialise()
    {
        userName = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getMediaFromCloud()
    }
    
    func getMediaFromCloud()
    {
        let channelId = defaults.valueForKey(archiveId) as! Int
        let archiveMeidaCount = defaults.valueForKey(ArchiveCount) as! Int
    
        ImageUpload.sharedInstance.getChannelMediaDetails("\(channelId)" , userName: userName, accessToken: accessToken, limit: "\(archiveMeidaCount)", offset: "0", success: { (response) -> () in
            self.authenticationSuccessHandlerForFetchMedia(response)
        }) { (error, message) -> () in
            return
            // self.authenticationFailureHandlerForFetchMedia(error, code: message)
        }
    }
    
    func authenticationSuccessHandlerForFetchMedia(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
            globalDataSource.removeAll()
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrlBeforeNullChk = responseArr[index].valueForKey("thumbnail_name_SignedUrl")
                let mediaUrl = nullToNil(mediaUrlBeforeNullChk) as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrlBeforeNullChk =  responseArr[index].valueForKey("gcs_object_name_SignedUrl")
                let actualUrl = nullToNil(actualUrlBeforeNullChk) as! String
                let notificationType : String = "likes"
                let time = responseArr[index].valueForKey("created_time_stamp") as! String
                let channelMediaDetailId = responseArr[index].valueForKey("channel_media_detail_id")?.stringValue
                
                globalDataSource.append([mediaDetailIdKey:mediaId!,channelMediaDetailIdKey:channelMediaDetailId!, thumbImageURLKey:mediaUrl,fullImageURLKey:actualUrl,mediaTypeKey:mediaType, notificationTypeKey:notificationType, createdTimeStampKey:time, uploadProgressKey:0.0])
            }
        }
   
        if(globalDataSource.count > 0)
        {
            globalDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[createdTimeStampKey] as! String
                let time2 = p2[createdTimeStampKey] as! String
                return time1 > time2
            })
            
            let start = 0
            var end = 0
            if globalDataSource.count > 10
            {
                end = 10
            }
            else{
                end = globalDataSource.count
            }
            
            let qualityOfServiceClass = QOS_CLASS_BACKGROUND
            let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
            dispatch_async(backgroundQueue, {
                self.downloadMediaFromGCS(start,end: end)
            })
        }
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func downloadMediaFromGCS(start:Int, end:Int)
    {
        for(var i = start; i < end; i++)
        {
            var imageForMedia : UIImage = UIImage()
            let id = String(globalDataSource[i][mediaDetailIdKey]!)
            let mediaIdForFilePath = "\(id))thumb"
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                let mediaUrl = globalDataSource[i][thumbImageURLKey] as! String
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
            globalDataSource[i][thumbImageKey] = imageForMedia
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("removeActivityIndicatorMyMedia", object:nil)
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
    
    func deleteMediasOnGlobalMyMediaDeletionAction(mediaId: String){
        
        //all channelIds from global channel image mapping data source to a channelids array
        let channelIds : Array = Array(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.keys)
        
        var channelMediaDataSource : [[String:AnyObject]] = [[String:AnyObject]]()
        var index = 0
        var selectedIndex : Int = -1
        var chkFlag = false
        
        //loop through the channelIds array
        for var mainIndex = 0; mainIndex < channelIds.count; mainIndex++
        {
            let chanID = channelIds[mainIndex]
            
            //store the medias of a particular channel to a media array
            channelMediaDataSource = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[chanID]!
            
            //loop through the media array
            for var j = 0; j < channelMediaDataSource.count; j++
            {
                index = j
                let mediaIdChk = channelMediaDataSource[j][mediaDetailIdKey] as! String
                        
                //check media exist in the media array
                if mediaId == mediaIdChk
                {
                    chkFlag = true
                    break
                }
            }
            
            //save the media array index to another array for removing
            if chkFlag == true
            {
                selectedIndex = index
            }
                
            //loop through the indexes and remove the media from media array
            if selectedIndex != -1
            {
                channelMediaDataSource.removeAtIndex(selectedIndex)
            }
            
            //sort
            channelMediaDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[createdTimeStampKey] as! String
                let time2 = p2[createdTimeStampKey] as! String
                return time1 > time2
            })
                    
            //update the global image datasource with medias and channel id
            GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.updateValue(channelMediaDataSource, forKey: chanID)

            //loop through the channel list array to update total count and latest thumbnail after deletion complete
            
            for var k = 0; k < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count; k++
            {
                let chanIdChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][channelDetailIdKey] as! String
                
                //check channel id exists
                if chanIdChk == chanID
                {
                    let totalNumOfMedias = channelMediaDataSource.count
                    if channelMediaDataSource.count > 0
                    {
                        let mediaIdForFilePath = "\(channelMediaDataSource[0][mediaDetailIdKey] as! String)thumb"
                        let thumbUrl = channelMediaDataSource[0][thumbImageURLKey] as! String
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][thumbImageURLKey] = thumbUrl
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][thumbImageKey] = downloadLatestMedia(mediaIdForFilePath,thumbURL: thumbUrl)
                    }
                    else{
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][thumbImageURLKey] = "empty"
                        GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][thumbImageKey] =  UIImage(named: "thumb12")
                    }
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][totalMediaCountKey] = "\(totalNumOfMedias)"
                }
            }
            channelMediaDataSource.removeAll()
            selectedIndex = -1
            chkFlag = false
            index = 0
        }
     }
    
    func downloadLatestMedia(mediaIdForFilePath: String, thumbURL : String) -> UIImage
    {
        var imageForMedia : UIImage = UIImage()
        let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
        let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
        let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
        if fileExistFlag == true{
            let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
            imageForMedia = mediaImageFromFile!
        }
        else{
            if(thumbURL != ""){
                let url = convertStringtoURL(thumbURL)
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
        }
        
        return imageForMedia
    }
    
    
    //    func authenticationFailureHandlerForFetchMedia(error: NSError?, code: String)
    //    {
    //        print("message = \(code) andError = \(error?.localizedDescription) ")
    //        if !self.requestManager.validConnection() {
    //            ErrorManager.sharedInstance.noNetworkConnection()
    //        }
    //        else if code.isEmpty == false {
    //            ErrorManager.sharedInstance.inValidResponseError()
    //        }
    //    }
    
}


