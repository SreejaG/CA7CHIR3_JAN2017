//
//  ChannelsSharedController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/11/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ChannelsSharedController: UIViewController , UITableViewDelegate {
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    
    var  dummy:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
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
    
    var loadingOverlay: UIView?
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    @IBOutlet weak var ChannelSharedTableView: UITableView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.ChannelSharedTableView.addSubview(refreshControl)
        self.ChannelSharedTableView.alwaysBounceVertical = true
        
        initialise()
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    func pullToRefresh()
    {
        if(!pullToRefreshActive){
        
        mediaShared.removeAll()
        dummy.removeAll()
        dataSource.removeAll()
        pullToRefreshActive = true
        initialise()
        }
        else{
            self.refreshControl.endRefreshing()
        }
    }
    
    func initialise(){
        mediaShared.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
//        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
//        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
//        dispatch_async(backgroundQueue, {
        getChannelSharedDetails(userId, token: accessToken)
//        })
    }
    
    func getChannelSharedDetails(userName: String, token: String)
    {
        showOverlay()
        if(pullToRefreshActive){
            removeOverlay()
        }
        channelManager.getChannelShared(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
            
        }
    }
    
    func  loadInitialViewController(){
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
        
        if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
        {
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtPath(documentsPath)
            }
            catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        else{
            FileManagerViewController.sharedInstance.createParentDirectory()
        }
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let deviceToken = defaults.valueForKey("deviceToken") as! String
        defaults.removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
        defaults.setValue(deviceToken, forKey: "deviceToken")
        defaults.setObject(1, forKey: "shutterActionMode");
        
        let sharingStoryboard = UIStoryboard(name:"Authentication", bundle: nil)
        let channelItemListVC = sharingStoryboard.instantiateViewControllerWithIdentifier("AuthenticateNavigationController") as! AuthenticateNavigationController
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.presentViewController(channelItemListVC, animated: true, completion: nil)
    }
    
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
      //  self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
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
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        if let json = response as? [String: AnyObject]
        {
            dummy.removeAll()
            
            let responseArrLive = json["liveChannels"] as! [[String:AnyObject]]
            if (responseArrLive.count != 0)
            {
                var mediaImage : UIImage?
                var profileImage : UIImage?
                for element in responseArrLive{
                    let channelId = element[channelIdkey]?.stringValue
                    let channelName = element[channelNameKey] as! String
                    let streamTocken = element[streamTockenKey] as! String
                    let mediaSharedCount = element[sharedMediaCount]?.stringValue
                    let username = element[usernameKey] as! String
                    let liveStream = "1"
                    
                    //signed url iprofile
                    
                    let thumbUrlBeforeNullChk =  element[profileImageKey]
                    let thumbUrl =  nullToNil(thumbUrlBeforeNullChk) as! String
                    if(thumbUrl != "")
                    {
                        let url: NSURL = convertStringtoURL(thumbUrl)
                        if let data = NSData(contentsOfURL: url){
                            let imageDetailsData = (data as NSData?)!
                            profileImage = UIImage(data: imageDetailsData)!
                        }
                        else{
                            profileImage = UIImage(named: "dummyUser")!
                        }
                    }
                    else{
                        profileImage = UIImage(named: "dummyUser")!
                    }
                    mediaImage = UIImage(named: "thumb12")
                    dataSource.append([channelIdkey:channelId!,channelNameKey:channelName,sharedMediaCount:mediaSharedCount!, streamTockenKey:streamTocken,timeStamp:"",usernameKey:username,liveStreamStatus:liveStream, profileImageKey:profileImage!,mediaImageKey:mediaImage!])
                }
            }
            let responseArr = json["subscribedChannels"] as! [[String:AnyObject]]
            if (responseArr.count == 0)
            {
                ErrorManager.sharedInstance.subscriptionEmpty()
            }
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
            }
            for element in responseArr{
                var mediaImage : UIImage?
                var profileImage : UIImage?
                let channelId = element[channelIdkey]?.stringValue
                let channelName = element[channelNameKey] as! String
                let mediaSharedCount = element[sharedMediaCount]?.stringValue
                let time = element[lastUpdatedTimeStamp] as! String
                let username = element[usernameKey] as! String
                let liveStream = "0"
                if liveStream == "0"
                {
                    let mediaThumbUrlBeforeNullChk = element["thumbnail_Url"]
                    let mediaThumbUrl = nullToNil(mediaThumbUrlBeforeNullChk) as! String
                    if(mediaThumbUrl != "")
                    {
                        let url: NSURL = convertStringtoURL(mediaThumbUrl)
                        if let mediaData = NSData(contentsOfURL: url){
                            let mediaImageData = (mediaData as NSData?)!
                            mediaImage = UIImage(data: mediaImageData)
                        }
                        else
                        {
                            mediaImage = UIImage()
                        }
                    }
                    else{
                        mediaImage = UIImage()
                    }
                }
                else
                {
                    mediaImage = UIImage()
                }
                
                //     signedurl profile image
                
                let profileImageNameBeforeNullChk =  element[profileImageKey]
                let thumbUrl =  nullToNil(profileImageNameBeforeNullChk) as! String
                if(thumbUrl != "")
                {
                    let url: NSURL = convertStringtoURL(thumbUrl)
                    if let data = NSData(contentsOfURL: url){
                        let imageDetailsData = (data as NSData?)!
                        profileImage = UIImage(data: imageDetailsData)!
                    }
                    else{
                        profileImage = UIImage(named: "dummyUser")!
                    }
                }
                else{
                    profileImage = UIImage(named: "dummyUser")!
                }
                
                //
                //                let profileImageName = element[profileImageKey]
                //                if let imageByteArray: NSArray = profileImageName!["data"] as? NSArray
                //                {
                //                    var bytes:[UInt8] = []
                //                    for serverByte in imageByteArray {
                //                        bytes.append(UInt8(serverByte as! UInt))
                //                    }
                //
                //                    if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
                //                        let profileImageData = profileData as NSData?
                //                        profileImage = UIImage(data: profileImageData!)
                //                    }
                //                }
                //                else{
                //                    profileImage = UIImage(named: "avatar")!
                //                }
                //
                //                profileImage = UIImage(named: "dummyUser")!
                
                if( mediaShared.count > 0)
                {
                    var flag: Bool = false
                    for i in 0  ..< mediaShared.count
                    {
                        if let val = mediaShared[i][channelIdkey] {
                            if((val as! String) == channelId)
                            {
                                flag = true
                                if mediaShared[i][isWatched] as! String == "1"
                                {
                                    if((mediaShared[i][totalNoShared] as! String) == mediaSharedCount)
                                    {
                                        let count:Int? = Int(mediaSharedCount!)! - Int(mediaShared[i][totalNoShared] as! String)!
                                        let countString = String(                                      callAbsolute(count!))
                                        mediaShared[i][sharedMediaCount] = countString
                                        mediaShared[i][totalNoShared] = mediaSharedCount
                                        mediaShared[i][isWatched] = "0"
                                    }
                                    else
                                    {
                                        let count:Int? = Int(mediaSharedCount!)! - Int(mediaShared[i][totalNoShared] as! String)!
                                        mediaShared[i][sharedMediaCount] = String(callAbsolute(count!))
                                        mediaShared[i][totalNoShared] = mediaSharedCount
                                    }
                                }
                                else
                                {
                                    if(mediaShared[i][totalNoShared] as? String != mediaSharedCount)
                                    {
                                        let count = Int(mediaSharedCount!)! - Int(mediaShared[i][totalNoShared] as! String)!
                                        let p = mediaShared[i][sharedMediaCount] as! String
                                        let countString:Int
                                        if( Int(p) == nil)
                                        {
                                            countString = 0 + Int(callAbsolute(count))
                                        }
                                        else
                                        {
                                            countString = Int((mediaShared[i][sharedMediaCount] as! String))! + Int(callAbsolute(count))
                                        }
                                        
                                        
                                        mediaShared[i][sharedMediaCount] = String(countString)
                                        mediaShared[i][totalNoShared] = mediaSharedCount
                                        mediaShared[i][isWatched] = "0"
                                    }
                                }
                            }
                            
                        }
                    }
                    if(!flag)
                    {
                        mediaShared.append([channelIdkey:channelId!,totalNoShared:mediaSharedCount! ,sharedMediaCount:mediaSharedCount!,isWatched :"0"])
                    }
                }
                else
                {
                    mediaShared.append([channelIdkey:channelId!,totalNoShared:mediaSharedCount! ,sharedMediaCount:mediaSharedCount!,isWatched :"0"])
                }
                dummy.append([channelIdkey:channelId!,channelNameKey:channelName,sharedMediaCount:mediaSharedCount!,timeStamp:time,usernameKey:username,liveStreamStatus:liveStream,streamTockenKey:"0", profileImageKey:profileImage!,mediaImageKey:mediaImage!])
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
            for i in 0  ..< mediaShared.count
            {
                var found : Bool = false
                for j in 0 ..< dataSource.count
                {
                    if(mediaShared[i][channelIdkey] as! String == dataSource[j][channelIdkey] as! String)
                    {
                        found = true
                    }
                }
                if(!found)
                {
                    mediaShared[i][channelIdkey] = "-1";
                }
            }
            var index = 0
            for element in mediaShared
            {
                if  element[channelIdkey] as! String == "-1"
                    
                {
                    mediaShared.removeAtIndex(index)
                }
                index += 1
            }
            NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            ChannelSharedTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
        }
        else{
        }
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

extension ChannelsSharedController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if dataSource.count > 0
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(ChannelSharedCell.identifier, forIndexPath:indexPath) as! ChannelSharedCell
            cell.channelProfileImage.image = dataSource[indexPath.row][profileImageKey] as? UIImage
            cell.channelNameLabel.text =   dataSource[indexPath.row][channelNameKey] as? String
            cell.countLabel.hidden = true
            if(dataSource[indexPath.row][liveStreamStatus] as! String == "1")
            {
                cell.currentUpdationImage.hidden = false
                cell.latestImage.hidden = true
                let text = "@" + (dataSource[indexPath.row][usernameKey] as! String) + " Live"
                cell.currentUpdationImage.image  = UIImage(named: "Live_camera")
                let linkTextWithColor = "Live"
                let range = (text as NSString).rangeOfString(linkTextWithColor)
                let attributedString = NSMutableAttributedString(string:text)
                attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor() , range: range)
                cell.detailLabel.attributedText = attributedString
            }
            else
            {
                if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
                {
                    mediaShared.removeAll()
                    mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
                }
                cell.countLabel.hidden = false
                cell.currentUpdationImage.hidden = true
                for i in 0  ..< mediaShared.count
                {
                    if(mediaShared[i][channelIdkey]?.intValue ==  dataSource[indexPath.row][channelIdkey]?.intValue)
                    {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        dateFormatter.timeZone = NSTimeZone(name: "UTC")
                        let date = dateFormatter.dateFromString(dataSource[indexPath.row][timeStamp] as! String)
                        let fromdateStr = dateFormatter.stringFromDate(NSDate())
                        let fromdate = dateFormatter.dateFromString(fromdateStr)
                        let sdifferentString =  offsetFrom(date!, todate: fromdate!)
                        let count = (mediaShared[i][sharedMediaCount]?.intValue)!
                        let text = dataSource[indexPath.row][usernameKey] as! String
                        if( count == 0)
                        {
                            cell.latestImage.hidden = false
                            
                            cell.countLabel.hidden = true
                            cell.latestImage.image  = dataSource[indexPath.row][mediaImageKey] as? UIImage
                            cell.detailLabel.text = "@" + text + " " + sdifferentString
                        }
                        else
                        {
                            cell.latestImage.hidden = true
                            cell.countLabel.hidden = false
                            cell.countLabel.text = String(count)
                            cell.detailLabel.text = "@" + text + " " + sdifferentString
                        }
                    }
                }
            }
            cell.selectionStyle = .None
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let streamingStoryboard = UIStoryboard(name:"Streaming", bundle: nil)
        let channelItemListVC = streamingStoryboard.instantiateViewControllerWithIdentifier(OtherChannelViewController.identifier) as! OtherChannelViewController
        
        channelItemListVC.channelId = dataSource[indexPath.row][channelIdkey] as! String
        channelItemListVC.channelName = dataSource[indexPath.row][channelNameKey] as! String
        channelItemListVC.totalMediaCount = Int(dataSource[indexPath.row][sharedMediaCount]! as! String)!
        channelItemListVC.userName = dataSource[indexPath.row][usernameKey] as! String
        channelItemListVC.profileImage = dataSource[indexPath.row][profileImageKey] as! UIImage
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelItemListVC, animated: false)
        
    }
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.154.69.174:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        
        self.presentViewController(vc, animated: false) { () -> Void in
            
        }
    }
    
    func yearsFrom(date:NSDate, todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Year, fromDate: date, toDate: todate, options: []).year
    }
    func monthsFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Month, fromDate: date, toDate: todate, options: []).month
    }
    func weeksFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.WeekOfYear, fromDate: date, toDate: todate, options: []).weekOfYear
    }
    func daysFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Day, fromDate: date, toDate: todate, options: []).day
    }
    func hoursFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Hour, fromDate: date, toDate: todate, options: []).hour
    }
    func minutesFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Minute, fromDate: date, toDate: todate, options: []).minute
    }
    func secondsFrom(date:NSDate,todate:NSDate) -> Int{
        return NSCalendar.currentCalendar().components(.Second, fromDate: date, toDate: todate, options: []).second
    }
    
    func offsetFrom(date:NSDate,todate:NSDate) -> String {
        if yearsFrom(date,todate:todate)   > 0 {
            return "\(yearsFrom(date,todate:todate))y"
        }
        if monthsFrom(date,todate:todate)  > 0 { return "\(monthsFrom(date,todate:todate))M"  }
        if weeksFrom(date,todate:todate)   > 0 { return "\(weeksFrom(date,todate:todate))w"   }
        if daysFrom(date,todate:todate)    > 0 { return "\(daysFrom(date,todate:todate))d"    }
        if hoursFrom(date,todate:todate)   > 0 { return "\(hoursFrom(date,todate:todate))h"   }
        if minutesFrom(date,todate:todate) > 0 { return "\(minutesFrom(date,todate:todate))m" }
        if secondsFrom(date,todate:todate) > 0 { return "\(secondsFrom(date,todate:todate))s" }
        return ""
    }
    
}

