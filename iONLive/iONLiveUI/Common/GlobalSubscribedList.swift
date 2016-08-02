//
//  GlobalSubscribedList.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 7/22/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class GlobalSubscribedList: NSObject {

//    
//    func initialiseCloudData(){
//        
//        let defaults = NSUserDefaults .standardUserDefaults()
//        let userId = defaults.valueForKey(userLoginIdKey) as! String
//        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
//        showOverlay()
//        
//        let offsetString : String = String(offsetToInt)
//        
//        imageUploadManger.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) -> () in
//            self.authenticationSuccessHandler(response)
//        }) { (error, message) -> () in
//            self.authenticationFailureHandler(error, code: message)
//        }
//    }
//    func authenticationSuccessHandler(response:AnyObject?)
//    {
//        //        removeOverlay()
//        isWatchedTrue()
//        if let json = response as? [String: AnyObject]
//        {
//            let responseArr = json["MediaDetail"] as! [AnyObject]
//            
//            for index in 0 ..< responseArr.count
//            {
//                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
//                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
//                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
//                let actualUrl =  responseArr[index].valueForKey("gcs_object_name_SignedUrl") as! String
//                var notificationType : String = String()
//                let time = responseArr[index].valueForKey("created_time_stamp") as! String
//                if let notifType =  responseArr[index].valueForKey("notification_type") as? String
//                {
//                    if notifType != ""
//                    {
//                        notificationType = (notifType as? String)!.lowercaseString
//                    }
//                    else{
//                        notificationType = "shared"
//                    }
//                }
//                else{
//                    notificationType = "shared"
//                }
//                
//                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,"createdTime":time])
//            }
//            let responseArrLive = json["LiveDetail"] as! [AnyObject]
//            
//            for index in 0 ..< responseArrLive.count
//            {
//                
//                let streamTocken = responseArrLive[index].valueForKey("wowza_stream_token")as! String
//                let mediaUrl = responseArrLive[index].valueForKey("signedUrl") as! String
//                let mediaId = responseArrLive[index].valueForKey("live_stream_detail_id")?.stringValue
//                if(mediaUrl != ""){
//                    let url: NSURL = convertStringtoURL(mediaUrl)
//                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
//                        self.fullImageDataSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:mediaUrl, self.thumbImageKey:result ,self.streamTockenKey:streamTocken,self.actualImageKey:mediaUrl,self.notificationKey:self.imageDataSource[index][self.notificationKey]!,self.mediaTypeKey:"live", self.userIdKey:self.userName, self.channelNameKey:self.channelName])
//                        self.channelItemsCollectionView.reloadData()
//                    })
//                }
//            }
//            
//            if(imageDataSource.count > 0){
//                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//                dispatch_async(backgroundQueue, {
//                    self.downloadMediaFromGCS()
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        self.channelItemsCollectionView.reloadData()
//                    })
//                })
//            }
//            
//        }
//        else
//        {
//            ErrorManager.sharedInstance.inValidResponseError()
//        }
//    }
//    
//    func authenticationFailureHandler(error: NSError?, code: String)
//    {
//        removeOverlay()
//        if(offsetToInt <= totalMediaCount){
//            print("message = \(code) andError = \(error?.localizedDescription) ")
//            
//            if !self.requestManager.validConnection() {
//                ErrorManager.sharedInstance.noNetworkConnection()
//            }
//            else if code.isEmpty == false {
//                //                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
//                if((code == "USER004") || (code == "USER005") || (code == "USER006")){
//                    loadInitialViewController(code)
//                }
//            }
//            else{
//                ErrorManager.sharedInstance.inValidResponseError()
//            }
//        }
//    }
//    
//    func convertStringtoURL(url : String) -> NSURL
//    {
//        let url : NSString = url
//        let searchURL : NSURL = NSURL(string: url as String)!
//        return searchURL
//    }
//    func downloadMediaFromGCS(){
//        for var i = 0; i < imageDataSource.count; i++
//        {
//            
//            var imageForMedia : UIImage = UIImage()
//            let mediaIdForFilePath = "\(imageDataSource[i][mediaIdKey] as! String)thumb"
//            let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
//            let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
//            let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
//            if fileExistFlag == true{
//                let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
//                imageForMedia = mediaImageFromFile!
//            }
//            else{
//                let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
//                if(mediaUrl != ""){
//                    let url: NSURL = convertStringtoURL(mediaUrl)
//                    downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
//                        
//                        if(result != UIImage()){
//                            let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
//                            let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
//                            let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
//                            let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
//                            if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
//                                print("not same")
//                            }
//                            else{
//                                FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
//                            }
//                            imageForMedia = result
//                        }
//                        else{
//                            imageForMedia = UIImage(named: "thumb12")!
//                        }
//                    })
//                    
//                }
//            }
//            self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.thumbImageKey:imageForMedia,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.streamTockenKey:"",self.notificationKey:self.imageDataSource[i][self.notificationKey]!,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.removeOverlay()
//                self.channelItemsCollectionView.reloadData()
//            })
//            
//            
//        }
//    }
//    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
//    {
//        var mediaImage : UIImage = UIImage()
//        let data = NSData(contentsOfURL: downloadURL)
//        if let imageData = data as NSData? {
//            if let mediaImage1 = UIImage(data: imageData)
//            {
//                mediaImage = mediaImage1
//            }
//            completion(result: UIImage(data: imageData)!)
//        }
//        else
//        {
//            completion(result:UIImage(named:"thumb12")!)
//        }
//    }
//    
    


}
