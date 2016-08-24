
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
    var fulldataSource : [[String:AnyObject]] = [[String:AnyObject]]()
    
    let usernameKey = "userName"
    let profileImageKey = "profileImage"
    let notificationTypeKey = "notificationType"
    let mediaTypeKey = "mediaType"
    let mediaImageKey = "mediaImage"
    let messageKey = "message"
    let notificationTimeKey = "notifTime"
    
    var operationQueueObjInNotif = NSOperationQueue()
    var operationInNotif = NSBlockOperation()
    
    
    @IBOutlet var notifImage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = NSUserDefaults .standardUserDefaults()
        if let notifFlag = defaults.valueForKey("notificationArrived")
        {
            if notifFlag as! String == "0"
            {
                let image = UIImage(named: "noNotif") as UIImage?
                notifImage.setImage(image, forState: .Normal)
            }
        }
        else{
            let image = UIImage(named: "notif") as UIImage?
            notifImage.setImage(image, forState: .Normal)
        }
//        defaults.setValue("0", forKey: "notificationArrived")
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
         operationInNotif.cancel()
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
        fulldataSource.removeAll()
        let defaults = NSUserDefaults .standardUserDefaults()
        defaults.setValue("0", forKey: "notificationFlag")
        
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getNotificationDetails(userId, token: accessToken)
    }
    
    func getNotificationDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getMediaInteractionDetails(userName, accessToken: token, limit: "350", offset: "0", success: { (response) in
            self.authenticationSuccessHandler(response)
            
        }) { (error, message) -> () in
            self.authenticationFailureHandler(error, code: message)
        }
    }
    
    func  loadInitialViewController(code: String){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] + "/GCSCA7CH"
            
            if(NSFileManager.defaultManager().fileExistsAtPath(documentsPath))
            {
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath(documentsPath)
                }
                catch let error as NSError {
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
            self.presentViewController(channelItemListVC, animated: false) { () -> Void in
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        })
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
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
        if minutesFrom(date,todate:todate) > 0 {
            return "\(minutesFrom(date,todate:todate))min"
        }
        if secondsFrom(date,todate:todate) > 0 {
            return "Just now"
        }
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
        NSUserDefaults.standardUserDefaults().setValue("0", forKey: "notificationArrived")
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let mediaResponseArr = json["notification Details"] as! [[String:AnyObject]]
            var mediaId : String = String()
            var mediaThumbUrl : String = String()
            if mediaResponseArr.count > 0
            {
                for element in mediaResponseArr{
                    let liveStreamId =  element["live_stream_detail_id"] as! NSNumber
                    if liveStreamId != 0
                    {
                        mediaId = "\(liveStreamId)"
                    }
                    else
                    {
                        mediaId = "\(element["media_detail_id"]  as! NSNumber)"
                    }
                    
                    let notifType = element["notification_type"] as! String
                    if(notifType.lowercaseString == "likes"){
                        let mediaThumbUrlBeforeNullChk =  element["thumbnail_name_SignedUrl"]
                        mediaThumbUrl = nullToNil(mediaThumbUrlBeforeNullChk) as! String
                    }
                    else{
                        mediaThumbUrl = "nomedia"
                    }
                    
                    let profileImageNameBeforeNullChk =  element["profile_image_thumbnail"]
                    let profileImageName = nullToNil(profileImageNameBeforeNullChk) as! String
                    
                    let notTime = element["created_time_stamp"] as! String
                    var timeDiff = getTimeDifference(notTime)
                    let messageFromCloud = element["message"] as! String
                    let message = "\(messageFromCloud)  \(timeDiff)"
                    
                    dataSource.append(["mediaIdKey":mediaId,messageKey:message,profileImageKey:profileImageName,mediaImageKey:mediaThumbUrl, notificationTimeKey:notTime, notificationTypeKey:notifType.lowercaseString])
                }
            }
            
            if(dataSource.count > 0)
            {
                dataSource.sortInPlace({ p1, p2 in
                    let time1 = p1[notificationTimeKey] as! String
                    let time2 = p2[notificationTimeKey] as! String
                    return time1 > time2
                })
                
                if(dataSource.count > 0){
                    operationInNotif  = NSBlockOperation (block: {
                        self.downloadMediaFromGCS(self.operationInNotif)
                    })
                    self.operationQueueObjInNotif.addOperation(operationInNotif)
        
                }
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func downloadMediaFromGCS(operationObj: NSBlockOperation){
        fulldataSource.removeAll()
        for var i = 0; i < dataSource.count; i++
        {
            if operationObj.cancelled == true{
                return
            }
            print("In notification thread  \(i)")
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
            if(mediaThumbUrl != "nomedia"){
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
            
            self.fulldataSource.append([self.notificationTypeKey:self.dataSource[i][self.notificationTypeKey]!,self.messageKey:self.dataSource[i][self.messageKey]!, self.profileImageKey:profileImage!, self.mediaImageKey:mediaImage!,self.notificationTimeKey:self.dataSource[i][self.notificationTimeKey]!,"mediaIdKey":self.dataSource[i]["mediaIdKey"]!])
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.NotificationTableView.reloadData()
            })
        }
    }
    
    func createMediaThumb(mediaName: String) -> UIImage
    {
        var mediaImage : UIImage = UIImage()
        do {
            let url: NSURL = convertStringtoURL(mediaName)
            let data = try NSData(contentsOfURL: url,options: NSDataReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData)
                {
                    mediaImage = mediaImage1
                }
            }
            else
            {
              mediaImage = UIImage(named: "thumb12")!
            }
            
        } catch {
           mediaImage = UIImage(named: "thumb12")!
        }
        return mediaImage

//        var mediaImage : UIImage?
//        if(mediaName != "")
//        {
//            let url: NSURL = convertStringtoURL(mediaName)
//            if let mediaData = NSData(contentsOfURL: url){
//                let mediaImageData = (mediaData as NSData?)!
//                mediaImage = UIImage(data: mediaImageData)
//            }
//            else{
//                mediaImage = UIImage(named: "thumb12")
//            }
//        }
//        else{
//            mediaImage = UIImage(named: "thumb12")
//        }
//        return mediaImage!
        
    }
    
    func createProfileImage(profileName: String) -> UIImage
    {
        var profileImage : UIImage = UIImage()
        do {
            let url: NSURL = convertStringtoURL(profileName)
            let data = try NSData(contentsOfURL: url,options: NSDataReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData)
                {
                    profileImage = mediaImage1
                }
            }
            else
            {
                profileImage = UIImage(named: "dummyUser")!
            }
            
        } catch {
            profileImage = UIImage(named: "dummyUser")!
        }
        return profileImage
        
//        
//        let url: NSURL = convertStringtoURL(profileName)
//        if let data = NSData(contentsOfURL: url){
//            let imageDetailsData = (data as NSData?)!
//            profileImage = UIImage(data: imageDetailsData)!
//        }
//        else{
//            profileImage = UIImage(named: "dummyUser")!
//        }
//        return profileImage
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
        NSUserDefaults.standardUserDefaults().setValue("0", forKey: "notificationArrived")
        self.removeOverlay()
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
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
        if fulldataSource.count > 0
        {
            return fulldataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if fulldataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MyChannelNotificationCell.identifier, forIndexPath:indexPath) as! MyChannelNotificationCell
            cell.notificationText.text = fulldataSource[indexPath.row][messageKey] as? String
            cell.NotificationSenderImageView.image = fulldataSource[indexPath.row][profileImageKey] as? UIImage
            cell.NotificationImage.image = fulldataSource[indexPath.row][mediaImageKey] as? UIImage
            cell.selectionStyle = .None
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
}
