
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
    override func viewDidLoad() {
        super.viewDidLoad()
        // newShareAvailabellabel.layer.backgroundColor  = UIColor.redColor().CGColor
        newShareAvailabellabel.layer.cornerRadius = 5
        initialise()
    }
    @IBAction func backButtonClicked(sender: AnyObject) {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        //  self.removeOverlay()
        //  self.showOverlay()
        NSUserDefaults.standardUserDefaults().setValue("NotActive", forKey: "StreamListActive")
        
        if(GlobalStreamList.sharedInstance.GlobalStreamDataSource.count == 0)
        {
            self.removeOverlay()
        }
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        
    }
    func initialise()
    {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(ChannelsSharedController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
        self.ChannelSharedTableView.addSubview(self.refreshControl)
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.ChannelSharedTableView.alwaysBounceVertical = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.updateChannelList), name: "SharedChannelList", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.pushNotificationUpdate), name: "PushNotification", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.pullToRefreshUpdate), name: "PullToRefreshSharedChannelList", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.mediaDeletePushNotificationSharing), name: "MediaDelete", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChannelsSharedController.deletedMediaFromArchieve), name: "StreamToChannelMedia", object:nil)
        newShareAvailabellabel.hidden = true
        if (ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count == 0)
        {
            self.showOverlay()
            let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
            let accessToken = NSUserDefaults.standardUserDefaults().valueForKey(userAccessTockenKey) as! String
            ChannelSharedListAPI.sharedInstance.getChannelSharedDetails(userId, token: accessToken)
            
        }else
        {
            self.showOverlay()
        }
    }
    
    func channelDeletionPushNotification(info:  [String : AnyObject])
    {
        let channelId = info["channelId"]!
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            var foundFlag : Bool = false
            
            for(var i = 0 ; i < ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count ; i++)
            {
                
                let channelIdValue = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[i][self.channelIdkey] as! String
                
                if (channelIdValue == "\(channelId)")
                {
                    foundFlag = true
                    break
                }
            }
            if(foundFlag)
            {
                self.deleteChannelFromSpecificRow("\(channelId)")
                
            }
        })
    }
    func deleteFromGlobal(channelId : Int , mediaArrayData : NSArray)
    {
        
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            var foundFlag : Bool = false
            
            for(var i = 0 ; i < ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count ; i++)
            {
                
                let channelIdValue = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[i][self.channelIdkey] as! String
                
                if (channelIdValue == "\(channelId)")
                {
                    foundFlag = true
                    break
                    
                }
            }
            if(foundFlag)
            {
                self.reloadSpecificRowMediaDeleted("\(channelId)", deletedMediaCount: mediaArrayData.count)
            }
        })
    }
    func mediaDeletePushNotificationSharing(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        let type =  info["type"] as! String
        if(type != "media")
        {
            let channelId = info["channelId"] as! Int
            let mediaArrayData  = info["mediaId"] as! NSArray
            deleteFromGlobal(channelId , mediaArrayData: mediaArrayData)
        }
    }
    func deletedMediaFromArchieve(notif : NSNotification)
    {
        let responseArrData = notif.object as! NSDictionary
        let keys = responseArrData.allKeys
        for( var channelIdIndex = 0 ; channelIdIndex < keys.count ; channelIdIndex += 1 )
        {
            let  deletedMediaCount : Int = responseArrData.valueForKey(keys[channelIdIndex] as! String) as! Int
            reloadSpecificRowMediaDeleted(keys[channelIdIndex] as! String,deletedMediaCount: Int(deletedMediaCount))
        }
    }
    func channelPushNotificationLiveStarted(info: [String : AnyObject])
    {
        // let info = notif.object as! [String : AnyObject]
        let subType = info["subType"] as! String
        
        switch subType {
        case "started":
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
                var pathArray :[NSIndexPath] = [NSIndexPath]()
                let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                //if(self.isVisibleCell(index))
                //  {
                self.ChannelSharedTableView.beginUpdates()
                pathArray.append(indexPath)
                self.ChannelSharedTableView.reloadRowsAtIndexPaths(pathArray, withRowAnimation: UITableViewRowAnimation.Left)
                self.ChannelSharedTableView.endUpdates()
                //  }
                
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
    func updateLiveStreamStoppeddEntry(info:[String : AnyObject])
    {
        let channelId = info["channelId"] as! Int
        let index  = getUpdateIndexChannel("\(channelId)", isCountArray: false)
        if(index != -1)
        {
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][ self.liveStreamStatus] = "0"
            ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][ self.streamTockenKey] = "0"
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                //  if(self.isVisibleCell(index))
                //  {
                self.ChannelSharedTableView.beginUpdates()
                var pathArray :[NSIndexPath] = [NSIndexPath]()
                let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                pathArray.append(indexPath)
                self.ChannelSharedTableView.reloadRowsAtIndexPaths(pathArray, withRowAnimation: UITableViewRowAnimation.Left)
                self.ChannelSharedTableView.endUpdates()
                //  }
            })
        }
        //        else{
        //            newShareAvailabellabel.hidden = false
        //            newShareAvailabellabel.text = "Live stream available"
        //
        //        }
        
    }
    
    func pushNotificationUpdate(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        if (info["type"] as! String == "share"){
            
            let channelId = info["channelId"] as! Int
            // Only show label while added new channel either increment count only
            // While deletion remove entry from global source and media array... its need to be implemented based on push notification parameter
            pushNotificationFlag = true
            //      newShareAvailabellabel.hidden = false
            if(self.downloadCompleteFlag == "end")
            {
                
            }
            else
            {
                newShareAvailabellabel.hidden = true
            }
            let chid : String = "\(channelId)"
            reloadSpecificRowMediaAdded(chid)
        }
        else if (info["type"] as! String == "channel")
        {
            
            if(info["subType"] as! String == "useradded")
            {
                newShareAvailabellabel.hidden = false
                newShareAvailabellabel.text = info[ "messageText"] as! String
                
            }
            else{
                
                channelDeletionPushNotification(info)
            }
        }
        else if (info["type"] as! String == "liveStream")
        {
            channelPushNotificationLiveStarted(info)
        }
    }
    func getUpdateIndexChannel(channelId : String , isCountArray : Bool) -> Int
    {
        var selectedArray : NSArray = NSArray()
        var indexOfRow : Int = Int()
        if(isCountArray)
        {
            if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
            {
                mediaShared.removeAll()
                mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
            }
            selectedArray = mediaShared as Array
            
        }
        else{
            selectedArray = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource
        }
        var  checkFlag : Bool = false
        for (index, element) in selectedArray.enumerate() {
            // do something with index
            if element[channelIdkey] as? String == channelId
            {
                indexOfRow = index
                checkFlag = true
            }
        }
        if (!checkFlag)
        {
            indexOfRow = -1
        }
        return indexOfRow
    }
    func deleteChannelFromSpecificRow(channelId : String)
    {
        let index  = getUpdateIndexChannel(channelId, isCountArray: true)
        if(index != -1)
        {
            mediaShared.removeAtIndex(index)
            NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            let rowIndex  = getUpdateIndexChannel(channelId, isCountArray: false)
            if(rowIndex != -1)
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.removeAtIndex(rowIndex)
                    
                    self.ChannelSharedTableView.reloadData()
                    //                    var pathArray :[NSIndexPath] = [NSIndexPath]()
                    //                    let indexPath: NSIndexPath = NSIndexPath(forRow: rowIndex, inSection: 0)
                    //                    pathArray.append(indexPath)
                    //                    self.ChannelSharedTableView.deleteRowsAtIndexPaths(pathArray, withRowAnimation: UITableViewRowAnimation.Left)
                    //                    self.ChannelSharedTableView.endUpdates()
                })
            }
        }
    }
    func  reloadSpecificRowMediaDeleted(channelId : String ,  deletedMediaCount : Int)
    {
        let index  = getUpdateIndexChannel(channelId, isCountArray: true)
        if(index != -1)
        {
            let sharedCount = mediaShared[index][sharedMediaCount] as! String
            let totalNo = mediaShared[index][totalNoShared] as! String
            let totalNoLatest : Int = Int(totalNo)! - deletedMediaCount
            if(totalNoLatest == 0)
            {
                mediaShared[index][sharedMediaCount]  = "0"
            }
            mediaShared[index][totalNoShared]  = "\(totalNoLatest)"
            NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            let rowIndex  = getUpdateIndexChannel(channelId, isCountArray: false)
            if(rowIndex != -1)
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let indexPath = NSIndexPath(forRow: rowIndex, inSection: 0)
                    if let visibleIndexPaths = self.ChannelSharedTableView.indexPathsForVisibleRows?.indexOf(indexPath) {
                        if visibleIndexPaths != NSNotFound {
                            self.ChannelSharedTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                        }
                    }
                    
                })
            }
        }
        pushNotificationFlag = false
    }
    func reloadSpecificRowMediaAdded(channelId : String)
    {
        
        let index  = getUpdateIndexChannel(channelId, isCountArray: true)
        if(index != -1)
        {
            let sharedCount = mediaShared[index][sharedMediaCount] as! String
            let totalNo = mediaShared[index][totalNoShared] as! String
            let  latestCount : Int = Int(sharedCount)! + 1
            let totalNoLatest : Int = Int(totalNo)! + 1
            if(latestCount == 1)
            {
                mediaShared[index][isWatched]  = "0"
            }
            mediaShared[index][sharedMediaCount]  = "\(latestCount)"
            mediaShared[index][totalNoShared]  = "\(totalNoLatest)"
            NSUserDefaults.standardUserDefaults().setObject(mediaShared, forKey: "Shared")
            let rowIndex  = getUpdateIndexChannel(channelId, isCountArray: false)
            if(rowIndex != -1)
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    //                    let indexPath = NSIndexPath(forRow: rowIndex, inSection: 0)
                    //                    if let visibleIndexPaths = self.ChannelSharedTableView.indexPathsForVisibleRows?.indexOf(indexPath) {
                    //                        if visibleIndexPaths != NSNotFound {
                    //                            self.ChannelSharedTableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    //                        }
                    //                    }
                    self.ChannelSharedTableView.reloadData()
                })
            }
        }
        pushNotificationFlag = false
    }
    func updateChannelList(notif : NSNotification)
    {
        self.refreshControl.endRefreshing()
        
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
                })
            }
            
        }
        else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                //  self.isWatchedTrue()
            })
        }
        
    }
    func pullToRefresh()
    {
        
        
        newShareAvailabellabel.hidden = true
        pullToRefreshActive = true
        let sortList : Array = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource
        var subIdArray : [Int] = [Int]()
        
        for(var i = 0 ; i < sortList.count ; i++)
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
                    
                    //  newShareAvailabellabel.hidden = true
                    isNeedRefresh = false
                    ChannelSharedListAPI.sharedInstance.dataSource.removeAll()
                    ChannelSharedListAPI.sharedInstance.dummy.removeAll()
                    ChannelSharedListAPI.sharedInstance.pullToRefreshSource.removeAll()
                    ChannelSharedListAPI.sharedInstance.pullToRefreshData("\(subid)")
                    
                }
                
            }
            else{
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            }
        }
        else
        {
            self.refreshControl.endRefreshing()
            self.pullToRefreshActive = false
            
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
                
                print(ChannelSharedListAPI.sharedInstance.pullToRefreshSource)
                
                for (var dataSourceIndex = ChannelSharedListAPI.sharedInstance.pullToRefreshSource.count - 1 ; dataSourceIndex >= 0 ; dataSourceIndex-- )
                {
                    var flag : Bool = false
                    for(var i = 0 ; i <  ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count ; i++)
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
                    //     if(self.isVisibleCell(0))
                    //   {
                    //                    self.ChannelSharedTableView.beginUpdates()
                    //                    self.ChannelSharedTableView.insertRowsAtIndexPaths([
                    //                        NSIndexPath(forRow: 0 , inSection: 0)
                    //                        ], withRowAnimation: .Automatic)
                    //                    self.ChannelSharedTableView.endUpdates()
                }
                self.ChannelSharedTableView.reloadData()
                
                //  }
            })
        }
        else{
            self.refreshControl.endRefreshing()
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
            //
            
            return ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count
            
        }
        else
        {
            // self.removeOverlay()
            
            return 0
            
        }
        
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count > 0)
        {
            if(indexPath.row == ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count - 1){
                self.removeOverlay()
            }
        }
        else{
            self.removeOverlay()
            
        }
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
                        let date = dateFormatter.dateFromString(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][timeStamp] as! String)
                        let fromdateStr = dateFormatter.stringFromDate(NSDate())
                        let fromdate = dateFormatter.dateFromString(fromdateStr)
                        let sdifferentString =  offsetFrom(date!, todate: fromdate!)
                        let count = (mediaShared[i][sharedMediaCount]?.intValue)!
                        let text = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String
                        if( count == 0)
                        {
                            cell.latestImage.hidden = false
                            cell.countLabel.hidden = true
                            cell.latestImage.image  = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][mediaImageKey] as? UIImage
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
        //  SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAll()
        //   SharedChannelDetailsAPI.sharedInstance.imageDataSource.removeAll()
        let chId = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
        let index  = getUpdateIndexChannel(chId, isCountArray: true)
        if(index != -1)
        {
            let totalCount = mediaShared[index][totalNoShared] as! String
            let sharedCount = mediaShared[index][sharedMediaCount] as! String
            if(totalCount != "0")
            {
                channelItemListVC.channelId = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
                channelItemListVC.channelName = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelNameKey] as! String
                channelItemListVC.totalMediaCount = Int(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][sharedMediaCount]! as! String)!
                channelItemListVC.userName = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String
                channelItemListVC.profileImage = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][profileImageKey] as! UIImage
                channelItemListVC.navigationController?.navigationBarHidden = true
                SharedChannelDetailsAPI.sharedInstance.getSubscribedChannelData(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
                    , selectedChannelName: ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelNameKey] as! String, selectedChannelUserName: ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String , sharedCount: sharedCount)
                self.navigationController?.pushViewController(channelItemListVC, animated: false)
            }
            else{
                if (ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][liveStreamStatus] as! String == "1")
                {
                    channelItemListVC.channelId = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
                    channelItemListVC.channelName = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelNameKey] as! String
                    channelItemListVC.totalMediaCount = Int(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][sharedMediaCount]! as! String)!
                    channelItemListVC.userName = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String
                    channelItemListVC.profileImage = ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][profileImageKey] as! UIImage
                    channelItemListVC.navigationController?.navigationBarHidden = true
                    SharedChannelDetailsAPI.sharedInstance.getSubscribedChannelData(ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelIdkey] as! String
                        , selectedChannelName: ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][channelNameKey] as! String, selectedChannelUserName: ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[indexPath.row][usernameKey] as! String , sharedCount: sharedCount)
                    self.navigationController?.pushViewController(channelItemListVC, animated: false)
                }
                else{
                    ErrorManager.sharedInstance.noShared()
                }
            }
        }
        
    }
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://\(vowzaIp):1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
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

  