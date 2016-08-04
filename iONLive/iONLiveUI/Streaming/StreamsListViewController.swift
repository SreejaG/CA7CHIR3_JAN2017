
import UIKit

class StreamsListViewController: UIViewController{
    
    let streamTockenKey = "wowza_stream_token"
    let imageKey = "image"
    let typeKey = "type"
    let imageType = "imageType"
    let timestamp = "last_updated_time_stamp"
    let channelIdkey = "ch_detail_id"
    let channelNameKey = "channel_name"
    let notificationKey = "notification"
    let userIdKey = "user_name"
    static let identifier = "StreamsListViewController"
    let imageUploadManger = ImageUpload.sharedInstance
    let profileManager = ProfileManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    var firstTap : Int = 0
    var offset: String = "0"
    var offsetToInt : Int = Int()
    let isWatched = "isWatched"
    let actualImageKey = "actualImage"
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var mediaAndLiveArray:[[String:AnyObject]] = [[String:AnyObject]]()
    let cameraController = IPhoneCameraViewController()
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    let timeKey = ""
    let thumbImageKey = "thumbImage"
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    var tapCount : Int = 0
    let livestreamingManager = LiveStreamingManager()
    let requestManager = RequestManager()
    var refreshControl:UIRefreshControl!
    var pullToRefreshActive = false
    var  liveStreamSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var count : Int = 0
    var limit : Int = 20
    var downloadCompleteFlag : String = "start"
    var lastContentOffset: CGPoint = CGPoint()
    @IBOutlet weak var streamListCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        firstTap = 0
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.streamListCollectionView.alwaysBounceVertical = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.streamUpdate), name: "stream", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(StreamsListViewController.mediaDeletePushNotification), name: "MediaDelete", object:nil)
        getAllLiveStreams()
        initialise()
        if GlobalStreamList.sharedInstance.GlobalStreamDataSource.count == 0
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh), forControlEvents: UIControlEvents.ValueChanged)
                self.streamListCollectionView.addSubview(self.refreshControl)
                self.showOverlay()
            })
            limit = 20
            count = 0
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
        
        //  var timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "pushNotificationUpdate", userInfo: nil, repeats: true)
    }
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (self.lastContentOffset.y < scrollView.contentOffset.y) {
            if(self.downloadCompleteFlag == "end")
            {
                do {
                    if(GlobalStreamList.sharedInstance.GlobalStreamDataSource.count < self.totalMediaCount)
                    {
                        if(self.downloadCompleteFlag == "end")
                        {
                            
                            
                            let sortList : Array = GlobalStreamList.sharedInstance.GlobalStreamDataSource
                            var subIdArray : [Int] = [Int]()
                            
                            for(var i = 0 ; i < sortList.count ; i++)
                            {
                                subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                                
                                //subIdArray[i] =            // subIdArray.arrayByAddingObject()
                                
                            }
                            print( subIdArray.minElement())
                            
                            let subid = subIdArray.minElement()!
                            //GlobalStreamList.sharedInstance.imageDataSource.removeAll()
                            // GlobalStreamList.sharedInstance.getMediaByOffset("\(subid)")
                            self.downloadCompleteFlag = "start"
                        }
                    }
                } catch {
                    print("do it error")
                }
            }
        }
        if (self.lastContentOffset.y > scrollView.contentOffset.y) {
            print("Scrolled Up");
        }
    }
    func sortFunc(num1: Int, num2: Int) -> Bool {
        return num1 < num2
    }
    func mediaDeletePushNotification(notif: NSNotification)
    {
        print ("inside notification ---->",  notif.object as! [String : AnyObject])
        let info = notif.object as! [String : AnyObject]
        print(info)
        let channelId = info["channelId"] as! Int
        let mediaArrayData  = info["mediaId"] as! NSArray
        var selectedArray :[Int] = [Int]()
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            for(var mediaArrayCount = 0 ; mediaArrayCount < mediaArrayData.count ; mediaArrayCount++)
            {
                var foundFlag : Bool = false
                var removeIndex : Int = Int()
                for(var i = 0 ; i < GlobalStreamList.sharedInstance.GlobalStreamDataSource.count ; i++)
                {
                    let channelIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.channelIdkey] as! String
                    
                    if ( channelIdValue == "\(channelId)")
                    {
                        let mediaIdValue = GlobalStreamList.sharedInstance.GlobalStreamDataSource[i][self.mediaIdKey] as! String
                        
                        if( mediaIdValue == "\(mediaArrayData[mediaArrayCount])" )
                        {
                            foundFlag = true
                            removeIndex = i
                            
                        }
                    }
                    
                }
                if(foundFlag)
                {
                    selectedArray.append(removeIndex)
                }
                
            }
        })
        selectedArray.sortInPlace()
        for(var i = 0 ; i < selectedArray.count ; i++)
        {
            GlobalStreamList.sharedInstance.GlobalStreamDataSource.removeAtIndex(selectedArray[i])
        }
        let qualityOfServiceClass1 = QOS_CLASS_BACKGROUND
        let backgroundQueue1 = dispatch_get_global_queue(qualityOfServiceClass1, 0)
        dispatch_async(backgroundQueue1, {
            self.removeFromMediaAndLiveArray(channelId, mediaData: mediaArrayData)
            
        })
    }
    func removeFromMediaAndLiveArray(channelId : Int,mediaData : NSArray)
    {
        var selectedArray :[Int] = [Int]()
        for(var mediaArrayCount = 0 ; mediaArrayCount < mediaData.count ; mediaArrayCount++)
        {
            var foundFlag : Bool = false
            var removeIndex : Int = Int()
            for(var i = 0 ; i < mediaAndLiveArray.count ; i++)
            {
                let channelIdValue = mediaAndLiveArray[i][channelIdkey] as! String
                if (channelIdValue == "\(channelId)")
                {
                    let mediaIdValue = mediaAndLiveArray[i][mediaIdKey] as! String
                    
                    if(mediaIdValue == "\(mediaData[mediaArrayCount])" )
                    {
                        foundFlag = true
                        removeIndex = i
                        break
                    }
                }
            }
            if(foundFlag)
            {
                selectedArray.append(removeIndex)
                foundFlag = false
                
            }
            
            
        }
        print(selectedArray)
        
        if(selectedArray.count > 0)
        {
            print(selectedArray)
            var pathArray : [NSIndexPath] = [NSIndexPath]()
            
            selectedArray = selectedArray.sort()
            for(var i = 0 ; i < selectedArray.count ; i++)
            {
                
                let index = selectedArray[i]
                let indexPath: NSIndexPath = NSIndexPath(forRow: index, inSection: 0)
                pathArray.append(indexPath)
                mediaAndLiveArray.removeAtIndex(index)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                self.streamListCollectionView.reloadData()
                print(self.mediaAndLiveArray.count)
            })
        }
        
        
    }
    func remove(pathArray : NSArray) {
        
        //   var indexPath: NSIndexPath = NSIndexPath(forRow: i, inSection: 0)
        var pathArray : [NSIndexPath] = [NSIndexPath]()
        // pathArray.append(indexPath)
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.streamListCollectionView.performBatchUpdates({
                self.streamListCollectionView.deleteItemsAtIndexPaths(pathArray)
                }, completion: {
                    (finished: Bool) in
                    //                              self.streamListCollectionView.reloadItemsAtIndexPaths(self.streamListCollectionView.indexPathsForVisibleItems())
                    
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
        print(selectedArray)
        var  checkFlag : Bool = false
        for (index, element) in selectedArray.enumerate() {
            // do something with index
            if element["mediaId"] as? String == channelId
            {
                indexOfRow = index
                print(indexOfRow)
                checkFlag = true
            }
        }
        if (!checkFlag)
        {
            indexOfRow = -1
        }
        print("\(indexOfRow)index--------->"  )
        return indexOfRow
    }
    func setSourceByAppendingMediaAndLive()
    {
        mediaAndLiveArray = self.liveStreamSource +  GlobalStreamList.sharedInstance.GlobalStreamDataSource
        streamListCollectionView.reloadData()
    }
    func streamUpdate(notif: NSNotification)
    {
        if(self.downloadCompleteFlag == "start")
        {
            downloadCompleteFlag = "end"
        }
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
                //  ErrorManager.sharedInstance.emptyMedia()
                self.setSourceByAppendingMediaAndLive()
                self.streamListCollectionView.reloadData()
            })
        }
    }
    func initialise()
    {
        totalMediaCount = 0
        firstTap = firstTap + 1
        if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
        {
            mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        }
        print(mediaShared)
        for i in 0 ..< mediaShared.count
        {
            totalMediaCount = totalMediaCount + Int(mediaShared[i]["totalNo"] as! String)!
        }
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
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
    
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func downloadMedia(downloadURL : NSURL ,key : String , completion: (result: UIImage) -> Void)
    {
        var mediaImage : UIImage = UIImage()
        let data = NSData(contentsOfURL: downloadURL)
        if let imageData = data as NSData? {
            if let mediaImage1 = UIImage(data: imageData)
            {
                mediaImage = mediaImage1
            }
            completion(result: mediaImage)
        }
        else
        {
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
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.197.92.137:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        self.presentViewController(vc, animated: false) { () -> Void in
        }
    }
    func pullToRefresh()
    {
        if(!pullToRefreshActive){
            
            pullToRefreshActive = true
            self.downloadCompleteFlag = "start"
            getAllLiveStreams()
            getPullToRefreshData()
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
            removeOverlay()
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
            }
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    func authenticationFailureHandlerForLiveStream(error: NSError?, code: String)
    {
        self.removeOverlay()
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                self.initialise()
            }
        }
        else{
            self.initialise()
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
            print(responseArrLive)
            if (responseArrLive.count != 0)
            {
                for element in responseArrLive{
                    let stremTockn = element[streamTockenKey] as! String
                    let userId = element[userIdKey] as! String
                    let channelIdSelected = element["ch_detail_id"]?.stringValue
                    let channelname = element[channelNameKey] as! String
                    let mediaId = element["live_stream_detail_id"]?.stringValue
                    let pulltorefresh = element["channel_live_stream_detail_id"]?.stringValue
                    var notificationType : String = String()
                    
                    if let notifType =  element["notification_type"] as? String
                    {
                        if notifType != ""
                        {
                            notificationType = (notifType as? String)!.lowercaseString
                        }
                        else{
                            notificationType = "shared"
                        }
                    }
                    else{
                        notificationType = "shared"
                    }
                    var imageForMedia : UIImage = UIImage()
                    let thumbUrlBeforeNullChk = element["live_stream_signedUrl"]
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
                    liveStreamSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:"", self.timestamp :currentDate,self.thumbImageKey:imageForMedia ,self.streamTockenKey:stremTockn,self.actualImageKey:"",self.userIdKey:userId,self.notificationKey:notificationType,self.mediaTypeKey:"live",self.timeKey:currentDate,self.channelNameKey:channelname, self.channelIdkey: channelIdSelected!,"createdTime":currentDate,pullTorefreshKey :pulltorefresh!])
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraVC = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        iPhoneCameraVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraVC, animated: false)
    }
    func  didSelectExtension(indexPathRow: Int)
    {
        getProfileImageSelectedIndex(indexPathRow)
    }
    func getProfileImageSelectedIndex(indexpathRow: Int)
    {
        let subUserName = GlobalStreamList.sharedInstance.GlobalStreamDataSource[indexpathRow][userIdKey] as! String
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        profileManager.getSubUserProfileImage(userId, accessToken: accessToken, subscriberUserName: subUserName, success: { (response) in
            self.successHandlerForProfileImage(response,indexpathRow: indexpathRow)
            }, failure: { (error, message) -> () in
                self.failureHandlerForprofileImage(error, code: message,indexPathRow:indexpathRow)
                return
        })
    }
    var profileImageUserForSelectedIndex : UIImage = UIImage()
    func successHandlerForProfileImage(response:AnyObject?,indexpathRow:Int)
    {
        if let json = response as? [String: AnyObject]
        {
            let profileImageNameBeforeNullChk = json["profile_image_thumbnail"]
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
        let mediaId = GlobalStreamList.sharedInstance.GlobalStreamDataSource[indexpathRow][mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow, profile: profile)
    }
    func getLikeCount(mediaId: String,indexpathRow:Int,profile:UIImage) {
        let mediaTypeSelected : String = GlobalStreamList.sharedInstance.GlobalStreamDataSource[indexpathRow][mediaTypeKey] as! String
        var likeCount: String = "0"
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
            likeCountSelectedIndex = json["likeCount"] as! String
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
        
        let type = mediaAndLiveArray[indexPathRow][mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            let dateString = mediaAndLiveArray[indexPathRow]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            let vc = MovieViewController.movieViewControllerWithImageVideo(mediaAndLiveArray[indexPathRow][self.actualImageKey] as! String, channelName: mediaAndLiveArray[indexPathRow][self.channelNameKey] as! String,channelId: mediaAndLiveArray[indexPathRow][self.channelIdkey] as! String, userName: mediaAndLiveArray[indexPathRow][self.userIdKey] as! String, mediaType:mediaAndLiveArray[indexPathRow][self.mediaTypeKey] as! String, profileImage: profileImage, videoImageUrl:mediaAndLiveArray[indexPathRow][self.mediaUrlKey] as! UIImage, notifType: mediaAndLiveArray[indexPathRow][self.notificationKey] as! String, mediaId: mediaAndLiveArray[indexPathRow][self.mediaIdKey] as! String,timeDiff:imageTakenTime,likeCountStr:likeCount) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = mediaAndLiveArray[indexPathRow][self.streamTockenKey] as! String
            print(streamTocken)
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName": mediaAndLiveArray[indexPathRow][self.channelNameKey] as! String, "userName":mediaAndLiveArray[indexPathRow][self.userIdKey] as! String, "mediaType":mediaAndLiveArray[indexPathRow][self.mediaTypeKey] as! String, "profileImage":profileImage, "notifType":mediaAndLiveArray[indexPathRow][self.notificationKey] as! String, "mediaId":mediaAndLiveArray[indexPathRow][self.mediaIdKey] as! String,"channelId":mediaAndLiveArray[indexPathRow][self.channelIdkey] as! String,"likeCount":likeCount as! String]
                let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.197.92.137:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                
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
                let type = mediaAndLiveArray[indexPath.row][mediaTypeKey] as! String
                if let imageThumb = mediaAndLiveArray[indexPath.row][thumbImageKey] as? UIImage
                {
                    
                    if type == "video"
                    {
                        cell.liveStatusLabel.hidden = false
                        cell.liveStatusLabel.text = ""
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
        //   if(!pullToRefreshActive){
        if  mediaAndLiveArray.count>0
        {
            if mediaAndLiveArray.count > indexPath.row
            {
                collectionView.alpha = 0.4
                showOverlay()
                didSelectExtension(indexPath.row)
            }
        }
        // }
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
