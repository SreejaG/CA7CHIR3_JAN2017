
import UIKit

class OtherChannelViewController: UIViewController  {
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    static let identifier = "OtherChannelViewController"
    var lastContentOffset: CGPoint = CGPoint()
    var totalMediaCount: String = String()
    var channelId:String!
    var channelName:String!
    var userName:String!
    var profileImage : UIImage!
    var offset: String = "0"
    var offsetToInt : Int = Int()
    let isWatched = "isWatched"
    var loadingOverlay: UIView?
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    let cameraController = IPhoneCameraViewController()
    var refreshControl:UIRefreshControl!
    var limit : Int = Int()
    var fixedLimit : Int =  0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()
    var downloadCompleteFlag : String = "start"
    var pullToRefreshActive = false
    @IBOutlet weak var channelItemsCollectionView: UICollectionView!
    @IBOutlet weak var channelTitleLabel: UILabel!
    let sharedMediaCount = "total_no_media_shared"
    var scrollObj = UIScrollView()
    var NoDatalabel : UILabel = UILabel()
    var liveStreamFlag : Bool = false
    var vc : MovieViewController = MovieViewController()
    var customView = CustomInfiniteIndicator()

    @IBOutlet weak var notificationLabel: UILabel!
    override func viewDidLoad()
    {
        super.viewDidLoad()
            NSNotificationCenter.defaultCenter().removeObserver(self)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.updateChannelMediaList), name: "SharedChannelMediaDetail", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.ObjectDeleted), name: "DeletedObject", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.pushNotificationUpdateStream), name: "PushNotification", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.checkCountIncrementInSelectedChannel), name: "CountIncrementedPushNotification", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.dismissFullView), name: "ViewMediaDeleted", object:nil)
        self.notificationLabel.hidden = true
        self.refreshControl = UIRefreshControl()
        self.channelItemsCollectionView.alwaysBounceVertical = true
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh),forControlEvents :
            UIControlEvents.ValueChanged)
        self.channelItemsCollectionView.addSubview(self.refreshControl)
        isWatchedTrue()
        createScrollViewAnimations()
        
        showOverlay()
        SharedChannelDetailsAPI.sharedInstance.getSubscribedChannelData(channelId
            , selectedChannelName: channelName, selectedChannelUserName: userName , sharedCount: totalMediaCount)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        channelItemsCollectionView.alpha = 1.0
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
     //   NSNotificationCenter.defaultCenter().removeObserver(self)
        channelItemsCollectionView.alpha = 1.0
        self.customView.removeFromSuperview()

    }
    func dismissFullView(notif: NSNotification)
    {
        let mediaId = notif.object as! String
        let obj : SetUpView = SetUpView()
      //  vc.mediaDeletedErrorMessage()
        obj.callDelete(vc, mediaId: mediaId)
        dispatch_async(dispatch_get_main_queue()) {
         //   self.channelItemsCollectionView.reloadData()
        }
        
    }
    func pushNotificationUpdateStream(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        if (info["type"] as! String == "liveStream")
        {
            channelPushNotificationLiveStarted(info)
        }
        else if (info["type"] as! String == "channel")
        {
            if (info["subType"] as! String == "deleted")
            {
                let chId = info["channelId"]!
                if("\(chId)" == channelId as String )
                {
                    channelRemoved()
                }
            }
        }
    }
    
    func channelRemoved()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let refreshAlert = UIAlertController(title: "Deleted", message: "User deleted shared channel.", preferredStyle: UIAlertControllerStyle.Alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            }))
            self.presentViewController(refreshAlert, animated: true, completion: nil)
            self.channelItemsCollectionView.reloadData()
            self.NoDatalabel.removeFromSuperview()
            SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAll()
            if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count == 0)
            {
                self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                self.NoDatalabel.textAlignment = NSTextAlignment.Center
                self.NoDatalabel.text = "No Media Available"
                self.view.addSubview(self.NoDatalabel)
            }
            if(self.pullToRefreshActive)
            {
                self.pullToRefreshActive = false
                self.refreshControl.endRefreshing()
                
            }
        })
    }
    
    func checkCountIncrementInSelectedChannel(notif : NSNotification)
    {
        let channel = notif.object!
        if  "\(channel)" == channelId as String
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notificationLabel.hidden = false
                self.notificationLabel.text = "Pull to get new media"
            })
        }
    }
    func channelPushNotificationLiveStarted(info: [String : AnyObject])
    {
        let subType = info["subType"] as! String
        let chId = info["channelId"]!
        
        switch subType {
        case "started":
            liveStreamFlag = false
            if("\(chId)" == channelId as String )
            {
                notificationLabel.hidden = false
                notificationLabel.text = "pull to get livestream"
            }
            break;
        case "stopped":
            liveStreamFlag = true
            updateLiveStreamStoppeddEntry(info)
            break;
        default:
            break;
        }
    }
    
    func updateLiveStreamStartedEntry(info:[String : AnyObject])
    {
        ErrorManager.sharedInstance.streamAvailable()
    }
    
    func updateLiveStreamStoppeddEntry(info:[String : AnyObject])
    {
        if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
        {
            let type = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[0][stream_mediaTypeKey] as! String
            if(type == "live")
            {
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if ( SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
                    {
                        SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAtIndex(0)
                        self.channelItemsCollectionView.reloadData()
                    }
                })
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.channelItemsCollectionView.reloadData()
                })
            }
        }
    }
    
    func createScrollViewAnimations()  {
        channelItemsCollectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 40, 40))
        channelItemsCollectionView.infiniteScrollIndicatorMargin = 50
        channelItemsCollectionView.addInfiniteScrollWithHandler {  (scrollView) -> Void in
            
            if(!self.pullToRefreshActive)
            {
                self.scrollObj = scrollView
                self.getInfinteScrollData()
            }
            else
            {
                scrollView.finishInfiniteScroll()
            }
        }
    }
    
    func pullToRefresh()
    {
        if(!pullToRefreshActive){
            pullToRefreshActive = true
            do {
                if SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0
                {
                    getPullToRefreshData()
                }
                    
                else{
                    if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count == 0)
                    {
                        if self.downloadCompleteFlag == "end"
                        {
                            self.downloadCompleteFlag = "start"
                            SharedChannelDetailsAPI.sharedInstance.getMedia(channelId
                                , selectedChannelName: channelName, selectedChannelUserName: userName , sharedCount: totalMediaCount)
                        }
                    }
                }
            }
        }
        else
        {
            pullToRefreshActive = false
            self.refreshControl.endRefreshing()
        }
    }
    
    func ObjectDeleted(notif: NSNotification)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.channelItemsCollectionView.reloadData()
            self.NoDatalabel.removeFromSuperview()
            if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count == 0)
            {
                self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                self.NoDatalabel.textAlignment = NSTextAlignment.Center
                self.NoDatalabel.text = "No Media Available"
                self.view.addSubview(self.NoDatalabel)
            }
            if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count < 18 && SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count != 0)
            {
               // self.showOverlay()
                
                
                self.getInfinteScrollData()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.customView.removeFromSuperview()
                    self.channelItemsCollectionView.userInteractionEnabled = false
                    self.customView  = CustomInfiniteIndicator(frame: CGRectMake(self.channelItemsCollectionView.layer.frame.width/2 - 20, self.channelItemsCollectionView.layer.frame.height - 100, 40, 40))
                    self.channelItemsCollectionView.addSubview(self.customView)
                    self.customView.startAnimating()
                })

            }
            if(self.pullToRefreshActive)
            {
                self.pullToRefreshActive = false
                self.refreshControl.endRefreshing()
            }
        })
    }
    
    func updateChannelMediaList(notif: NSNotification)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.scrollObj.finishInfiniteScroll()
            self.scrollObj = UIScrollView()
            self.notificationLabel.hidden = true
            if(self.downloadCompleteFlag == "start")
            {
                self.downloadCompleteFlag = "end"
            }
            if(self.pullToRefreshActive){
                self.refreshControl.endRefreshing()
                self.pullToRefreshActive = false
            }
        })
        let success =  notif.object as! String
        if(success == "success")
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
                {
                    self.removeOverlay()
                    self.channelItemsCollectionView.reloadData()
                    self.NoDatalabel.removeFromSuperview()
                }
                
            })
        }
        else{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.NoDatalabel.removeFromSuperview()
                if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count == 0)
                {
                    self.NoDatalabel = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
                    self.NoDatalabel.textAlignment = NSTextAlignment.Center
                    self.NoDatalabel.text = "No Media Available"
                    self.view.addSubview(self.NoDatalabel)
                }
            })
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.channelItemsCollectionView.userInteractionEnabled = true
            self.customView.stopAnimationg()
            self.customView.removeFromSuperview()
        })
    }
    
    @IBAction func backClicked(sender: AnyObject)
    {
        self.setMediaimage()
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "SelectedTab")
        let sharingStoryboard = UIStoryboard(name:"Streaming", bundle: nil)
        let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(StreamsGalleryViewController.identifier) as! StreamsGalleryViewController
        sharingVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(sharingVC, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
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
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func isWatchedTrue(){
        let defaults = NSUserDefaults .standardUserDefaults()
        mediaSharedCountArray = defaults.valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        for i in 0  ..< mediaSharedCountArray.count
        {
            if  mediaSharedCountArray[i][channelIdkey] as! String == channelId as String
            {
                mediaSharedCountArray[i][sharedMediaCount] = "0"
                let defaults = NSUserDefaults .standardUserDefaults()
                defaults.setObject(mediaSharedCountArray, forKey: "Shared")
            }
        }
    }
    
    func setMediaimage()
    {
        let mediaImageKey = "mediaImage"
        var flag : Bool = false
        var index : Int = Int()
        for i in 0  ..< ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource.count
        {
            if  ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[i][channelIdkey] as! String == channelId as String
            {
                if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
                {
                    flag = true
                    index = i
                }
                else{
                    index = i
                }
            }
        }
        if(flag)
        {
            if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
            {
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][mediaImageKey] = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[0][stream_thumbImageKey] as! UIImage
            }
        }
        else{
            if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count == 0)
            {
                ChannelSharedListAPI.sharedInstance.SharedChannelListDataSource[index][mediaImageKey] =  UIImage()
            }
        }
        
        
    }
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    func getInfinteScrollData()
    {
        self.downloadCompleteFlag = "start"
        let sortList : Array = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource
        var subIdArray : [Int] = [Int]()
        for i in 0  ..< sortList.count
        {
            let id = sortList[i]["channel_media_detail_id"] as! String
            if(id != "")
            {
                subIdArray.append(Int(id)!)
            }
        }
        if(subIdArray.count > 0)
        {
            let subid = subIdArray.minElement()!
            let channelSelectedMediaId =  "\(subid)"
            let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
            SharedChannelDetailsAPI.sharedInstance.infiniteScroll(channelId, selectedChannelName: channelName, selectedChannelUserName: userId, channelMediaId: channelSelectedMediaId)
        }
        else{
            self.downloadCompleteFlag = "end"
            removeOverlay()
        }

    }
    
    func getPullToRefreshData()
    {
        if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count >= 2)
        {
            let type  = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[0][stream_mediaTypeKey] as! String
            if type != "live"
            {
                let sortList : Array = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource
                if self.downloadCompleteFlag == "end"
                {
                    self.downloadCompleteFlag = "start"
                    var subIdArray : [Int] = [Int]()
                    for i in 0  ..< sortList.count
                    {
                        subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                    }
                    if(subIdArray.count > 0)
                    {
                        let subid = subIdArray.maxElement()
                        let channelSelectedMediaId = subid!
                        let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
                        SharedChannelDetailsAPI.sharedInstance.pullToRefresh(channelId, selectedChannelUserName: userId, channelMediaId: "\(channelSelectedMediaId)")
                    }
                }
            }
            else{
                let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
                if self.downloadCompleteFlag == "end"
                {
                    let sortList : Array = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource
                    self.downloadCompleteFlag = "start"
                    var subIdArray : [Int] = [Int]()
                    for i in 1  ..< sortList.count
                    {
                        subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                    }
                    if subIdArray.count > 0
                    {
                        let subid = subIdArray.maxElement()
                        let channelSelectedMediaId = subid!
                        SharedChannelDetailsAPI.sharedInstance.pullToRefresh(channelId, selectedChannelUserName: userId, channelMediaId: "\(channelSelectedMediaId)")
                    }
                }
            }
        }
        else
        {
            if self.downloadCompleteFlag == "end"
            {
                self.downloadCompleteFlag = "start"
                SharedChannelDetailsAPI.sharedInstance.getMedia(channelId
                    , selectedChannelName: channelName, selectedChannelUserName: userName , sharedCount: totalMediaCount)
            }
        }
    }
    
    func  didSelectExtension(indexPathRow: Int)
    {
        getLikeCountForSelectedIndex(indexPathRow)
    }
    
    func getLikeCountForSelectedIndex(indexpathRow:Int)  {
        let mediaId = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexpathRow][stream_mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow)
    }
    
    func getLikeCount(mediaId: String,indexpathRow:Int) {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let mediaTypeSelected : String = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexpathRow][stream_mediaTypeKey] as! String
        channelManager.getMediaLikeCountDetails(userId, accessToken: accessToken, mediaId: mediaId, mediaType: mediaTypeSelected, success: { (response) in
            self.successHandlerForMediaCount(response,indexpathRow:indexpathRow)
            }, failure: { (error, message) -> () in
                self.failureHandlerForMediaCount(error, code: message,indexPathRow:indexpathRow)
                return
        })
    }
    
    var likeCountSelectedIndex : String = "0"
    
    func successHandlerForMediaCount(response:AnyObject?,indexpathRow:Int)
    {
        if let json = response as? [String: AnyObject]
        {
            likeCountSelectedIndex = "\(json["likeCount"]!)"
        }
        loadmovieViewController(indexpathRow, likeCount: likeCountSelectedIndex)
    }
    
    func failureHandlerForMediaCount(error: NSError?, code: String,indexPathRow:Int)
    {
        likeCountSelectedIndex = "0"
        loadmovieViewController(indexPathRow, likeCount: likeCountSelectedIndex)
    }
    
    func loadmovieViewController(indexPathRow:Int,likeCount:String) {
        self.removeOverlay()
        channelItemsCollectionView.alpha = 1.0
        let type = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][stream_mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            let dateString = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow]["createdTime"] as! String
            let index = Int32 (indexPathRow)
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            vc = MovieViewController.movieViewControllerWithImageVideo(self.channelName,channelId: self.channelId as String, userName: userName, mediaType: SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][stream_mediaTypeKey] as! String, profileImage:self.profileImage,videoImageUrl:SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][mediaUrlKey] as! UIImage, notifType: SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][notificationKey] as! String, mediaId: SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][stream_mediaIdKey] as! String,timeDiff: imageTakenTime,likeCountStr: likeCount, selectedItem: index,pageIndicator: 2) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][ stream_streamTockenKey] as! String
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName": self.channelName, "userName":userName ,    "mediaType":type, "profileImage":self.profileImage, "notifType":SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][notificationKey] as! String, "mediaId": SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][stream_mediaIdKey] as! String,"channelId":self.channelId, "likeCount":likeCount ]
                 vc = MovieViewController.movieViewControllerWithContentPath("rtsp://\(vowzaIp):1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! MovieViewController
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

extension OtherChannelViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0
        {
            return SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("OtherChannelCell", forIndexPath: indexPath) as! OtherChannelCell
        
        if SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0
        {
            if indexPath.row < SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count
            {
                let mediaType = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPath.row][stream_mediaTypeKey] as! String
                let imageData =  SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPath.row][stream_thumbImageKey] as! UIImage
                if mediaType == "video"
                {
                    let vDuration  = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPath.row][videoDurationKey] as! String
                    cell.detailLabel.hidden = false
                    cell.detailLabel.text = vDuration
                    cell.videoView.hidden = false
                    cell.videoView.image = UIImage(named: "Live_now_off_mode")
                    let imageToConvert: UIImage = imageData
                    let sizeThumb = CGSizeMake(150, 150)
                    let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                    cell.channelMediaImage.image = imageAfterConversionThumbnail
                }
                else if mediaType == "image" {
                    cell.detailLabel.hidden = true
                    cell.videoView.hidden = true
                    cell.channelMediaImage.image = imageData
                }
                else{
                    cell.detailLabel.hidden = false
                    cell.detailLabel.text = "LIVE"
                    cell.videoView.hidden = false
                    cell.videoView.image = UIImage(named: "Live_now")
                    cell.channelMediaImage.image = imageData
                }
            }
        }
        return cell
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
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if  SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count>0
        {
            if SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > indexPath.row
            {
                showOverlay()
                channelItemsCollectionView.alpha = 0.4
                didSelectExtension(indexPath.row)
            }
        }
    }
}
