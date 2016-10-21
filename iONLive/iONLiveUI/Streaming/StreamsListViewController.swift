
import UIKit

class StreamsListViewController: UIViewController{
    static let identifier = "StreamsListViewController"
    let imageUploadManger = ImageUpload.sharedInstance
    let profileManager = ProfileManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    var channelId:String!
    var channelName:String!
    var firstTap : Int = 0
    var offset: String = "0"
    var offsetToInt : Int = Int()
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaAndLiveArray:[[String:AnyObject]] = [[String:AnyObject]]()
    let cameraController = IPhoneCameraViewController()
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    var tapCount : Int = 0
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    var  liveStreamSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var count : Int = 0
    var limit : Int = 27
    var scrollObj = UIScrollView()
    @IBOutlet weak var sharedNewMediaLabel: UILabel!
    var downloadCompleteFlagStream : String = "start"
    var lastContentOffset: CGPoint = CGPoint()
    var NoDatalabel : UILabel = UILabel()
    var selectedMediaId : String = String()
    var isMovieView : Bool = false
    var vc : MovieViewController = MovieViewController()
    var customView = CustomInfiniteIndicator()
    let isWatched = "isWatched"

    @IBOutlet weak var streamListCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        NSUserDefaults.standardUserDefaults().setValue("0", forKey: "notificationArrived")
        firstTap = 0
        sharedNewMediaLabel.hidden = true
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.streamListCollectionView.alwaysBounceVertical = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.streamUpdate), name: "stream", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.mediaDeletePushNotification), name: "MediaDelete", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.closeMovieView), name: "ShowAlert", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.pushNotificationUpdateStream), name: "PushNotificationStream", object:nil)
        getAllLiveStreams()
        showOverlay()
        createScrollViewAnimations()
        if GlobalStreamList.sharedInstance.GlobalStreamDataSource.count == 0
        {
            GlobalStreamList.sharedInstance.initialiseCloudData(count ,endValueLimit: limit)
            self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
            self.streamListCollectionView.addSubview(self.refreshControl)
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.setSourceByAppendingMediaAndLive()
                self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
                self.streamListCollectionView.addSubview(self.refreshControl)
                self.streamListCollectionView.reloadData()
            })
        }
        if NSUserDefaults.standardUserDefaults().objectForKey("NotificationText") != nil{
            if(NSUserDefaults.standardUserDefaults().objectForKey("NotificationText") as! String != "")
            {
                self.sharedNewMediaLabel.hidden = false
                self.sharedNewMediaLabel.text = "Pull to get new media"
            }
            NSUserDefaults.standardUserDefaults().setObject("", forKey: "NotificationText")
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        isMovieView = false
        super.viewWillAppear(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSUserDefaults.standardUserDefaults().setInteger(1, forKey: "SelectedTab")
        GlobalStreamList.sharedInstance.cancelOperationQueue()
        self.customView.removeFromSuperview()
    }
    func closeMovieView(notif : NSNotification)
    {
        vc.closeView()
    }
    func createScrollViewAnimations()  {
        streamListCollectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 40, 40))
        streamListCollectionView.infiniteScrollIndicatorMargin = 50
        streamListCollectionView.addInfiniteScrollWithHandler {  (scrollView) -> Void in
            if(!self.pullToRefreshActive)
            {
                let sortList : Array = GlobalStreamList.sharedInstance.GlobalStreamDataSource
                var subIdArray : [Int] = [Int]()
                self.scrollObj = scrollView
                for i in 0  ..< sortList.count
                {
                    subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                }
                if(subIdArray.count > 0)
                {
                    let subid = subIdArray.minElement()!
                    self.downloadCompleteFlagStream = "start"
                    GlobalStreamList.sharedInstance.getMediaByOffset("\(subid)")
                }
            }
            else
            {
                scrollView.finishInfiniteScroll()
            }
        }
    }
    
    func pushNotificationUpdateStream(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        if (info["type"] as! String == "liveStream")
        {
            channelPushNotificationLiveStarted(info)
        }
        else if(info["type"] as! String == "channel")
        {
            if(info["subType"] as! String == "useradded")
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sharedNewMediaLabel.hidden = false
                    self.sharedNewMediaLabel.text = "Pull to get new media"
                })
               
            }
            else{
                let channelId = info["channelId"]!
                deleteChannelSpecificMediaFromLocal("\(channelId)")
                deleteChannelSpecificMediaFromGlobal("\(channelId)")
            }
        }
        else if(info["type"] as! String == "share")
        {
            sharedNewMediaLabel.hidden = false
            sharedNewMediaLabel.text = "Pull to get new media"
        }
    }
    func deleteChannelSpecificMediaFromLocal(channelId : String)
    {
        var selectedArray : [Int] = [Int]()
        
        for i in 0  ..< mediaAndLiveArray.count 
        {
            let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
            if ( channelIdValue == "\(channelId)")
            {
                selectedArray.append(i)
            }
        }
        
        selectedArray =  selectedArray.sort()
        for i in 0  ..< selectedArray.count 
        {
            mediaAndLiveArray.removeAtIndex(selectedArray[i] - i)
        }
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if(self.mediaAndLiveArray.count == 0)
            {
                self.NoDatalabel.removeFromSuperview()
                self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                self.NoDatalabel.textAlignment = NSTextAlignment.Center
                self.NoDatalabel.text = "No Media Available"
                self.view.addSubview(self.NoDatalabel)
            }
            self.streamListCollectionView.reloadData()
        })
        getMediaWhileDeleted()

    }
    
    func deleteChannelSpecificMediaFromGlobal(channelId : String)
    {
        var selectedArray : [Int] = [Int]()
        
        for i in 0  ..< GlobalStreamList.sharedInstance.GlobalStreamDataSource.count 
        {
            let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][channelIdkey] as! String
            if (channelIdValue == "\(channelId)")
            {
                selectedArray.append(i)
            }
        }
        
        selectedArray =  selectedArray.sort()
        for i in 0  ..< selectedArray.count 
        {
            GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i] - i)
        }
    }
    
    func channelPushNotificationLiveStarted(info: [String : AnyObject])
    {
        let subType = info["subType"] as! String
        switch subType {
        case "started":
            ErrorManager.sharedInstance.streamAvailable()
            updateLiveStreamStartedEntry(info)
            sharedNewMediaLabel.hidden = false
            sharedNewMediaLabel.text = "Pull to get live stream"
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
    }
    
    func updateLiveStreamStoppeddEntry(info:[String : AnyObject])
    {
        let channelId = info["channelId"] as! Int
        let livStreamId = info ["liveStreamId"] as! Int
        var  checkFlag : Bool = false
        var removeIndex : Int = Int()
        for (index, element) in mediaAndLiveArray.enumerate() {
            if element[channelIdkey] as? String == "\(channelId)"
            {
                if(element[stream_mediaIdKey] as? String == "\(livStreamId)")
                {
                    removeIndex = index
                    checkFlag = true
                }
            }
        }
        if checkFlag
        {
            mediaAndLiveArray.removeAtIndex(removeIndex)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(self.mediaAndLiveArray.count == 0)
                {
                    self.NoDatalabel.removeFromSuperview()
                    self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                    self.NoDatalabel.textAlignment = NSTextAlignment.Center
                    self.NoDatalabel.text = "No Media Available"
                    self.view.addSubview(self.NoDatalabel)
                }
                self.streamListCollectionView.reloadData()
            })
        }
    }
    func getMediaWhileDeleted()
    {
        if(mediaAndLiveArray.count <  18 && mediaAndLiveArray.count != 0)
        {
            if(!self.pullToRefreshActive)
            {
                let sortList : Array = self.mediaAndLiveArray
                var subIdArray : [Int] = [Int]()
                
                for i in 0  ..< sortList.count 
                {
                    subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                }
                if(subIdArray.count > 0)
                {
                  //  showOverlay()
                    let subid = subIdArray.minElement()!
                    self.downloadCompleteFlagStream = "start"
                    GlobalStreamList.sharedInstance.getMediaByOffset("\(subid)")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.customView.removeFromSuperview()
                        self.streamListCollectionView.userInteractionEnabled = false
                        self.customView  = CustomInfiniteIndicator(frame: CGRectMake(self.streamListCollectionView.layer.frame.width/2 - 20, self.streamListCollectionView.layer.frame.height - 100, 40, 40))
                        self.streamListCollectionView.addSubview(self.customView)
                        self.customView.startAnimating()
                    })
                }
            }
        }
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
            }
            selectedArray = mediaShared as Array
        }
        else{
            selectedArray = mediaAndLiveArray
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
        if (checkFlag)
        {
            indexOfRow = index
        }
        return indexOfRow
    }
    
    func mediaDeletePushNotification(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        let type =  info["type"] as! String
        dispatch_async(dispatch_get_main_queue()) {

        let refreshAlert = UIAlertController(title: "Deleted", message: "Shared media deleted.", preferredStyle: UIAlertControllerStyle.Alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
        }))
        
        self.presentViewController(refreshAlert, animated: true, completion: nil)
        }
        if(type == "media")
        {
            //delete media from archive
            self.getDataUsingNotificationId(info)
        }
        else{
            let channelId = info["channelId"] as! Int
            let mediaArrayData  = info["mediaId"] as! NSArray
            self.removeDataFromGlobal(channelId, mediaArrayData: mediaArrayData)
            self.deleteFromOtherChannelIfExist(mediaArrayData)
        }
    }
    func removeDataFromGlobal(channelId : Int , mediaArrayData : NSArray)
    {
        var selectedArray :[Int] = [Int]()
        for mediaArrayCount in 0  ..< mediaArrayData.count 
        {
            var foundFlag : Bool = false
            var removeIndex : Int = Int()
            for i in 0  ..< GlobalStreamList.sharedInstance.GlobalStreamDataSource.count
            {
                let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][channelIdkey] as! String
                
                if ( channelIdValue == "\(channelId)")
                {
                    if(i < GlobalStreamList.sharedInstance.GlobalStreamDataSource.count)
                    {
                        let mediaIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][stream_mediaIdKey] as! String
                        
                        if( mediaIdValue == "\(mediaArrayData[mediaArrayCount])" )
                        {
                            foundFlag = true
                            removeIndex = i
                        }
                    }
                }
            }
            if(foundFlag)
            {
                selectedArray.append(removeIndex)
            }
        }
        selectedArray.sortInPlace()
        for i in 0  ..< selectedArray.count 
        {
            if(GlobalStreamList.sharedInstance.GlobalStreamDataSource.count > 0)
            {
                GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i]-i)
            }
        }
        self.removeFromMediaAndLiveArray(channelId, mediaData: mediaArrayData)
    }
    
    func getDataUsingNotificationId(info : [String : AnyObject])
    {
        let notifId : Int = info["notificationId"] as! Int
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey) as! String
        let accessTocken = userDefault.objectForKey(userAccessTockenKey) as! String
        channelManager.getDataByNotificationId(loginId, accessToken: accessTocken, notificationId: "\(notifId)", success: { (response) in
            self.getAllChannelIdsSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandlerForLiveStream(error, code: message)
        }
    }
    
    func getAllChannelIdsSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["notificationMessage"] as! String
            let responseArrData = convertStringToDictionary1(responseArr)
            let channelIdArray : NSArray = responseArrData!["channelId"] as! NSArray
            let mediaArrayData : NSArray = responseArrData!["mediaId"] as! NSArray
            deleteFromLocal(channelIdArray, mediaArrayData: mediaArrayData)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.streamListCollectionView.reloadData()
            })
            self.deleteFromGlobal(channelIdArray, mediaArrayData: mediaArrayData)
            self.deleteFromOtherChannelIfExist(mediaArrayData)
        }
    }
    
    func deleteFromOtherChannelIfExist( mediaArrayData : NSArray)
    {
        if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
        {
            var selectedArray : [Int] = [Int]()
            for i in 0  ..< SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count
            {
                var foundFlag : Bool = false
                if(i < SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count)
                {
                    var  count : Int = 0
                    let mediaId = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[i][stream_mediaIdKey] as! String
                    
                    for mediaArrayCount in 0  ..< mediaArrayData.count 
                    {
                        if("\(mediaArrayData[mediaArrayCount])" == mediaId)
                        {
                            NSNotificationCenter.defaultCenter().postNotificationName("ViewMediaDeleted", object: mediaId)
                            count = count + 1
                            foundFlag = true
                            break;
                        }
                    }
                }
                if(foundFlag)
                {
                    foundFlag = false
                    selectedArray.append(i)
                }
            }
            
            selectedArray =  selectedArray.sort()
            for i in 0  ..< selectedArray.count 
            {
                SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAtIndex(selectedArray[i] - i)
            }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName("DeletedObject", object: nil)
    }
    
    func deleteFromGlobal (channelIdArray : NSArray, mediaArrayData : NSArray)
    {
        var selectedArray : [Int] = [Int]()
        for j in 0  ..< channelIdArray .count 
        {
            let channel = channelIdArray[j] as! Int
            
            for i in 0  ..< GlobalStreamList.sharedInstance.GlobalStreamDataSource.count 
            {
                let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][channelIdkey] as! String
                var foundFlag : Bool = false
                
                if ( channelIdValue == "\(channel)")
                {
                    if(i < GlobalStreamList.sharedInstance.GlobalStreamDataSource.count)
                    {
                        var  count : Int = 0
                        let mediaId = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][stream_mediaIdKey] as! String
                        
                        for mediaArrayCount in 0  ..< mediaArrayData.count
                        {
                            if("\(mediaArrayData[mediaArrayCount])" == mediaId)
                            {
                                count = count + 1
                                foundFlag = true
                                break;
                            }
                        }
                    }
                    
                    if(foundFlag)
                    {
                        foundFlag = false
                        selectedArray.append(i)
                    }
                }
            }
        }
        
        selectedArray =  selectedArray.sort()
        for i in 0  ..< selectedArray.count
        {
            GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i] - i)
        }
    }
    
    func deleteFromLocal (channelIdArray : NSArray, mediaArrayData : NSArray)
    {
        var selectedArray : [Int] = [Int]()
        var channelIDCount : [String : AnyObject] = [String : AnyObject]()
        
        for j in 0  ..< channelIdArray .count 
        {
            let channel = channelIdArray[j] as! Int
            for i in 0  ..< mediaAndLiveArray.count 
            {
                let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
                var foundFlag : Bool = false
                var  count : Int = 0
                if (channelIdValue == "\(channel)")
                {
                    if(i < mediaAndLiveArray.count)
                    {
                        let mediaId = mediaAndLiveArray[i][stream_mediaIdKey] as! String
                        for mediaArrayCount in 0  ..< mediaArrayData.count
                        {
                            if("\(mediaArrayData[mediaArrayCount])" == selectedMediaId)
                            {
                                if isMovieView
                                {
                                    self.vc.mediaDeletedErrorMessage()
                                    self.isMovieView = false
                                }
                            }
                            
                            if("\(mediaArrayData[mediaArrayCount])" == mediaId)
                            {
                                let obj : SetUpView = SetUpView()
                                obj.callDelete(vc, mediaId: mediaId)
                                count = count + 1
                                foundFlag = true
                                break;
                            }
                            
                        }
                        
                        if(foundFlag)
                        {
                            foundFlag = false
                            channelIDCount.updateValue(count, forKey: channelIdValue)
                            selectedArray.append(i)
                        }
                    }
                }
            }
        }
        selectedArray =  selectedArray.sort()
        for i in 0  ..< selectedArray.count
        {
            mediaAndLiveArray.removeAtIndex(selectedArray[i] - i)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if(self.mediaAndLiveArray.count == 0)
            {
                self.NoDatalabel.removeFromSuperview()
                self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                self.NoDatalabel.textAlignment = NSTextAlignment.Center
                self.NoDatalabel.text = "No Media Available"
                self.view.addSubview(self.NoDatalabel)
            }
        })
        getMediaWhileDeleted()
        NSNotificationCenter.defaultCenter().postNotificationName("StreamToChannelMedia", object: channelIDCount)
    }
    
    func convertStringToDictionary1(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch _ as NSError {
            }
        }
        return nil
    }
    
    func convertStringToDictionary(text: String) -> NSArray? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? NSArray
            } catch _ as NSError {
            }
        }
        return nil
    }
    
    func removeLiveFromMediaAndLiveArray(channelId : Int,type : String)
    {
        var selectedArray :[Int] = [Int]()
        var foundFlag : Bool = false
        var removeIndex : Int = Int()
        for i in 0  ..< mediaAndLiveArray.count 
        {
            let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
            if (channelIdValue == "\(channelId)")
            {
                if(i < mediaAndLiveArray.count)
                {
                    let mediaIdValue = mediaAndLiveArray[i][stream_mediaTypeKey] as! String
                    if(mediaIdValue == "live" )
                    {
                        foundFlag = true
                        removeIndex = i
                        break
                    }
                }
            }
        }
        if(foundFlag)
        {
            selectedArray.append(removeIndex)
            foundFlag = false
        }
        if(selectedArray.count > 0)
        {
            var pathArray : [NSIndexPath] = [NSIndexPath]()
            selectedArray = selectedArray.sort()
            for i in 0  ..< selectedArray.count 
            {
                let index = selectedArray[i]
                let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                pathArray.append(indexPath)
                mediaAndLiveArray.removeAtIndex(index)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.streamListCollectionView.reloadData()
            })
        }
    }
    
    func removeFromMediaAndLiveArray(channelId : Int,mediaData : NSArray)
    {
        var selectedArray :[Int] = [Int]()
        for mediaArrayCount in 0  ..< mediaData.count 
        {
            var foundFlag : Bool = false
            var removeIndex : Int = Int()
            for i in 0  ..< mediaAndLiveArray.count
            {
                let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
                if (channelIdValue == "\(channelId)")
                {
                    if(i < mediaAndLiveArray.count)
                    {
                        let mediaIdValue = mediaAndLiveArray[i][stream_mediaIdKey] as! String
                        if("\(mediaData[mediaArrayCount])" == selectedMediaId)
                        {
                            if isMovieView
                            {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.vc.mediaDeletedErrorMessage()
                                    self.isMovieView = false
                                })
                            }
                        }
                        if(mediaIdValue == "\(mediaData[mediaArrayCount])" )
                        {
                            let obj : SetUpView = SetUpView()
                            obj.callDelete(vc, mediaId: mediaIdValue)
                            foundFlag = true
                            removeIndex = i
                            break
                        }
                    }
                }
            }
            if(foundFlag)
            {
                selectedArray.append(removeIndex)
                foundFlag = false
            }
        }
        if(selectedArray.count > 0)
        {
            var pathArray : [NSIndexPath] = [NSIndexPath]()
            selectedArray = selectedArray.sort()
            for i in 0  ..< selectedArray.count
            {
                if(mediaAndLiveArray.count > 0)
                {
                    let index = selectedArray[i]
                    let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                    pathArray.append(indexPath)
                    mediaAndLiveArray.removeAtIndex(index - i)
                }
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(self.mediaAndLiveArray.count == 0)
                {
                    self.NoDatalabel.removeFromSuperview()
                    self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                    self.NoDatalabel.textAlignment = NSTextAlignment.Center
                    self.NoDatalabel.text = "No Media Available"
                    self.view.addSubview(self.NoDatalabel)
                }
                self.streamListCollectionView.reloadData()
            })
        }
        getMediaWhileDeleted()

    }
    
    func remove(pathArray : NSArray) {
        
        let pathArray : [NSIndexPath] = [NSIndexPath]()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.streamListCollectionView.performBatchUpdates({
                self.streamListCollectionView.deleteItemsAtIndexPaths(pathArray)
                }, completion: {
                    (finished: Bool) in
            })
        })
    }
    
    func getUpdateIndex(channelId : String , isCountArray : Bool) -> Int
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
            selectedArray = GlobalStreamList.sharedInstance.GlobalStreamDataSource
        }
        var  checkFlag : Bool = false
        for (index, element) in selectedArray.enumerate() {
            if element["mediaId"] as? String == channelId
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
    
    func setSourceByAppendingMediaAndLive()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mediaAndLiveArray.removeAll()
            self.mediaAndLiveArray = self.liveStreamSource +  GlobalStreamList.sharedInstance.GlobalStreamDataSource
            if(self.mediaAndLiveArray.count > 0)
            {
                self.NoDatalabel.removeFromSuperview()
            }
            self.streamListCollectionView.reloadData()
        })
        print(mediaAndLiveArray)
        print(GlobalStreamList)
    }
    
    func streamUpdate(notif: NSNotification)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("RemoveOverlay", object: nil)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.scrollObj.finishInfiniteScroll()
            self.scrollObj = UIScrollView()
            if(self.downloadCompleteFlagStream == "start")
            {
                self.downloadCompleteFlagStream = "end"
            }
        })
        if(pullToRefreshActive){
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            })
        }
        let success =  notif.object as! String
        if(success == "success")
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.setSourceByAppendingMediaAndLive()
                self.streamListCollectionView.reloadData()
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                if(self.liveStreamSource.count > 0)
                {
                    self.setSourceByAppendingMediaAndLive()
                    self.streamListCollectionView.reloadData()
                }
                else{
                    self.mediaAndLiveArray.removeAll()
                    self.mediaAndLiveArray = GlobalStreamList.sharedInstance.GlobalStreamDataSource
                    self.NoDatalabel.removeFromSuperview()
                    if(self.mediaAndLiveArray.count == 0)
                    {
                        self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                        self.NoDatalabel.textAlignment = NSTextAlignment.Center
                        self.NoDatalabel.text = "No Media Available"
                        self.view.addSubview(self.NoDatalabel)
                    }
                    self.streamListCollectionView.reloadData()
                }
            })
        }
         dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.streamListCollectionView.userInteractionEnabled = true
            self.customView.stopAnimationg()
            self.customView.removeFromSuperview()
        })
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        
        // Data object to fetch weather data
        do {
            let data = try NSData(contentsOfURL: downloadURL,options: NSDataReadingOptions())
            if let imageData = data as NSData? {
                if let mediaImage1 = UIImage(data: imageData)
                {
                    mediaImage = mediaImage1
                }
                else{
                    
                    mediaImage = UIImage(named: "thumb12")!
                }

                completion(result: mediaImage)
            }
            else
            {
                completion(result:UIImage(named: "thumb12")!)
            }
            
        } catch {
            completion(result:UIImage(named: "thumb12")!)
        }
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
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://\(vowzaIp):1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        self.presentViewController(vc, animated: false) { () -> Void in
        }
    }
    
    func pullToRefresh()
    {
        NSUserDefaults.standardUserDefaults().setObject("", forKey: "NotificationText")
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.sharedNewMediaLabel.hidden = true
            self.NoDatalabel.removeFromSuperview()
        })
        if(!pullToRefreshActive){
            pullToRefreshActive = true
            self.downloadCompleteFlagStream = "start"
            if(mediaAndLiveArray.count > 0){
                self.getAllLiveStreams()
                self.getPullToRefreshData()
            }
            else{
                self.downloadCompleteFlagStream = "start"
                self.getAllLiveStreams()
                GlobalStreamList.sharedInstance.imageDataSource.removeAll()
                GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAll()
                GlobalStreamList.sharedInstance.initialiseCloudData(count ,endValueLimit: limit)
            }
        }
        else
        {
        }
    }
    
    func getPullToRefreshData()
    {
        GlobalStreamList.sharedInstance.getPullToRefreshData()
    }
    
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        liveStreamSource.removeAll()
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        if let loginId = loginId, let accessTocken = accessTocken
        {
            livestreamingManager.getAllLiveStreams(loginId:loginId as! String , accesstocken:accessTocken as! String ,success: { (response) -> () in
                self.getAllStreamSuccessHandler(response)
                }, failure: { (error, message) -> () in
                    self.authenticationFailureHandlerForLiveStream(error, code: message)
                    return
            })
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                })
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
            }
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func authenticationFailureHandlerForLiveStream(error: NSError?, code: String)
    {
        if !self.requestManager.validConnection() {
            self.removeOverlay()
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                self.removeOverlay()
            }
        }
        else{
            self.removeOverlay()

        }
    }
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func getAllStreamSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            let responseArrLive = json["liveStreams"] as! [[String:AnyObject]]
            if (responseArrLive.count != 0)
            {
                for element in responseArrLive{
                    let stremTockn = element[stream_streamTockenKey] as! String
                    let userId = element[userIdKey] as! String
                    let channelIdSelected = element["channel_detail_id"]?.stringValue
                    let channelname = element[stream_channelNameKey] as! String
                    let mediaId = element["live_stream_detail_id"]?.stringValue
                    let pulltorefresh = element["channel_live_stream_detail_id"]?.stringValue
                    let notificationType : String = ""
                    let thumbUrlBeforeNullChk =  UrlManager.sharedInstance.getLiveThumbUrlApi(mediaId!)
                    var imageForMedia : UIImage = UIImage()
                    let thumbUrl = nullToNil(thumbUrlBeforeNullChk) as! String
                    if(thumbUrl != ""){
                        let url: NSURL = convertStringtoURL(thumbUrl)
                        downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                            if(result != UIImage()){
                                imageForMedia = result
                            }
                        })
                    }
                    else{
                        imageForMedia = UIImage(named: "thumb12")!
                    }
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    dateFormatter.timeZone = NSTimeZone(name: "UTC")
                    let currentDate = dateFormatter.stringFromDate(NSDate())
                    liveStreamSource.append([stream_mediaIdKey:mediaId!, mediaUrlKey:"", timestamp :currentDate,stream_thumbImageKey:imageForMedia ,stream_streamTockenKey:stremTockn,actualImageKey:"",userIdKey:userId,notificationKey:notificationType,stream_mediaTypeKey:"live",timeKey:currentDate,stream_channelNameKey:channelname, channelIdkey: channelIdSelected!,"createdTime":currentDate,pullTorefreshKey :pulltorefresh!])
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if(self.mediaAndLiveArray.count == 0)
                    {
                        if(self.liveStreamSource.count > 0)
                        {
                            self.setSourceByAppendingMediaAndLive()
                        }
                    }
                    else
                    {
                        if(self.liveStreamSource.count > 0)
                        {
                            self.setSourceByAppendingMediaAndLive()
                        }
                    }
                    self.streamListCollectionView.reloadData()
                })
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func loadStaticImagesOnly()
    {
        self.streamListCollectionView.reloadData()
    }
    
    @IBAction func customBackButtonClicked(sender: AnyObject)
    {
        SharedChannelDetailsAPI.sharedInstance.imageDataSource.removeAll()
        SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAll()
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    
    func  didSelectExtension(indexPathRow: Int)
    {
        getProfileImageSelectedIndex(indexPathRow)
    }
    
//    func getProfileImage(userId: String)
//    {
//        
//    }
    var profileImageUserForSelectedIndex : UIImage = UIImage()

    func getProfileImageSelectedIndex(indexpathRow: Int)
    {
        if(mediaAndLiveArray.count > 0)
        {
            let subUserName = mediaAndLiveArray[indexpathRow][userIdKey] as! String
            let profileImageNameBeforeNullChk =  UrlManager.sharedInstance.getProfileURL(subUserName)
            let profileImageName = self.nullToNil(profileImageNameBeforeNullChk) as! String
            if(profileImageName != "")
            {
                let url: NSURL = self.convertStringtoURL(profileImageName)
                if let data = NSData(contentsOfURL: url){
                    let imageDetailsData = (data as NSData?)!
                    profileImageUserForSelectedIndex = UIImage(data: imageDetailsData)!
                }
                else{
                    profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
                }
            }
            else{
                profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
            }
            
        }
        else{
            profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        }
        getLikeCountForSelectedIndex(indexpathRow,profile: profileImageUserForSelectedIndex)
    }
    func failureHandlerForprofileImage(error: NSError?, code: String,indexPathRow:Int)
    {
        profileImageUserForSelectedIndex = UIImage(named: "dummyUser")!
        getLikeCountForSelectedIndex(indexPathRow,profile: profileImageUserForSelectedIndex)
    }
    
    func getLikeCountForSelectedIndex(indexpathRow:Int,profile:UIImage)  {
        let mediaId = mediaAndLiveArray[indexpathRow][stream_mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow, profile: profile)
    }
    
    func getLikeCount(mediaId: String,indexpathRow:Int,profile:UIImage) {
        let mediaTypeSelected : String = mediaAndLiveArray[indexpathRow][stream_mediaTypeKey] as! String
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        channelManager.getMediaLikeCountDetails(userId, accessToken: accessToken, mediaId: mediaId, mediaType: mediaTypeSelected, success: { (response) in
            self.successHandlerForMediaCount(response,indexpathRow:indexpathRow,profile: profile)
            }, failure: { (error, message) -> () in
                self.failureHandlerForMediaCount(error, code: message,indexPathRow:indexpathRow,profile: profile)
                return
        })
    }
    
    var likeCountSelectedIndex : String = "0"
    
    func successHandlerForMediaCount(response:AnyObject?,indexpathRow:Int,profile:UIImage)
    {
        if let json = response as? [String: AnyObject]
        {
            likeCountSelectedIndex = "\(json["likeCount"]!)"
        }
        loadmovieViewController(indexpathRow, profileImage: profile, likeCount: likeCountSelectedIndex)
    }
    
    func failureHandlerForMediaCount(error: NSError?, code: String,indexPathRow:Int,profile:UIImage)
    {
        likeCountSelectedIndex = "0"
        loadmovieViewController(indexPathRow, profileImage: profile, likeCount: likeCountSelectedIndex)
    }
    
    func loadmovieViewController(indexPathRow:Int,profileImage:UIImage,likeCount:String) {
        
        self.removeOverlay()
        streamListCollectionView.alpha = 1.0
        let index = Int32(indexPathRow)
        let type = mediaAndLiveArray[indexPathRow][stream_mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            isMovieView = true
            selectedMediaId = mediaAndLiveArray[indexPathRow][stream_mediaIdKey] as! String
            let dateString = mediaAndLiveArray[indexPathRow]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            vc = MovieViewController.movieViewControllerWithImageVideo(mediaAndLiveArray[indexPathRow][stream_channelNameKey] as! String,channelId: mediaAndLiveArray[indexPathRow][channelIdkey] as! String, userName: mediaAndLiveArray[indexPathRow][userIdKey] as! String, mediaType:mediaAndLiveArray[indexPathRow][stream_mediaTypeKey] as! String, profileImage: profileImage, videoImageUrl:mediaAndLiveArray[indexPathRow][mediaUrlKey] as! UIImage, notifType: mediaAndLiveArray[indexPathRow][notificationKey] as! String, mediaId: mediaAndLiveArray[indexPathRow][stream_mediaIdKey] as! String,timeDiff:imageTakenTime,likeCountStr:likeCount, selectedItem: index,pageIndicator: 1) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = mediaAndLiveArray[indexPathRow][stream_streamTockenKey] as! String
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName": mediaAndLiveArray[indexPathRow][stream_channelNameKey] as! String, "userName":mediaAndLiveArray[indexPathRow][userIdKey] as! String, "mediaType":mediaAndLiveArray[indexPathRow][stream_mediaTypeKey] as! String, "profileImage":profileImage, "notifType":mediaAndLiveArray[indexPathRow][notificationKey] as! String, "mediaId":mediaAndLiveArray[indexPathRow][stream_mediaIdKey] as! String,"channelId":mediaAndLiveArray[indexPathRow][channelIdkey] as! String,"likeCount":likeCount ]
                vc = MovieViewController.movieViewControllerWithContentPath("rtsp://\(vowzaIp):1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false)  as! MovieViewController
                
                
                self.presentViewController(vc, animated: false) { () -> Void in
                }
            }
            else
            {
                ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
            }
        }
    }
}

extension StreamsListViewController:UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if  mediaAndLiveArray.count > 0
        {
            return mediaAndLiveArray.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("StreamListCollectionViewCell", forIndexPath: indexPath) as! StreamListCollectionViewCell
        
        if  mediaAndLiveArray.count > 0
        {
            if mediaAndLiveArray.count > indexPath.row
            {
                let type = mediaAndLiveArray[indexPath.row][stream_mediaTypeKey] as! String
                
                if let imageThumb = mediaAndLiveArray[indexPath.row][stream_thumbImageKey] as? UIImage
                {
                    
                    if type == "video"
                    {
                        let vDuration  = mediaAndLiveArray[indexPath.row][videoDurationKey] as! String
                        cell.liveStatusLabel.hidden = false
                        cell.liveStatusLabel.text = vDuration
                        cell.liveNowIcon.hidden = false
                        cell.liveNowIcon.image = UIImage(named: "Live_now_off_mode")
                        cell.streamThumbnaleImageView.image = imageThumb
                    }
                    else if type == "image"{
                        
                        cell.liveStatusLabel.hidden = true
                        cell.liveNowIcon.hidden = true
                        cell.streamThumbnaleImageView.image = imageThumb
                    }
                    else
                    {
                        cell.liveStatusLabel.hidden = false
                        cell.liveStatusLabel.text = "LIVE"
                        cell.liveNowIcon.hidden = false
                        cell.liveNowIcon.image = UIImage(named: "Live_now")
                        cell.streamThumbnaleImageView.image = imageThumb
                    }
                }
            }
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if  mediaAndLiveArray.count>0
        {
            if mediaAndLiveArray.count > indexPath.row
            {
                collectionView.alpha = 0.4
                showOverlay()
                didSelectExtension(indexPath.row)
            }
        }
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(1, 1, 0, 1)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSizeMake((UIScreen.mainScreen().bounds.width/3)-2, 100)
    }
}

extension Dictionary {
    mutating func update(other:Dictionary) {
        for (key,value) in other {
            self.updateValue(value, forKey:key)
        }
    }
}
