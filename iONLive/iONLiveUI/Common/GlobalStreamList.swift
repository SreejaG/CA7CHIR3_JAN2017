//
//  GlobalStreamList.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 7/22/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

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
    
    class var sharedInstance: GlobalStreamList
    {
        struct Singleton
        {
            static let instance = GlobalStreamList()
            private init() {}
            //This prevents others from using the default '()' initializer for this class.
        }
        return Singleton.instance
    }
    func initialiseCloudData( startOffset : Int ,endValueLimit :Int){
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let startValue = "\(startOffset)"
        let endValueCount = String(endValueLimit)
        ImageUpload.sharedInstance.getSubscribedChannelMediaDetails(userId, accessToken: accessToken, limit: endValueCount, offset: startValue, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
//            self.authenticationFailureHandler(error, code: message)
        }
    }
    
      func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            
            let responseArr = json["objectJson"] as! [AnyObject]
            print(responseArr)
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let userid = responseArr[index].valueForKey(userIdKey) as! String
                let time = responseArr[index].valueForKey("last_updated_time_stamp") as! String
                let channelName =  responseArr[index].valueForKey("channel_name") as! String
                let channelIdSelected =  responseArr[index].valueForKey("ch_detail_id")?.stringValue
                var notificationType : String = String()
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
                
                let actualUrlBeforeNullChk =  responseArr[index].valueForKey("gcs_object_name_SignedUrl")
                let actualUrl = nullToNil(actualUrlBeforeNullChk) as! String
                
                let mediaUrlBeforeNullChk =  responseArr[index].valueForKey("thumbnail_name_SignedUrl")
                let mediaUrl = nullToNil(mediaUrlBeforeNullChk) as! String
                let pulltorefreshId = responseArr[index].valueForKey(pullTorefreshKey)?.stringValue
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,userIdKey:userid,timestamp:time,channelNameKey:channelName, pullTorefreshKey : pulltorefreshId!, channelIdkey:channelIdSelected!,"createdTime":time])
            }
            
            if(imageDataSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    
                })
            }
            else{
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
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("stream", object: "failure")

        print("message = \(code) andError = \(error?.localizedDescription) ")
        
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
    
    func downloadMediaFromGCS(){
        //        self.dummy.removeAll()
        //        self
        //   print(dataSource[0][timestamp])
        
        for var i = 0; i < imageDataSource.count; i++
        {
            let mediaIdS = "\(imageDataSource[i][mediaIdKey] as! String)"
            if(mediaIdS != ""){
                var imageForMedia : UIImage = UIImage()
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
                
                
                //                    if contains(self.mediaIdKey, {contains(dataSource., self.imageDataSource[i][self.mediaIdKey])}) {
                //                    print("it is in there")
                //            }
                
                GlobalStreamDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.thumbImageKey:imageForMedia ,self.streamTockenKey:"",self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.userIdKey:self.imageDataSource[i][self.userIdKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,self.timestamp :self.imageDataSource[i][self.timestamp]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.channelNameKey:self.imageDataSource[i][self.channelNameKey]!,self.channelIdkey:self.imageDataSource[i][self.channelIdkey]!,pullTorefreshKey:self.imageDataSource[i][pullTorefreshKey] as! String,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
                //                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                //                        self.removeOverlay()
                //                       self.streamListCollectionView.reloadData()
                //                    })
            }

        }
        print(GlobalStreamDataSource.count)
        if(GlobalStreamDataSource.count > 0){
            GlobalStreamDataSource.sortInPlace({ p1, p2 in
                let time1 = p1[timestamp] as! String
                let time2 = p2[timestamp] as! String
                return time1 > time2
            })
        }
        print(GlobalStreamDataSource[0][timestamp])
        NSNotificationCenter.defaultCenter().postNotificationName("stream", object: "success")


    }
    func getUpdateData()
    {
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        let createdTimeStamp = GlobalStreamList.sharedInstance.GlobalStreamDataSource[0][pullTorefreshKey] as! String
        ChannelManager.sharedInstance.getUpdatedMediaDetails(userId, accessToken:accessToken,timestamp : "\(createdTimeStamp)",success: { (response) in
            self.authenticationSuccessHandler(response)
            
        }) { (error, message) in
//            self.authenticationFailureHandler(error, code: message)
        }
    }
    func getMediaByOffset()
    {
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        let createdTimeStamp = GlobalStreamList.sharedInstance.GlobalStreamDataSource[0][pullTorefreshKey] as! String
        ChannelManager.sharedInstance.getOffsetMediaDetails(userId, accessToken:accessToken,timestamp : "\(createdTimeStamp)",success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
//            self.authenticationFailureHandler(error, code: message)
        }

    }
}
