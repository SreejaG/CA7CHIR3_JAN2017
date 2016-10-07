
import UIKit

class ChannelsSharedController: UIViewController , UITableViewDelegate {
    
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
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
    var downloadCompleteFlag : String = "start"
    var pullToRefreshActive = false
    @IBOutlet weak var ChannelSharedTableView: UITableView!
    var tapCountChannelShared : Int = 0
    var isNeedRefresh : Bool = false
    @IBOutlet weak var leadingLabelConstraint: NSLayoutConstraint!
    var pushNotificationFlag : Bool = false
    @IBOutlet weak var newShareAvailabellabel: UILabel!
    let calendar = NSCalendar.currentCalendar()
    var refreshAlert : UIAlertController = UIAlertController()
    var NoDatalabel : UILabel = UILabel()
    var timer : NSTimer = NSTimer()
    override func viewDidLoad() {
        super.viewDidLoad()
        newShareAvailabellabel.layer.cornerRadius = 5
        initialise()
        timer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: #selector(ChannelsSharedController.timerFunc(_:)), userInfo: nil, repeats: false)
        
        if NSUserDefaults.standardUserDefaults().objectForKey("NotificationChannelText") != nil{
            let messageText = NSUserDefaults.standardUserDefaults().objectForKey("NotificationChannelText") as! String
            if(messageText != "")
            {
                self.newShareAvailabellabel.hidden = false
                self.newShareAvailabellabel.text = messageText
            }
            NSUserDefaults.standardUserDefaults().setObject("", forKey: "NotificationChannelText")
        }
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        SharedChannelDetailsAPI.sharedInstance.imageDataSource.removeAll()
        SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAll()
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
        
    }
    func timerFunc(timer:NSTimer!) {
        
        if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
            
            if (GlobalStreamList.sharedInstance.GlobalStreamDataSource.count == 0)
            {
                self.removeOverlay()
                self.NoDatalabel.removeFromSuperview()
                self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                self.NoDatalabel.textAlignment = NSTextAlignment.Center
                self.NoDatalabel.text = "No Channel Available"
                self.view.addSubview(self.NoDatalabel)
            }
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        refreshAlert = UIAlertController()
        ChannelSharedListAPI.sharedInstance.cancelOperationQueue()
    }
    
    func initialise()
    {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(ChannelsSharedController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
        self.ChannelSharedTableView.addSubview(self.refreshControl)
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.ChannelSharedTableView.alwaysBounceVertical = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.updateChannelList), name: "SharedChannelList", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.pushNotificationUpdate), name: "PushNotificationChannel", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.pullToRefreshUpdate), name: "PullToRefreshSharedChannelList", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.removeOverlay), name: "RemoveOverlay", object:nil)
        
        newShareAvailabellabel.hidden = true
        if (ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count == 0)
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.showOverlay()
            })
            let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
            let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
            ChannelSharedListAPI.sharedInstance.getChannelSharedDetails(userId, token: accessToken)
            
        }else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
            })
        }
    }
    
    // channel delete push notification handler
    func channelDeletionPushNotification(info:  [String : AnyObject])
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count == 0)
            {
                self.NoDatalabel.removeFromSuperview()
                self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                self.NoDatalabel.textAlignment = NSTextAlignment.Center
                self.NoDatalabel.text = "No Channel Available"
                self.view.addSubview(self.NoDatalabel)
            }
            else
            {
                self.NoDatalabel.removeFromSuperview()
            }
            self.ChannelSharedTableView.reloadData()
        })
    }
    
    func channelPushNotificationLiveStarted(info: [String : AnyObject])
    {
        let subType = info["subType"] as! String
        
        switch subType {
        case "started":
            ErrorManager.sharedInstance.streamAvailable()
            updateLiveStreamStartedEntry(info)
            break;
        case "stopped":
            updateLiveStreamStoppeddEntry(info)
            break;
            
        default:
            break;
        }
    }
    
    func updateLiveStreamStartedEntry(info:[String : AnyObject])
    {
        let channelId = info["channelId"] as! Int
        let index  = getUpdateIndexChannel("\(channelId)", isCountArray: false)
        if(index != -1)
        {
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][ self.liveStreamStatus] = "1"
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][ self.streamTockenKey] = "1"
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let itemToMove = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index]
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.removeAtIndex(index)
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.insert(itemToMove, atIndex: 0)
                self.ChannelSharedTableView.reloadData()
            })
        }
        else{
            newShareAvailabellabel.hidden = false
            newShareAvailabellabel.text = "Live stream available"
        }
    }
    
    func isVisibleCell( index : Int ) -> Bool
    {
        if let indices = ChannelSharedTableView.indexPathsForVisibleRows {
            for index in indices {
                if index.row == index {
                    return true
                }
            }
        }
        return false
    }
    func thumbExists (item: [String : AnyObject]) -> Bool {
        let liveStreamStatus = "liveChannel"
        return item[liveStreamStatus] as! String == "1"
    }
    func updateLiveStreamStoppeddEntry(info:[String : AnyObject])
    {
        let channelId = info["channelId"] as! Int
        let index  = getUpdateIndexChannel("\(channelId)", isCountArray: false)
        if(index != -1)
        {
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][ self.liveStreamStatus] = "0"
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][ self.streamTockenKey] = "0"
            
            let filteredData = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.filter(thumbExists)
            let totalCount = filteredData.count
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let itemToMove = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index]
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.removeAtIndex(index)
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.insert(itemToMove, atIndex: totalCount)
                self.ChannelSharedTableView.reloadData()
            })
        }
    }
    
    func pushNotificationUpdate(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        if (info["type"] as! String == "share"){
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
           
            self.pushNotificationFlag = true
            if(self.downloadCompleteFlag != "end")
            {
                self.newShareAvailabellabel.hidden = true
            }
                self.ChannelSharedTableView.reloadData()
            })
            pushNotificationFlag = false
        }
        else if (info["type"] as! String == "channel")
        {
            if(info["subType"] as! String == "useradded")
            {
                newShareAvailabellabel.hidden = false
                newShareAvailabellabel.text = info[ "messageText"] as? String
            }
            else{
                if(!ChannelSharedTableView.visibleCells.isEmpty)
                {
                    refreshAlert = UIAlertController(title: "Deleted", message: "Shared channel deleted.", preferredStyle: UIAlertControllerStyle.Alert)
                    
                    refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                    }))
                    self.presentViewController(refreshAlert, animated: true, completion: nil)
                    self.channelDeletionPushNotification(info)
                }
            }
        }
        else if (info["type"] as! String == "liveStream")
        {
            channelPushNotificationLiveStarted(info)
        }
    }
    
    func topMostController() -> UIViewController {
        var topController: UIViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
        while (topController.presentedViewController != nil) {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    func getUpdateIndexChannel(channelIdValue : String , isCountArray : Bool) -> Int
    {
        var selectedArray : NSArray = NSArray()
        var indexOfRow : Int = -1
        if(isCountArray)
        {
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared.removeAll()
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
                selectedArray = mediaShared as Array
            }
            
        }
        else{
            selectedArray = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource
        }
        var  checkFlag : Bool = false
        var index : Int =  Int()
        
        for i in 0  ..< selectedArray.count 
        {
            let channelId = selectedArray[i][channelIdkey]!
            if "\(channelId!)"  == channelIdValue
            {
                checkFlag = true
                index = i
            }
        }
        if(checkFlag)
        {
            indexOfRow = index
        }
        return indexOfRow
    }
    
    func updateChannelList(notif : NSNotification)
    {
        if(self.downloadCompleteFlag == "start")
        {
            downloadCompleteFlag = "end"
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.newShareAvailabellabel.hidden = true
            self.removeOverlay()
            if(self.pullToRefreshActive){
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            }
        })
        let success =  notif.object as! String
        if(success == "success")
        {
            if !pushNotificationFlag
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.removeOverlay()
                    self.ChannelSharedTableView.reloadData()
                    if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > 0)
                    {
                        self.NoDatalabel.removeFromSuperview()
                    }
                })
            }
            
        }
        else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
            })
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count == 0)
                {
                    self.NoDatalabel.removeFromSuperview()
                    self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                    self.NoDatalabel.textAlignment = NSTextAlignment.Center
                    self.NoDatalabel.text = "No Channel Available"
                    self.view.addSubview(self.NoDatalabel)
                }
                else
                {
                    self.NoDatalabel.removeFromSuperview()
                }
            })
            
        }
    }
    
    func pullToRefresh()
    {
        newShareAvailabellabel.hidden = true
        NSUserDefaults.standardUserDefaults().setObject("", forKey: "NotificationChannelText")
        pullToRefreshActive = true
        let sortList : Array = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource
        var subIdArray : [Int] = [Int]()
        
        for i in 0  ..< sortList.count 
        {
            let subId = sortList[i][subChannelIdKey] as! String
            subIdArray.append(Int(subId)!)
        }
        if(subIdArray.count > 0)
        {
            let subid = subIdArray.maxElement()!
            
            if(!pushNotificationFlag)
            {
                if(pullToRefreshActive){
                    isNeedRefresh = false
                    ChannelSharedListAPI.sharedInstance.dataSource.removeAll()
                    ChannelSharedListAPI.sharedInstance.dummy.removeAll()
                    ChannelSharedListAPI.sharedInstance.pullToRefreshSource.removeAll()
                    ChannelSharedListAPI.sharedInstance.pullToRefreshData("\(subid)")
                }
            }
            else{
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.refreshControl.endRefreshing()
                })
                self.pullToRefreshActive = false
            }
        }
        else
        {
            ChannelSharedListAPI.sharedInstance.dataSource.removeAll()
            ChannelSharedListAPI.sharedInstance.dummy.removeAll()
            ChannelSharedListAPI.sharedInstance.pullToRefreshSource.removeAll()
            ChannelSharedListAPI.sharedInstance.initialisedata()
        }
    }
    
    func pullToRefreshUpdate(notif : NSNotification)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
        })
        let success =  notif.object as! String
        if(success == "success")
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                for(var dataSourceIndex = ChannelSharedListAPI.sharedInstance.pullToRefreshSource.count - 1 ; dataSourceIndex >= 0 ; dataSourceIndex--)
                {
                    var flag : Bool = false
                    for i in 0  ..< ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count
                    {
                        let chId =  ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[i][self.channelIdkey] as! String
                        
                        let chId2 = ChannelSharedListAPI.sharedInstance.pullToRefreshSource[dataSourceIndex][self.channelIdkey] as! String
                        if(chId == chId2)
                        {
                            flag = true
                        }
                    }
                    if(!flag)
                    {
                        ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.insert(ChannelSharedListAPI.sharedInstance.pullToRefreshSource[dataSourceIndex] , atIndex: 0)
                    }
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > 0)
                    {
                        self.NoDatalabel.removeFromSuperview()
                    }
                    self.ChannelSharedTableView.reloadData()
                })
            })
        }
        else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl.endRefreshing()
            })
            self.pullToRefreshActive = false
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
                catch _ as NSError {
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
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
}

extension ChannelsSharedController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > 0
        {
            return ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count
        }
        else
        {
            return 0
        }
        
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.removeOverlay()
        })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(ChannelSharedCell.identifier, forIndexPath:indexPath) as! ChannelSharedCell
            cell.channelProfileImage.image = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][profileImageKey] as? UIImage
            cell.channelNameLabel.text =   ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelNameKey] as? String
            cell.countLabel.hidden = true
            if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][liveStreamStatus] as! String == "1")
            {
                cell.currentUpdationImage.hidden = false
                cell.latestImage.hidden = true
                let text = "@" + (ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String) + " Live"
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
                    if(mediaShared[i][channelIdkey]?.intValue ==  ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey]?.intValue)
                    {
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                        dateFormatter.timeZone = NSTimeZone(name: "UTC")
                        var date = dateFormatter.dateFromString(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][timeStamp] as! String)
                        let fromdateStr = dateFormatter.stringFromDate(NSDate())
                        var fromdate = dateFormatter.dateFromString(fromdateStr)
                        let sdifferentString =  offsetFrom(date!, todate: fromdate!)
                        let count = (mediaShared[i][sharedMediaCount]?.intValue)!
                        let text = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String
                        if( count == 0)
                        {
                            cell.latestImage.hidden = false
                            cell.countLabel.hidden = true
                            cell.latestImage.image  = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][self.mediaImageKey] as? UIImage
                            cell.detailLabel.text = "@" + text + " " +  sdifferentString
                        }
                        else
                        {
                            cell.latestImage.hidden = true
                            cell.countLabel.hidden = false
                            cell.countLabel.text = String(count)
                            cell.detailLabel.text = "@" + text + " " +  sdifferentString
                        }
                        
                        date = nil
                        fromdate = nil
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
        let chId = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
        let index  = getUpdateIndexChannel(chId, isCountArray: true)
        if(index != -1)
        {
            let sharedCount = mediaShared[index][sharedMediaCount] as! String
            channelItemListVC.channelId = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
            channelItemListVC.channelName = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelNameKey] as! String
            channelItemListVC.totalMediaCount = sharedCount
            channelItemListVC.userName = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String
            channelItemListVC.profileImage = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][profileImageKey] as! UIImage
            channelItemListVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(channelItemListVC, animated: false)
        }
    }
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://\(vowzaIp):1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        self.presentViewController(vc, animated: false) { () -> Void in
            
        }
    }
    
    func yearsFrom(date:NSDate, todate:NSDate) -> Int{
        return calendar.components(.Year, fromDate: date, toDate: todate, options: []).year
    }
    func monthsFrom(date:NSDate,todate:NSDate) -> Int{
        return calendar.components(.Month, fromDate: date, toDate: todate, options: []).month
    }
    func weeksFrom(date:NSDate,todate:NSDate) -> Int{
        return calendar.components(.WeekOfYear, fromDate: date, toDate: todate, options: []).weekOfYear
    }
    func daysFrom(date:NSDate,todate:NSDate) -> Int{
        return calendar.components(.Day, fromDate: date, toDate: todate, options: []).day
    }
    func hoursFrom(date:NSDate,todate:NSDate) -> Int{
        return calendar.components(.Hour, fromDate: date, toDate: todate, options: []).hour
    }
    func minutesFrom(date:NSDate,todate:NSDate) -> Int{
        return calendar.components(.Minute, fromDate: date, toDate: todate, options: []).minute
    }
    func secondsFrom(date:NSDate,todate:NSDate) -> Int{
        return calendar.components(.Second, fromDate: date, toDate: todate, options: []).second
    }
    func offsetFrom(date:NSDate,todate:NSDate) -> String {
        if yearsFrom(date,todate:todate)   > 0 {
            return String(yearsFrom(date,todate:todate))+"Y"
        }
        if monthsFrom(date,todate:todate)  > 0 { return String(monthsFrom(date,todate:todate))+"M" }
        if weeksFrom(date,todate:todate)   > 0 { return  String(weeksFrom(date,todate:todate))+"w"}
        if daysFrom(date,todate:todate)    > 0 { return String(daysFrom(date,todate:todate))+"d"    }
        if hoursFrom(date,todate:todate)   > 0 { return String(hoursFrom(date,todate:todate))+"h"   }
        if minutesFrom(date,todate:todate) > 0 { return String(minutesFrom(date,todate:todate))+"m" }
        if secondsFrom(date,todate:todate) > 0 { return String(secondsFrom(date,todate:todate))+"s" }
        if secondsFrom(date,todate:todate) == 0 {
            return "0s"
        }
        return ""
    }
}

