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
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelIdkey = "ch_detail_id"
    let channelNameKey = "channel_name"
    let sharedMediaCount = "total_no_media_shared"
    let timeStamp = "created_time_stamp"
    let lastUpdatedTimeStamp = "last_updated_time_stamp"
    let usernameKey = "user_name"
    let profileImageKey = "profile_image"
    let liveStreamStatus = "liveChannel"
    let isWatched = "isWatched"
    
//    let notificationTypeKey = "notificationType"
//    let mediaTypeKey = "mediaType"
    let mediaImageKey = "mediaImage"
//    let messageKey = "message"
    
    
    var loadingOverlay: UIView?

    @IBOutlet weak var ChannelSharedTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    func initialise(){
        
       
        

        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelSharedDetails(userId, token: accessToken)
    }
    func getChannelSharedDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getChannelShared(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                
        }}
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
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
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            
            let responseArrLive = json["liveChannels"] as! [[String:AnyObject]]
            print(responseArrLive.count)
            if (responseArrLive.count != 0)
            {
                
                var mediaImage : UIImage?
                var profileImage : UIImage?
                for element in responseArrLive{
                    let channelId = element[channelIdkey]?.stringValue
                    let channelName = element[channelNameKey] as! String
                    let mediaSharedCount = element[sharedMediaCount]?.stringValue
                    let time = element[timeStamp] as! String
                    let username = element[usernameKey] as! String
                    let liveStream = "1"
                    
                    let profileImageName = element[profileImageKey]
                    if let imageByteArray: NSArray = profileImageName!["data"] as? NSArray
                    {
                        var bytes:[UInt8] = []
                        for serverByte in imageByteArray {
                            bytes.append(UInt8(serverByte as! UInt))
                        }
                        
                        if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
                            let profileImageData = profileData as NSData?
                            profileImage = UIImage(data: profileImageData!)
                        }
                    }
                    else{
                        profileImage = UIImage(named: "defUser")
                    }
                    mediaImage = UIImage(named: "thumb12")
                    dataSource.append([channelIdkey:channelId!,channelNameKey:channelName,sharedMediaCount:"0",timeStamp:time,usernameKey:username,liveStreamStatus:liveStream, profileImageKey:profileImage!,mediaImageKey:mediaImage!])
                }
            }
            let responseArr = json["subscribedChannels"] as! [[String:AnyObject]]
            print(responseArr.count)
            if (responseArr.count == 0)
            {
                ErrorManager.sharedInstance.subscriptionEmpty()
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

               // let notifType = element["notification_type"] as! String
              //  let mediaType = element["gcs_object_type"] as! String
               // let message = "\(username.capitalizedString) \(notifType.lowercaseString) your \(mediaType)"
                if liveStream == "0"
                {
                    let mediaThumbUrl = element["thumbnail_Url"] as! String
                    if(mediaThumbUrl != "")
                    {
                        let url: NSURL = convertStringtoURL(mediaThumbUrl)
                        if let mediaData = NSData(contentsOfURL: url){
                            let mediaImageData = (mediaData as NSData?)!
                            mediaImage = UIImage(data: mediaImageData)
                        }
                        else
                        {
                            mediaImage = UIImage(named: "thumb12")

                        }
                    }
                    else{
                        mediaImage = UIImage(named: "thumb12")
                    }
                }
                else
                {
                     mediaImage = UIImage(named: "thumb12")
                }
               
                let profileImageName = element[profileImageKey]
                if let imageByteArray: NSArray = profileImageName!["data"] as? NSArray
                {
                    var bytes:[UInt8] = []
                    for serverByte in imageByteArray {
                        bytes.append(UInt8(serverByte as! UInt))
                    }
                    
                    if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
                        let profileImageData = profileData as NSData?
                        profileImage = UIImage(data: profileImageData!)
                    }
                }
                else{
                    profileImage = UIImage(named: "defUser")
                }
                mediaSharedCountArray.append([channelIdkey:channelId!,sharedMediaCount:mediaSharedCount!,isWatched :"0"])
                for var i=0 ; i  < dataSource.count ;i++
                {
                    if let val = dataSource[i][channelIdkey] {
                        if(val as! String != channelId)
                        {
                            
                        }
                        // now val is not nil and the Optional has been unwrapped, so use it
                    }
                }
               
                dataSource.append([channelIdkey:channelId!,channelNameKey:channelName,sharedMediaCount:mediaSharedCount!,timeStamp:time,usernameKey:username,liveStreamStatus:liveStream, profileImageKey:profileImage!,mediaImageKey:mediaImage!])
                
            }
            print(dataSource.count);
            NSUserDefaults.standardUserDefaults().setObject(mediaSharedCountArray, forKey: "MediaSharedArray")

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
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
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
                let text = "@" + (dataSource[indexPath.row][usernameKey] as! String) + " Live"
                  cell.currentUpdationImage.image  = UIImage(named: "Live_camera")
                let linkTextWithColor = "Live"
                let range = (text as NSString).rangeOfString(linkTextWithColor)
                let attributedString = NSMutableAttributedString(string:text)
                attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor() , range: range)
                cell.detailLabel.attributedText = attributedString
            }
            else if (dataSource[indexPath.row][sharedMediaCount]?.intValue == 0)
            {
                cell.currentUpdationImage.image  = UIImage(named: "thumb12")
                cell.detailLabel.text = dataSource[indexPath.row][usernameKey] as? String

            }
            else
            {
                cell.countLabel.hidden = false
                
                
                
                
                for var i=0 ; i < mediaSharedCountArray.count ; i++
                {
                    print(i)
                    if(mediaSharedCountArray[i][channelIdkey]?.intValue ==  dataSource[indexPath.row][channelIdkey]?.intValue)
                    {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"//this your string date format
                        dateFormatter.timeZone = NSTimeZone(name: "UTC")
                     //   dateFormatter.dateFormat =  "yyyy-MM-dd'T'HH:mm:ssZ"
                        let date = dateFormatter.dateFromString(dataSource[indexPath.row][timeStamp] as! String)
                      //  print(dataSource[indexPath.row][timeStamp] as! NSDate)
                        print(date)
                       let fromdate = NSDate()
                       let sdifferentString =  offsetFrom(date!, todate: fromdate)
                        print(sdifferentString);
                        if( mediaSharedCountArray[i][isWatched] as! String == "1")
                        {
                            let count = (dataSource[indexPath.row][channelIdkey]?.intValue)! - (mediaSharedCountArray[i][channelIdkey]?.intValue)!
                            let text = dataSource[indexPath.row][usernameKey] as! String

                            if( count == 0)
                            {
                                cell.currentUpdationImage.image  = UIImage(named: "thumb12")
                                cell.detailLabel.text = dataSource[indexPath.row][usernameKey] as? String
                            }
                            else
                            {
                                cell.countLabel.text = String(count)
                                cell.detailLabel.text = "@" + text
                            }
                        }
                        else
                        {
                            let text = dataSource[indexPath.row][usernameKey] as? String
                         let count = (dataSource[indexPath.row][channelIdkey]?.intValue)! - (mediaSharedCountArray[i][channelIdkey]?.intValue)!
                            if(count == 0)
                            {
                                cell.countLabel.text = dataSource[indexPath.row][channelIdkey] as? String
                                cell.detailLabel.text = "@" + text! + " " + sdifferentString
                            }
                            else
                            {
                                cell.countLabel.text = String(count)
                                cell.detailLabel.text = "@" + text! + " " + sdifferentString
                            }
                            
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
       
        channelItemListVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelItemListVC, animated: true)
        
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
            if yearsFrom(date,todate:todate)   > 0 { return "\(yearsFrom(date,todate:todate))y"   }
            if monthsFrom(date,todate:todate)  > 0 { return "\(monthsFrom(date,todate:todate))M"  }
            if weeksFrom(date,todate:todate)   > 0 { return "\(weeksFrom(date,todate:todate))w"   }
            if daysFrom(date,todate:todate)    > 0 { return "\(daysFrom(date,todate:todate))d"    }
            if hoursFrom(date,todate:todate)   > 0 { return "\(hoursFrom(date,todate:todate))h"   }
            if minutesFrom(date,todate:todate) > 0 { return "\(minutesFrom(date,todate:todate))m" }
            if secondsFrom(date,todate:todate) > 0 { return "\(secondsFrom(date,todate:todate))s" }
            return ""
        }
    
}

