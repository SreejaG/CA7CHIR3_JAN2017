//
//  ChannelSharedListAPI.swift
//  iONLive
//
//  Created by sreejesh on 7/29/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ChannelSharedListAPI: NSObject {
    
    let channelIdkey = "ch_detail_id"
    let channelNameKey = "channel_name"
    let sharedMediaCount = "total_no_media_shared"
    let totalNoShared = "totalNo"
    let timeStamp = "created_time_stamp"
    let lastUpdatedTimeStamp = "notificationTime"
    let usernameKey = "user_name"
    let profileImageKey = "profile_image_thumbnail"
    let liveStreamStatus = "liveChannel"
    let isWatched = "isWatched"
    let streamTockenKey = "wowza_stream_token"
    let mediaImageKey = "mediaImage"
    let thumbImageKey = "thumbImage"
    var  dummy:[[String:AnyObject]] = [[String:AnyObject]]()
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var SharedChannelListDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var pullToRefreshSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var pullTorefresh : Bool = false
    class var sharedInstance: ChannelSharedListAPI
    {
        struct Singleton
        {
            static let instance = ChannelSharedListAPI()
            private init() {}
        }
        return Singleton.instance
    }
    
    func getChannelSharedDetails(userName: String, token: String)
    {
        
        ChannelManager.sharedInstance.getChannelShared(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        
        if let json = response as? [String: AnyObject]
        {
            dummy.removeAll()
            dataSource.removeAll()
            let responseArrLive = json["liveChannels"] as! [[String:AnyObject]]
            
            if (responseArrLive.count != 0)
            {
                NSUserDefaults.standardUserDefaults().setValue("NotEmpty", forKey: "MEDIA")
                
                for element in responseArrLive{
                    let channelId = element[channelIdkey]?.stringValue
                    let channelName = element[channelNameKey] as! String
                    let streamTocken = element[streamTockenKey] as! String
                    let mediaSharedCount = element[sharedMediaCount]?.stringValue
                    let username = element[usernameKey] as! String
                    let liveStream = "1"
                    let channelSubId = element[subChannelIdKey]?.stringValue
                    let thumbUrlBeforeNullChk =  element[profileImageKey]
                    let thumbUrl =  nullToNil(thumbUrlBeforeNullChk) as! String
                    let mediaUrl =  "noimage"
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    
                    //  let cloudDate = dateFormatter.dateFromString(dateStr)
                    
                    let localDateStr = dateFormatter.stringFromDate(NSDate())
                    dataSource.append([channelIdkey:channelId!,channelNameKey:channelName,subChannelIdKey : channelSubId!,sharedMediaCount:mediaSharedCount!, streamTockenKey:streamTocken,timeStamp:localDateStr,usernameKey:username,liveStreamStatus:liveStream, profileImageKey:thumbUrl,mediaImageKey:mediaUrl])
                }
            }
            
            let responseArr = json["subscribedChannels"] as! [[String:AnyObject]]
            
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
            }
            
            if(responseArr.count == 0)
            {
                NSUserDefaults.standardUserDefaults().setValue("Empty", forKey: "EmptyShare")
            }
            if (responseArr.count != 0)
            {
                NSUserDefaults.standardUserDefaults().setValue("NotEmpty", forKey: "EmptyShare")
                
                for element in responseArr{
                    let channelId = element[channelIdkey]?.stringValue
                    let channelName = element[channelNameKey] as! String
                    let mediaSharedCount = element[sharedMediaCount]?.stringValue
                    let time = element[lastUpdatedTimeStamp] as! String
                    let username = element[usernameKey] as! String
                    let channelSubId = element[subChannelIdKey]?.stringValue
                    let liveStream = "0"
                    var mediaThumbUrl : String = String()
                    if liveStream == "0"
                    {
                        let mediaThumbUrlBeforeNullChk = element["thumbnail_Url"]
                        mediaThumbUrl = nullToNil(mediaThumbUrlBeforeNullChk) as! String
                    }
                    else
                    {
                        mediaThumbUrl = "noimage"
                    }
                    let profileImageNameBeforeNullChk =  element[profileImageKey]
                    let thumbUrl =  nullToNil(profileImageNameBeforeNullChk) as! String
                    var flag: Bool = false
                    
                    if(mediaShared.count > 0)
                    {
                        for(var i = 0 ;i < mediaShared.count ; i++)
                        {
                            if let val = mediaShared[i][channelIdkey] {
                                if((val as! String) == channelId)
                                {
                                    flag = true
                                }
                                
                                
                            }
                        }
                        if(!flag)
                        {
                            mediaShared.append([channelIdkey:channelId!,totalNoShared:mediaSharedCount! ,sharedMediaCount:mediaSharedCount!,isWatched :"0"])
                        }
                    }
                    else{
                        mediaShared.append([channelIdkey:channelId!,totalNoShared:mediaSharedCount! ,sharedMediaCount:mediaSharedCount!,isWatched :"0"])
                    }
                    
                    dummy.append([channelIdkey:channelId!, subChannelIdKey : channelSubId!,channelNameKey:channelName,sharedMediaCount:mediaSharedCount!,timeStamp:time,usernameKey:username,liveStreamStatus:liveStream,streamTockenKey:"0", profileImageKey:thumbUrl,mediaImageKey:mediaThumbUrl])
                }
            }
            if(dummy.count > 0)
            {
                dummy.sortInPlace({ p1, p2 in
                    
                    let time1 = p1[timeStamp] as! String
                    let time2 = p2[timeStamp] as! String
                    return time1 > time2
                })
            }
            for element in dummy
            {
                dataSource.append(element)
            }
            NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            if(dataSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    
                })
            }
            else{
                NSNotificationCenter.defaultCenter().postNotificationName("PullToRefreshSharedChannelList", object: "failure")
                
            }
        }
        else
        {
            NSNotificationCenter.defaultCenter().postNotificationName("PullToRefreshSharedChannelList", object: "failure")
            
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func updateMediaSharedInChannelList()
    {
        var mediaSharedSource : [[String : AnyObject]] = [[String : AnyObject]]()
        if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
        {
            mediaSharedSource = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        }
        
        if( mediaSharedSource.count > 0)
        {
            var flag: Bool = false
            for i in 0  ..< mediaSharedSource.count
            {
                
                for(var globalChannelListIndex  = 0 ; globalChannelListIndex  < ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count ; globalChannelListIndex++ )
                {
                    let channelId = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[globalChannelListIndex][channelIdkey] as! String
                    let mediaSharedCount = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[globalChannelListIndex][sharedMediaCount] as! String
                    if let val = mediaSharedSource[i][channelIdkey] {
                        if((val as! String) == channelId)
                        {
                            flag = true
                            if mediaSharedSource[i][isWatched] as! String == "1"
                            {
                                if((mediaSharedSource[i][totalNoShared] as! String) == mediaSharedCount)
                                {
                                    let count:Int? = Int(mediaSharedCount)! - Int(mediaSharedSource[i][totalNoShared] as! String)!
                                    let countString = String(                                      callAbsolute(count!))
                                    mediaSharedSource[i][sharedMediaCount] = countString
                                    mediaSharedSource[i][totalNoShared] = mediaSharedCount
                                    mediaSharedSource[i][isWatched] = "0"
                                }
                                else
                                {
                                    let count:Int? = Int(mediaSharedCount)! - Int(mediaSharedSource[i][totalNoShared] as! String)!
                                    mediaSharedSource[i][sharedMediaCount] = String(callAbsolute(count!))
                                    mediaSharedSource[i][totalNoShared] = mediaSharedCount
                                }
                            }
                            else
                            {
                                if(mediaSharedSource[i][totalNoShared] as? String != mediaSharedCount)
                                {
                                    let count = Int(mediaSharedCount)! - Int(mediaSharedSource[i][totalNoShared] as! String)!
                                    let p = mediaSharedSource[i][sharedMediaCount] as! String
                                    let countString:Int
                                    if( Int(p) == nil)
                                    {
                                        countString = 0 + Int(callAbsolute(count))
                                    }
                                    else
                                    {
                                        countString = Int((mediaSharedSource[i][sharedMediaCount] as! String))! + Int(callAbsolute(count))
                                    }
                                    
                                    
                                    mediaSharedSource[i][sharedMediaCount] = String(countString)
                                    mediaSharedSource[i][totalNoShared] = mediaSharedCount
                                    mediaSharedSource[i][isWatched] = "0"
                                }
                            }
                        }
                        
                    }
                }
                NSUserDefaults.standardUserDefaults().setObject(mediaSharedSource, forKey: "Shared")
            }
            //            if(flag)
            //            {
            //               // mediaShared.append([channelIdkey:channelId!,totalNoShared:mediaSharedCount! ,sharedMediaCount:mediaSharedCount!,isWatched :"0"])
            //                //ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[i][sharedMediaCount] = mediaSharedCount!
            //            }
        }
        
    }
    func pullToRefreshData( subID : String)
    {
        pullTorefresh = true
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        if( SharedChannelListDataSource.count > 0 )
        {
            // let subId = SharedChannelListDataSource[0][subChannelIdKey] as! String
            ChannelManager.sharedInstance.getChannelSharedPullToRefresh(userId, accessToken:    accessToken, channelSubId: subID, success: { (response) in
                self.authenticationSuccessHandler(response)
                
            }) { (error, code) in
                print("errorr")
            }
        }
    }
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func downloadMediaFromGCS(){
        
        for var i = 0; i < dataSource.count; i++
        {
            var mediaImage : UIImage?
            var profileImage : UIImage?
            
            let profileImageName = dataSource[i][profileImageKey] as! String
            if(profileImageName != "")
            {
                profileImage = createProfileImage(profileImageName)
            }
            else{
                profileImage = UIImage(named: "dummyUser")
            }
            
            let mediaThumbUrl = dataSource[i][mediaImageKey] as! String
            if(mediaThumbUrl != "noimage"){
                if(mediaThumbUrl != "")
                {
                    mediaImage = createMediaThumb(mediaThumbUrl)
                }
                else{
                    mediaImage = UIImage()
                }
            }
            else{
                mediaImage = UIImage()
            }
            
            if(!pullTorefresh)
            {
                
                SharedChannelListDataSource.append([self.channelIdkey:self.dataSource[i][self.channelIdkey]!,self.channelNameKey:self.dataSource[i][self.channelNameKey]!,self.sharedMediaCount:self.dataSource[i][self.sharedMediaCount]!,self.timeStamp:self.dataSource[i][self.timeStamp]!,self.usernameKey:self.dataSource[i][self.usernameKey]!,self.liveStreamStatus:self.dataSource[i][self.liveStreamStatus]!,self.streamTockenKey:self.dataSource[i][self.streamTockenKey]!,self.profileImageKey:profileImage!, self.mediaImageKey:mediaImage!, subChannelIdKey :self.dataSource[i][subChannelIdKey]! ])
            }
            else
            {
                pullToRefreshSource.append([self.channelIdkey:self.dataSource[i][self.channelIdkey]!,self.channelNameKey:self.dataSource[i][self.channelNameKey]!,self.sharedMediaCount:self.dataSource[i][self.sharedMediaCount]!,self.timeStamp:self.dataSource[i][self.timeStamp]!,self.usernameKey:self.dataSource[i][self.usernameKey]!,self.liveStreamStatus:self.dataSource[i][self.liveStreamStatus]!,self.streamTockenKey:self.dataSource[i][self.streamTockenKey]!,self.profileImageKey:profileImage!, self.mediaImageKey:mediaImage!, subChannelIdKey :self.dataSource[i][subChannelIdKey]! ])
            }
            
        }
        // if data available while pull to refresh no need to add data to global here
        // access datasource from calling view and insert respected rows to table view and update global source there in main view
        if(pullTorefresh)
        {
            if(pullToRefreshSource.count > 0)
            {
                NSNotificationCenter.defaultCenter().postNotificationName("PullToRefreshSharedChannelList", object: "success")
                
            }
            else
            {
                NSNotificationCenter.defaultCenter().postNotificationName("PullToRefreshSharedChannelList", object: "failure")
                
            }
        }
        else
        {
            NSNotificationCenter.defaultCenter().postNotificationName("SharedChannelList", object: "success")
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !RequestManager.sharedInstance.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                // loadInitialViewController(code)
            }
            else{
                //    ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
        }
    }
    func createMediaThumb(mediaName: String) -> UIImage
    {
        var mediaImage : UIImage?
        if(mediaName != "")
        {
            let url: NSURL = convertStringtoURL(mediaName)
            if let mediaData = NSData(contentsOfURL: url){
                let mediaImageData = (mediaData as NSData?)!
                mediaImage = UIImage(data: mediaImageData)
            }
            else{
                mediaImage = UIImage()
            }
        }
        else{
            mediaImage = UIImage()
        }
        return mediaImage!
    }
    
    func createProfileImage(profileName: String) -> UIImage
    {
        var profileImage : UIImage = UIImage()
        let url: NSURL = convertStringtoURL(profileName)
        if let data = NSData(contentsOfURL: url){
            let imageDetailsData = (data as NSData?)!
            profileImage = UIImage(data: imageDetailsData)!
        }
        else{
            profileImage = UIImage(named: "dummyUser")!
        }
        return profileImage
    }
    
    func callAbsolute(value : Int ) -> Int
    {
        if (value < 0)
        {
            let value1 = value * -1;
            return value1
            
        }
        return value
    }
    
}
