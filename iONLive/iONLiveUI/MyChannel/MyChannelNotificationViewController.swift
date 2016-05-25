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
   
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
    }
    
    @IBAction func didTapNotificationButton(sender: AnyObject) {
        let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelVC = storyboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
        channelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelVC, animated: false)
    }
    
    func initialise(){
        NotificationTableView.layer.cornerRadius=10
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
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
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
        if let json = response as? [String: AnyObject]
        {
            var mediaImage : UIImage?
            var profileImage : UIImage?
            
            let mediaResponseArr = json["notification Details"]!["mediaDetails"] as! [[String:AnyObject]]
            if mediaResponseArr.count > 0
            {
                for element in mediaResponseArr{
                    let notTime = element["created_time_stamp"] as! String
                    let timeDiff = getTimeDifference(notTime)
                    let messageFromCloud = element["message"] as! String
                    let message = "\(messageFromCloud)  \(timeDiff)"
                    
                    let mediaThumbUrlBeforeNullChk =  element["thumbnail_name_SignedUrl"]
                    let mediaThumbUrl = nullToNil(mediaThumbUrlBeforeNullChk) as! String
                    if(mediaThumbUrl != "")
                    {
                        mediaImage = createMediaThumb(mediaThumbUrl)
                    }
                    else{
                        mediaImage = UIImage(named: "thumb12")
                    }
                   
                    let profileImageNameBeforeNullChk =  element["profile_image_thumbnail"]
                    let profileImageName = nullToNil(profileImageNameBeforeNullChk) as! String
                    if(profileImageName != "")
                    {
                         profileImage = createProfileImage(profileImageName)
                    }
                    else{
                        profileImage = UIImage(named: "dummyUser")
                    }
                    dataSource.append([messageKey:message,profileImageKey:profileImage!,mediaImageKey:mediaImage!, notificationTimeKey:notTime])
                }
            }
            
            let channelResponseArr = json["notification Details"]!["channelDetails"] as! [[String:AnyObject]]
            if channelResponseArr.count > 0
            {
                for element in channelResponseArr{
                    let notTime = element["created_time_stamp"] as! String
                    let timeDiff = getTimeDifference(notTime)
                    let messageFromCloud = element["message"] as! String
                    let message = "\(messageFromCloud)  \(timeDiff)"
                    
                    let profileImageNameBeforeNullChk =  element["profile_image_thumbnail"]
                    let profileImageName = nullToNil(profileImageNameBeforeNullChk) as! String
                    if(profileImageName != "")
                    {
                        profileImage = createProfileImage(profileImageName)
                    }
                    else{
                        profileImage = UIImage(named: "dummyUser")
                    }
                    dataSource.append([messageKey:message,profileImageKey:profileImage!,mediaImageKey:UIImage(),notificationTimeKey:notTime])
                }
                
            }
            if(dataSource.count > 0)
            {
                dataSource.sortInPlace({ p1, p2 in
                    let time1 = p1[notificationTimeKey] as! String
                    let time2 = p2[notificationTimeKey] as! String
                    return time1 > time2
                })
            }
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
    
    func  getTimeDifference(dateStr:String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = NSTimeZone(name: "UTC")
        
        let cloudDate = dateFormatter.dateFromString(dateStr)
        
        let localDateStr = dateFormatter.stringFromDate(NSDate())
        let localDate = dateFormatter.dateFromString(localDateStr)
        
        let differenceString =  offsetFrom(cloudDate!, todate: localDate!)
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
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController()
            }
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
        return 0.01
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
