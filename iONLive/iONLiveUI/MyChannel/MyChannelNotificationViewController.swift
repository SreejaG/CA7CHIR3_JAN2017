//
//  MyChannelNotificationViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/11/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit


class MyChannelNotificationViewController: UIViewController {
    
    static let identifier = "MyChannelNotificationViewController"
    
    @IBOutlet var triangleView: UIImageView!
    @IBOutlet var NotificationLabelView: UIView!
    @IBOutlet var NotificationTableView: UITableView!
    
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    var mediaDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var channelDataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let usernameKey = "userName"
    let profileImageKey = "profileImage"
    let notificationTypeKey = "notificationType"
    let mediaTypeKey = "mediaType"
    let mediaImageKey = "mediaImage"
    let messageKey = "message"
    let notificationTimeKey = "notifTime"
    
    @IBOutlet var notifImage: UIButton!
    var tapFlag : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
//        let defaults = NSUserDefaults .standardUserDefaults()
//        if let notifFlag = defaults.valueForKey("notificationFlag")
//        {
//            if notifFlag as! String == "1"
//            {
//                let image = UIImage(named: "notif") as UIImage?
//                notifImage.setImage(image, forState: .Normal)
//            }
//        }
//        else{
//                let image = UIImage(named: "noNotif") as UIImage?
//                notifImage.setImage(image, forState: .Normal)
//            }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
    }
    
    @IBAction func didTapNotificationButton(sender: AnyObject) {
        if(tapFlag){

            let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelVC = storyboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
            channelVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(channelVC, animated: true)
        }
    }
    
    func initialise(){
        NotificationTableView.layer.cornerRadius=10
        tapFlag = false
        channelDataSource.removeAll()
        mediaDataSource.removeAll()
        
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue("0", forKey: "notificationFlag")
        
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getNotificationDetails(userId, token: accessToken)
    }
    
    func getNotificationDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getMediaInteractionDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                
        }}
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
         loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
//        loadingOverlayController.view.frame = self.view.bounds
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
        if monthsFrom(date,todate:todate)  > 0 { return "\(monthsFrom(date,todate:todate))m"  }
        if weeksFrom(date,todate:todate)   > 0 { return "\(weeksFrom(date,todate:todate))w"   }
        if daysFrom(date,todate:todate)    > 0 { return "\(daysFrom(date,todate:todate))d"    }
        if hoursFrom(date,todate:todate)   > 0 { return "\(hoursFrom(date,todate:todate))h"   }
        if minutesFrom(date,todate:todate) > 0 { return "\(minutesFrom(date,todate:todate))min" }
        if secondsFrom(date,todate:todate) > 0 { return "\(secondsFrom(date,todate:todate))sec" }
        return ""
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            print(json)
            
            var mediaImage : UIImage?
            var profileImage : UIImage?
           
            let mediaResponseArr = json["notification Details"]!["mediaDetails"] as! [[String:AnyObject]]
            if mediaResponseArr.count > 0
            {
                for element in mediaResponseArr{
//                    let username = element["user_name"] as! String
//                    let notifType = element["notification_type"] as! String
//                    let mediaType = element["gcs_object_type"] as! String
                    let notTime = element["created_time_stamp"] as! String
                    let timeDiff = getTimeDifference(notTime)
                    let messageFromCloud = element["message"] as! String
                    print(messageFromCloud)
                    let message = "\(messageFromCloud)  \(timeDiff)"
                    if let mediaThumbUrl: String = element["thumbnail_name_SignedUrl"] as? String
                    {
                        mediaImage = createMediaThumb(mediaThumbUrl)
                    }
                    else{
                        mediaImage = UIImage(named: "thumb12")
                    }
                
                    if let profileImageName = element["profile_image"]
                    {
                        if let imageByteArray: NSArray = profileImageName["data"] as? NSArray
                        {
                            profileImage = createProfileImage(imageByteArray)
                        }
                        else{
                            profileImage = UIImage(named: "avatar")
                        }
                    }
                    else{
                        profileImage = UIImage(named: "avatar")
                    }
                    
                 //   print("\(message)  \(profileImage)  \(mediaImage)   \(notTime)")
                    dataSource.append([messageKey:message,profileImageKey:profileImage!,mediaImageKey:mediaImage!, notificationTimeKey:notTime])
                }
            }
            
            let channelResponseArr = json["notification Details"]!["channelDetails"] as! [[String:AnyObject]]
            if channelResponseArr.count > 0
            {
                for element in channelResponseArr{
//                    let username = element["user_name"] as! String
//                    let notifType = element["notification_type"] as! String
//                    let mediaType = element["channel_name"] as! String
                    let notTime = element["created_time_stamp"] as! String
                    let timeDiff = getTimeDifference(notTime)
                    let messageFromCloud = element["message"] as! String
                    print(messageFromCloud)
                    let message = "\(messageFromCloud)  \(timeDiff)"
                    
                    if let profileImageName = element["profile_image"]
                    {
                        if let imageByteArray: NSArray = profileImageName["data"] as? NSArray
                        {
                            profileImage = createProfileImage(imageByteArray)
                        }
                        else{
                            profileImage = UIImage(named: "avatar")
                        }
                    }
                    else{
                        profileImage = UIImage(named: "avatar")
                    }
                    dataSource.append([messageKey:message,profileImageKey:profileImage!,mediaImageKey:UIImage(),notificationTimeKey:notTime])
                }
                
            }
            
            print(dataSource)
            
            if(dataSource.count > 0)
            {
                dataSource.sortInPlace({ p1, p2 in
                    let time1 = p1[notificationTimeKey] as! String
                    let time2 = p2[notificationTimeKey] as! String
                    return time1 > time2
                })
            }
         
            print(dataSource)
            
            tapFlag = true
            NotificationTableView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
 
    func createMediaThumb(mediaName: String) -> UIImage
    {
        var mediaImage : UIImage?
        print(mediaName)
        if(mediaName != "")
        {
            let url: NSURL = convertStringtoURL(mediaName)
            if let mediaData = NSData(contentsOfURL: url){
                let mediaImageData = (mediaData as NSData?)!
                mediaImage = UIImage(data: mediaImageData)
            }
            else{
                mediaImage = UIImage(named: "thumb12")
            }
        }
        else{
            mediaImage = UIImage(named: "thumb12")
        }
        return mediaImage!
    }
    
    func createProfileImage(profileName: NSArray) -> UIImage
    {
        var profileImage : UIImage?
        var bytes:[UInt8] = []
        for serverByte in profileName {
            bytes.append(UInt8(serverByte as! UInt))
        }
        
        if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
            let profileImageData = profileData as NSData?
            profileImage = UIImage(data: profileImageData!)
        }
        else{
            profileImage = UIImage(named: "avatar")
        }
        return profileImage!
    }
    
    func  getTimeDifference(dateStr:String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        
        let cloudDate = dateFormatter.dateFromString(dateStr)
        
        let localDateStr = dateFormatter.stringFromDate(NSDate())
        let localDate = dateFormatter.dateFromString(localDateStr)
        
        let differenceString =  offsetFrom(cloudDate!, todate: localDate!)
        print("\(cloudDate)   \(localDate)")
        print(differenceString)
        
        return differenceString
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

extension MyChannelNotificationViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 55.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}

extension MyChannelNotificationViewController:UITableViewDataSource
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
            let cell = tableView.dequeueReusableCellWithIdentifier(MyChannelNotificationCell.identifier, forIndexPath:indexPath) as! MyChannelNotificationCell
            
            cell.notificationText.text = dataSource[indexPath.row][messageKey] as? String
            cell.NotificationSenderImageView.image = dataSource[indexPath.row][profileImageKey] as? UIImage
            cell.NotificationImage.image = dataSource[indexPath.row][mediaImageKey] as? UIImage
            cell.selectionStyle = .None
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
}
