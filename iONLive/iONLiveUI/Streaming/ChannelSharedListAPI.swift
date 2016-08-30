
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
    var operationQueue = NSOperationQueue()
    var operation2 : NSBlockOperation = NSBlockOperation()
    
    class var sharedInstance: ChannelSharedListAPI
    {
        struct Singleton
        {
            static let instance = ChannelSharedListAPI()
            private init() {}
        }
        return Singleton.instance
    }
    func initialisedata()
    {
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        getChannelSharedDetails(userId, token: accessToken)
    }
    func cancelOperationQueue()
    {
        operation2.cancel()
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
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
            }
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
                    let localDateStr = dateFormatter.stringFromDate(NSDate())
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
                            mediaShared.append([channelIdkey:channelId!,sharedMediaCount:mediaSharedCount!])
                        }
                    }
                    else{
                        mediaShared.append([channelIdkey:channelId!,sharedMediaCount:mediaSharedCount!])
                    }
                    dataSource.append([channelIdkey:channelId!,channelNameKey:channelName,subChannelIdKey : channelSubId!,sharedMediaCount:mediaSharedCount!, streamTockenKey:streamTocken,timeStamp:localDateStr,usernameKey:username,liveStreamStatus:liveStream, profileImageKey:thumbUrl,mediaImageKey:mediaUrl])
                }
            }
            
            let responseArr = json["subscribedChannels"] as! [[String:AnyObject]]
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
                            mediaShared.append([channelIdkey:channelId!,sharedMediaCount:mediaSharedCount!])
                        }
                    }
                    else{
                        mediaShared.append([channelIdkey:channelId!,sharedMediaCount:mediaSharedCount!])
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
                operation2  = NSBlockOperation (block: {
                    self.downloadMediaFromGCS()
                })
                self.operationQueue.addOperation(operation2)
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
    
    func pullToRefreshData( subID : String)
    {
        pullTorefresh = true
        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
        let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
        if( SharedChannelListDataSource.count > 0 )
        {
            ChannelManager.sharedInstance.getChannelSharedPullToRefresh(userId, accessToken:    accessToken, channelSubId: subID, success: { (response) in
                self.authenticationSuccessHandler(response)
            }) { (error, code) in
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
            if operation2.cancelled
            {
                return
            }
            var mediaImage : UIImage?
            var profileImage : UIImage?
            if(dataSource.count > 0)
            {
                let profileImageName = dataSource[i][profileImageKey] as! String
                if(profileImageName != "")
                {
                    profileImage = createProfileImage(profileImageName)
                }
                else{
                    profileImage = UIImage(named: "dummyUser")
                }
                
                if(dataSource.count > 0)
                {
                    if let media1 = dataSource[i][mediaImageKey]
                    {
                        if(media1 as! String == "noimage"){
                            if(media1 as! String != "")
                            {
                                mediaImage = createMediaThumb(media1 as! String)
                            }
                            else{
                                mediaImage = UIImage()
                            }
                        }
                        else{
                            mediaImage = UIImage()
                        }
                        
                    }
                }
                
//                if let mediaThumbUrl = dataSource[i][mediaImageKey]
//                {
//                    if(mediaThumbUrl as! String == "noimage"){
//                        if(mediaThumbUrl != "")
//                        {
//                            mediaImage = createMediaThumb(mediaThumbUrl)
//                        }
//                        else{
//                            mediaImage = UIImage()
//                        }
//                    }
//                    else{
//                        mediaImage = UIImage()
//                    }
//                }
//                else{
//                    mediaImage = UIImage()
//                }
                
                
            }
            if(!pullTorefresh)
            {
                if(!checkDuplicate(self.dataSource[i][self.channelIdkey] as! String))
                {
                    if(dataSource.count > 0)
                    {
                        SharedChannelListDataSource.append([self.channelIdkey:self.dataSource[i][self.channelIdkey]!,self.channelNameKey:self.dataSource[i][self.channelNameKey]!,self.sharedMediaCount:self.dataSource[i][self.sharedMediaCount]!,self.timeStamp:self.dataSource[i][self.timeStamp]!,self.usernameKey:self.dataSource[i][self.usernameKey]!,self.liveStreamStatus:self.dataSource[i][self.liveStreamStatus]!,self.streamTockenKey:self.dataSource[i][self.streamTockenKey]!,self.profileImageKey:profileImage!, self.mediaImageKey:mediaImage!, subChannelIdKey :self.dataSource[i][subChannelIdKey]! ])
                    }
                }
            }
            else
            {
                if(dataSource.count > 0)
                {
                    pullToRefreshSource.append([self.channelIdkey:self.dataSource[i][self.channelIdkey]!,self.channelNameKey:self.dataSource[i][self.channelNameKey]!,self.sharedMediaCount:self.dataSource[i][self.sharedMediaCount]!,self.timeStamp:self.dataSource[i][self.timeStamp]!,self.usernameKey:self.dataSource[i][self.usernameKey]!,self.liveStreamStatus:self.dataSource[i][self.liveStreamStatus]!,self.streamTockenKey:self.dataSource[i][self.streamTockenKey]!,self.profileImageKey:profileImage!, self.mediaImageKey:mediaImage!, subChannelIdKey :self.dataSource[i][subChannelIdKey]! ])
                }
            }
            
        }
        
        /* if data available while pull to refresh no need to add data to global here
         / access datasource from calling view and insert respected rows to table view and update global source there in main view */
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
    
    func checkDuplicate( chId : String) -> Bool
    {
        var flag: Bool = false
        for(var i = 0 ; i < SharedChannelListDataSource.count ; i++ )
        {
            if SharedChannelListDataSource[i][channelIdkey] as! String == chId{
                flag = true
            }
        }
        return flag
    }
    
    func uniq<S : SequenceType, T : Hashable where S.Generator.Element == T>(source: S) -> [T] {
        var buffer = [T]()
        var added = Set<T>()
        for elem in source {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
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
