
import UIKit

class GlobalChannelToImageMapping: NSObject {
    
    var GlobalChannelImageDict : [String : [[String : AnyObject]]] =  [String : [[String : AnyObject]]]()
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    
    var channelImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var localDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var dummy: [[String:AnyObject]] = [[String:AnyObject]]()
    
    var channelId : String!
    var channelDetailId : String = String()
    
    var dataSourceCount : Int = 0
    
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
    let channelNameKey = "channel_name"
    let totalMediaCountKey = "total_media_count"
    let sharedIndicatorOriginalKey = "orgSelected"
    let sharedIndicatorTemporaryKey = "tempSelected"
    
    class var sharedInstance: GlobalChannelToImageMapping
    {
        struct Singleton
        {
            static let instance = GlobalChannelToImageMapping()
            private init() {}
        }
        return Singleton.instance
    }
    
    func globalData(source :[[String:AnyObject]])
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GlobalChannelToImageMapping.display), name: "success", object:nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GlobalChannelToImageMapping.mapNewMedias), name: "mapNewMedias", object:nil)
        
        dummy = source
        
        getMediaByChannelId()
    }
    
    func display(notif: NSNotification)
    {
        if (dataSourceCount < dummy.count - 1)
        {
            dataSourceCount  = dataSourceCount + 1
            
            getMediaByChannelId()
        }
        else if dataSourceCount == dummy.count - 1
        {
            let codeString = "Success"
            NSNotificationCenter.defaultCenter().postNotificationName("stopInitialising", object: codeString)
            NSNotificationCenter.defaultCenter().postNotificationName("mapNewMedias", object: nil)
        }
    }
    
    func getMediaByChannelId()
    {
        let totalMediaCount : Int = Int(dummy[dataSourceCount][self.totalMediaCountKey]  as! String)!
        let channelId : String =  dummy[dataSourceCount][self.channelDetailIdKey] as! String
        self.channelDetailId = channelId
        self.initialise(totalMediaCount, channelid: channelId)
    }
    
    func initialise(totalMediaCount : Int, channelid : String){
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        let startValue = "0"
        let endValue = String(totalMediaCount)
        
        channelDetailId = channelid
        
        if totalMediaCount <= 0
        {
            imageDataSource.removeAll()
            GlobalChannelImageDict.updateValue(imageDataSource, forKey: channelDetailId)
            NSNotificationCenter.defaultCenter().postNotificationName("success", object: channelDetailId)
        }
        else{
            
            ImageUpload.sharedInstance.getChannelMediaDetails(channelid , userName: userId, accessToken: accessToken, limit: endValue, offset: startValue, success: { (response) -> () in
                self.authenticationSuccessHandler(response,id: channelid)
            }) { (error, message) -> () in
                //   self.authenticationFailureHandler(error, code: message)
                return
            }
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?, id:String)
    {
        if let json = response as? [String: AnyObject]
        {
            imageDataSource.removeAll()
            let responseArr = json["MediaDetail"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let channelMediaDetailId = responseArr[index].valueForKey("channel_media_detail_id")?.stringValue
                let mediaUrlBeforeNullChk = responseArr[index].valueForKey("thumbnail_name_SignedUrl")
                let mediaUrl = nullToNil(mediaUrlBeforeNullChk) as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrlBeforeNullChk =  responseArr[index].valueForKey("gcs_object_name_SignedUrl")
                let actualUrl = nullToNil(actualUrlBeforeNullChk) as! String
                let notificationType : String = "likes"
                let time = responseArr[index].valueForKey("created_time_stamp") as! String
                
                imageDataSource.append([mediaDetailIdKey:mediaId!,channelMediaDetailIdKey:channelMediaDetailId!, thumbImageURLKey:mediaUrl,fullImageURLKey:actualUrl,mediaTypeKey:mediaType, notificationTypeKey:notificationType, createdTimeStampKey:time, uploadProgressKey:0.0])
            }
            
            if(imageDataSource.count > 0){
                imageDataSource.sortInPlace({ p1, p2 in
                    let time1 = Int(p1[mediaDetailIdKey] as! String)
                    let time2 = Int(p2[mediaDetailIdKey] as! String)
                    return time1 > time2
                })
                
                GlobalChannelImageDict.updateValue(imageDataSource, forKey: channelDetailId)
                NSNotificationCenter.defaultCenter().postNotificationName("success", object: self.channelDetailId)
            }
        }
    }
    
    func downloadMediaFromGCS(chanelId: String, start: Int, end:Int){
        localDataSource.removeAll()
        for var i = start; i < end; i++
        {
            localDataSource.append(GlobalChannelImageDict[chanelId]![i])
        }
        print("localdata \(localDataSource)")
        for var k = 0; k < localDataSource.count; k++
        {
            var imageForMedia : UIImage = UIImage()
            let mediaId = String(localDataSource[k][mediaDetailIdKey]!)
            let mediaIdForFilePath = "\(mediaId)thumb"
//            print(mediaIdForFilePath)
            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
            if fileExistFlag == true{
                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                imageForMedia = mediaImageFromFile!
            }
            else{
                let mediaUrl = localDataSource[k][thumbImageURLKey] as! String
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
            localDataSource[k][thumbImageKey] = imageForMedia
        }
        
        for var j = 0; j < GlobalChannelImageDict[chanelId]!.count; j++
        {
            let mediaIdChk = GlobalChannelImageDict[chanelId]![j][mediaDetailIdKey] as! String
            var chkFlag = false
            for element in localDataSource
            {
                let mediaIdFromLocal = element[mediaDetailIdKey] as! String
                if mediaIdChk == mediaIdFromLocal
                {
                   GlobalChannelImageDict[chanelId]![j][thumbImageKey] = element[thumbImageKey] as! UIImage
                }
            }
        }
            
    NSNotificationCenter.defaultCenter().postNotificationName("removeActivityIndicatorMyChannel", object:nil)
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
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    //add medias to channels when user capture an image
    func mapNewMedias(notif: NSNotification)
    {
        //captured media details in an array
        var localMediasForMapping = MediaBeforeUploadComplete.sharedInstance.dataSourceFromLocal
        
        var totalCount = 0
        if localMediasForMapping.count > 0
        {
            let globalChannelKeys = NSMutableArray()
            
            //store channel ids from global data channel list(my channel)
            for var k = 0; k < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count; k++
            {
                globalChannelKeys.addObject(GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][channelDetailIdKey] as! String)
            }
            
            var channelMediaDataSource : [[String:AnyObject]] = [[String:AnyObject]]()
            
            // channel ids from global channel image mapping data sources
            var channelMediaKeys : Array = Array(GlobalChannelImageDict.keys)
            
            var sharedFlag = false
            var indexOfI = 0
            
            //loop through the global data channel list data source
            for var j = 0; j < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count; j++
            {
                let chanId = GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][channelDetailIdKey] as! String
                
                // shared ind to check new media is share or not to the channel
                let sharedInd = GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][sharedIndicatorOriginalKey] as! Bool
                
                let chanName = GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][channelNameKey] as! String
                
                channelMediaDataSource.removeAll()
                
                //if channel already contain medias it is stored to local media array
                if channelMediaKeys.contains(chanId){
                    channelMediaDataSource = GlobalChannelImageDict[chanId]!
                }
                
                //check shared indicator true or channel name is archive map the newly captured  medias
                if(sharedInd == true || chanName == "Archive")
                {
                    totalCount = Int(GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][totalMediaCountKey] as! String)! + localMediasForMapping.count
                    
                    for element in localMediasForMapping
                    {
                        channelMediaDataSource.append(element)
                    }
                }
                else{
                    totalCount = Int(GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][totalMediaCountKey] as! String)!
                }
                
                //sort
                channelMediaDataSource.sortInPlace({ p1, p2 in
                    let time1 = Int(p1[mediaDetailIdKey] as! String)
                    let time2 = Int(p2[mediaDetailIdKey] as! String)
                    return time1 > time2
                })
                
                //update latest thumbnail and total count in global channel list data source
                let totalNumOfMedias = totalCount
                if channelMediaDataSource.count > 0
                {
                    let mediaIdForFilePath = "\(channelMediaDataSource[0][mediaDetailIdKey] as! String)thumb"
                    let thumbUrl = channelMediaDataSource[0][thumbImageURLKey] as! String
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][thumbImageURLKey] = thumbUrl
                    GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][thumbImageKey] = downloadLatestMedia(mediaIdForFilePath,thumbURL: thumbUrl)
                    
                    //update the latest mediaid details with the global channel image mapping data source
                    GlobalChannelImageDict.updateValue(channelMediaDataSource, forKey: chanId)
                }
                
                GlobalDataChannelList.sharedInstance.globalChannelDataSource[j][totalMediaCountKey] = "\(totalNumOfMedias)"
                
                channelMediaDataSource.removeAll()
                totalCount = 0
            }
            GlobalDataChannelList.sharedInstance.globalChannelDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[createdTimeStampKey] as! String
                let time2 = p2[createdTimeStampKey] as! String
                return time1 > time2
            })
            MediaBeforeUploadComplete.sharedInstance.dataSourceFromLocal.removeAll()
            localMediasForMapping.removeAll()
        }
    }
    
    // Add media from one channel to other channels
    
    func addMediaToChannel(channelSelectedDict: [[String:AnyObject]],  mediaDetailOfSelectedChannel : [[String:AnyObject]])
    {
        let channelKeys : NSMutableArray = NSMutableArray()
        
        var numberofMediasAddedCount = 0
        
        //channel ids to add new medias
        
        for var k = 0; k < channelSelectedDict.count; k++ {
            channelKeys.addObject(channelSelectedDict[k][channelDetailIdKey] as! String)
        }
        
        var channelMediaDataSource : [[String:AnyObject]] = [[String:AnyObject]]()
        
        //channel ids from globa channel image mapping data source
        
        let channelMediaKeys : Array = Array(GlobalChannelImageDict.keys)
        
        //loop through the channel ids in which medias are to added
        
        for var i = 0; i < channelKeys.count; i++
        {
            var chkFlag = false
            var dataRow : [String: AnyObject] = [String:AnyObject]()
            
            var channelId = channelKeys[i] as! String
            
            //check the channel already contain images
            
            if channelMediaKeys.contains(channelId){
                channelMediaDataSource = GlobalChannelImageDict[channelId]!
                
                //loop throgh the media details which are to to be added
                for element in mediaDetailOfSelectedChannel
                {
                    //each element is stored
                    dataRow = element
                    
                    let mediaIdChk = element[mediaDetailIdKey] as! String
                    
                    //loop through the media detail array from global channel to image mapping data source
                    for elementGlob in channelMediaDataSource
                    {
                        let mediaId = elementGlob[mediaDetailIdKey] as! String
                        
                        //check medai exists
                        
                        if mediaIdChk == mediaId
                        {
                            chkFlag = true
                            break
                        }
                        else{
                            chkFlag = false
                        }
                    }
                    
                    //if media is not in the media detail array add it
                    if chkFlag == false
                    {
                        numberofMediasAddedCount = numberofMediasAddedCount + 1
                        channelMediaDataSource.append(dataRow)
                    }
                }
            }
                
                //channel is newly created no medias
            else{
                for element in mediaDetailOfSelectedChannel
                {
                    numberofMediasAddedCount = numberofMediasAddedCount + 1
                    channelMediaDataSource.append(element)
                }
            }
            
            //sort
            channelMediaDataSource.sortInPlace({ p1, p2 in
                let time1 = Int(p1[mediaDetailIdKey] as! String)
                let time2 = Int(p2[mediaDetailIdKey] as! String)
                return time1 > time2
            })
            
            //update the global channel image mapping data source with new details
            GlobalChannelImageDict.updateValue(channelMediaDataSource, forKey: channelKeys[i] as! String)
            
            //loop through the channel list array to update total count and latest thumbnail after deletion complete
            for var k = 0; k < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count; k++
            {
                let chanIdChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][channelDetailIdKey] as! String
                
                //check the channel id exists in the channel list array
                
                if chanIdChk == channelId
                {
                    let totalCountBeforeDelete = Int(GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][totalMediaCountKey] as! String)
                    let totalNumOfMedias = totalCountBeforeDelete! + numberofMediasAddedCount
                    
                    //if media array contains atleast one element
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
            GlobalDataChannelList.sharedInstance.globalChannelDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[createdTimeStampKey] as! String
                let time2 = p2[createdTimeStampKey] as! String
                return time1 > time2
            })
            channelMediaDataSource.removeAll()
            numberofMediasAddedCount = 0
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
    
    // delete media from Channel
    
    func deleteMediasFromChannel(channelId: String, mediaIds: NSMutableArray)
    {
        let archiveChannelId = NSUserDefaults.standardUserDefaults().valueForKey(archiveId) as! Int
        
        // check channel is archive
        if channelId == "\(archiveChannelId)"
        {
            deleteMediasFromAllChannels(channelId, mediaIds: mediaIds)
        }
        else{
            deleteMediaFromParticularChannel(channelId)
        }
    }
    
    //delete media from a single channel
    
    func deleteMediaFromParticularChannel(channelId: String)
    {
        var channelMediaDataSource : [[String:AnyObject]] = [[String:AnyObject]]()
        
        //All medias in the selected channel to a media array
        channelMediaDataSource = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!
        
        
        //loop through the channel list array to update total count and latest thumbnail after deletion complete
        for var k = 0; k < GlobalDataChannelList.sharedInstance.globalChannelDataSource.count; k++
        {
            let chanIdChk = GlobalDataChannelList.sharedInstance.globalChannelDataSource[k][channelDetailIdKey] as! String
            
            //check the channel id exists in the channel list array
            if chanIdChk == channelId
            {
                let totalNumOfMedias = channelMediaDataSource.count
                
                //if media array contains atleast one element
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
    }
    
    //deleting from archive needs to delete medias from all channels
    func deleteMediasFromAllChannels(chanelId : String,mediaIds: NSMutableArray)
    {
        
        //all channelIds from global channel image mapping data source to a channelids array
        let channelIds : Array = Array(GlobalChannelImageDict.keys)
        
        var channelMediaDataSource : [[String:AnyObject]] = [[String:AnyObject]]()
        var index = 0
        var selectedIndex : [Int] = [Int]()
        var selectedIndexForArchive : [Int] = [Int]()
        
        //loop through the channelIds array
        for var mainIndex = 0; mainIndex < channelIds.count; mainIndex++
        {
            let chanID = channelIds[mainIndex]
            
            //store the medias of a particular channel to a media array
            channelMediaDataSource = GlobalChannelImageDict[chanID]!
            
            if(channelId != chanID)
            {
                //loop through the media ids which are to be deleted
                for var i = 0; i < mediaIds.count; i++
                {
                    let mediaIdDelete = mediaIds[i] as! String
                    var chkFlag = false
                    
                    //loop through the media array
                    for var j = 0; j < channelMediaDataSource.count; j++
                    {
                        index = j
                        let mediaIdChk = channelMediaDataSource[j][mediaDetailIdKey] as! String
                        
                        //check media exist in the media array
                        if mediaIdDelete == mediaIdChk
                        {
                            chkFlag = true
                            break
                        }
                    }
                    
                    //save the media array index to another array for removing
                    if chkFlag == true
                    {
                        selectedIndex.append(index)
                    }
                }
                
                //loop through the indexes and remove the media from media array
                
                if selectedIndex.count > 0
                {
                    selectedIndex = selectedIndex.sort()
                    for var i = 0;i < selectedIndex.count; i++
                    {
                        let indexToDelete = selectedIndex[i] - i
                        channelMediaDataSource.removeAtIndex(indexToDelete)
                    }
                    
                    //sort
                    channelMediaDataSource.sortInPlace({ p1, p2 in
                        let time1 = Int(p1[mediaDetailIdKey] as! String)
                        let time2 = Int(p2[mediaDetailIdKey] as! String)
                        return time1 > time2
                    })
                    
                    //update the global image datasource with medias and channel id
                    GlobalChannelImageDict.updateValue(channelMediaDataSource, forKey: chanID)
                }
            }
            
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
            selectedIndex.removeAll()
            index = 0
        }
        
        //delete the medias from Global data retriever data source(photoviewer)
        
        //loop through mediaids which are to be deleted
        for var i = 0; i < mediaIds.count; i++
        {
            var chkFlag = false
            let mediaIdDelete = mediaIds[i] as! String
            
            //loop through the global data retriever data source
            for var k = 0; k < GlobalDataRetriever.sharedInstance.globalDataSource.count; k++
            {
                index = k
                let mediaIdChk = GlobalDataRetriever.sharedInstance.globalDataSource[k][mediaDetailIdKey] as! String
                
                //check media exists
                if mediaIdDelete == mediaIdChk
                {
                    chkFlag = true
                    break
                }
            }
            
            //save index to another array
            if chkFlag == true
            {
                selectedIndexForArchive.append(index)
            }
        }
        
        //loop through the indexes and remove the media from globa data retriever data source
        selectedIndexForArchive = selectedIndexForArchive.sort()
        for var i = 0;i < selectedIndexForArchive.count; i++
        {
            let indexToDelete = selectedIndexForArchive[i] - i
            GlobalDataRetriever.sharedInstance.globalDataSource.removeAtIndex(indexToDelete)
        }
        
        //sort
        GlobalDataRetriever.sharedInstance.globalDataSource.sortInPlace({ p1, p2 in
            let time1 = Int(p1[mediaDetailIdKey] as! String)
            let time2 = Int(p2[mediaDetailIdKey] as! String)
            return time1 > time2
        })
        
        //update new archive count
        NSUserDefaults.standardUserDefaults().setInteger(GlobalDataRetriever.sharedInstance.globalDataSource.count, forKey: ArchiveCount)
    }
    
    //    func authenticationFailureHandler(error: NSError?, code: String)
    //    {
    //        //removeOverlay()
    //        NSNotificationCenter.defaultCenter().postNotificationName("success", object: id)
    //        GlobalChannelImageDict.updateValue(GlobalChannelImageDataSource, forKey: id)
    //        print("message = \(code) andError = \(error?.localizedDescription) ")
    //
    //        if !RequestManager.sharedInstance.validConnection() {
    //            ErrorManager.sharedInstance.noNetworkConnection()
    //        }
    //        else if code.isEmpty == false {
    //
    //            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
    //             //   loadInitialViewController(code)
    //            }
    //            else{
    //                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
    //            }
    //        }
    //        else{
    //            ErrorManager.sharedInstance.inValidResponseError()
    //        }
    //    }
    
    
}
