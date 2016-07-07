
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
    var mediaSharedCountArray:[[String:AnyObject]] = [[String:AnyObject]]()
    
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
    
    var dataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var  dummy: [[String:AnyObject]] = [[String:AnyObject]]()
    
    var dummyImagesArray:[String] = ["thumb1","thumb2","thumb3","thumb4","thumb5","thumb6" , "thumb7","thumb8","thumb9","thumb10","thumb11","thumb12"]
    var dummyImageListingDataSource = [[String:String]]()
    
    @IBOutlet weak var streamListCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstTap = 0
        dataSource.removeAll()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.streamListCollectionView.alwaysBounceVertical = true
        getAllLiveStreams()
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
    
    func initialise()
    {
        totalMediaCount = 0
        firstTap = firstTap + 1
        if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
        {
            mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        }
        for i in 0 ..< mediaShared.count
        {
            totalMediaCount = totalMediaCount + Int(mediaShared[i]["totalNo"] as! String)!
        }
        
        initialiseCloudData()
    }
    
    func initialiseCloudData(){
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let startValue = "0"
        let endValue = String(totalMediaCount)
        print(endValue)
        imageUploadManger.getSubscribedChannelMediaDetails(userId, accessToken: accessToken, limit: endValue, offset: startValue, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
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

    func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            imageDataSource.removeAll()
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
            }
//            removeOverlay()

            let responseArr = json["objectJson"] as! [AnyObject]
            print(responseArr)
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let userid = responseArr[index].valueForKey(userIdKey) as! String
                let time = responseArr[index].valueForKey("last_updated_time_stamp") as! String
                let channelName =  responseArr[index].valueForKey("channel_name") as! String
                let channelIdSelected =  responseArr[index].valueForKey("ch_detail_id")?.stringValue
                var notificationType : String = String()
                if let notifType =  responseArr[index].valueForKey("notification_type") as? String
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
                
                let actualUrlBeforeNullChk =  responseArr[index].valueForKey("gcs_object_name_SignedUrl")
                let actualUrl = nullToNil(actualUrlBeforeNullChk) as! String
                
                let mediaUrlBeforeNullChk =  responseArr[index].valueForKey("thumbnail_name_SignedUrl")
                let mediaUrl = nullToNil(mediaUrlBeforeNullChk) as! String
                
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,userIdKey:userid,timestamp:time,channelNameKey:channelName, channelIdkey:channelIdSelected!,"createdTime":time])
            }
            
            if(imageDataSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
                        self.streamListCollectionView.addSubview(self.refreshControl)
                        self.tapCount = 0
                    })
                })
            }
            else{
                removeOverlay()
            }
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
        if !self.requestManager.validConnection() {
            removeOverlay()
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
                tapCount = 0
            }
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                removeOverlay()
                if(pullToRefreshActive){
                    self.refreshControl.endRefreshing()
                    pullToRefreshActive = false
                    tapCount = 0
                }
                loadInitialViewController(code)
            }
            else{
                if((code == "MEDIA003") || (code == "MEDIA002")){
                    if(firstTap == 1){
                        self.initialise()
                    }
                    else{
                        removeOverlay()
                        if(pullToRefreshActive){
                            self.refreshControl.endRefreshing()
                            pullToRefreshActive = false
                            tapCount = 0
                        }
                        
                        ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
                    }
                }
            }
        }
        else{
            removeOverlay()
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
                tapCount = 0
            }
            ErrorManager.sharedInstance.inValidResponseError()
        }
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
    
    func downloadMediaFromGCS(){
        for var i = 0; i < imageDataSource.count; i++
        {
                let mediaIdS = "\(imageDataSource[i][mediaIdKey] as! String)"
                if(mediaIdS != ""){
                    var imageForMedia : UIImage = UIImage()
                    let mediaIdForFilePath = "\(imageDataSource[i][mediaIdKey] as! String)thumb"
                    let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                    let savingPath = "\(parentPath)/\(mediaIdForFilePath)"
                    let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                    if fileExistFlag == true{
                        let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                        imageForMedia = mediaImageFromFile!
                    }
                    else{
                        let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
                        if(mediaUrl != ""){
                            let url: NSURL = convertStringtoURL(mediaUrl)
                            downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                                if(result != UIImage()){
                                    let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                                    let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                                    let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                                    let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                                    if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                                        print("not same")
                                    }
                                    else{
                                        FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                                    }
                                    imageForMedia = result
                                }
                                else{
                                    imageForMedia = UIImage(named: "thumb12")!
                                }
                            })
                        }
                    }
                    self.dataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.thumbImageKey:imageForMedia ,self.streamTockenKey:"",self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.userIdKey:self.imageDataSource[i][self.userIdKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,self.timestamp :self.imageDataSource[i][self.timestamp]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.channelNameKey:self.imageDataSource[i][self.channelNameKey]!,self.channelIdkey:self.imageDataSource[i][self.channelIdkey]!,"createdTime":self.imageDataSource[i]["createdTime"] as! String])
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.removeOverlay()
                       self.streamListCollectionView.reloadData()
                    })
                }
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
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://130.211.135.170:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
        self.presentViewController(vc, animated: false) { () -> Void in
        }
    }
    
    func pullToRefresh()
    {
        tapCount = tapCount + 1
        if(tapCount <= 1){
            if(!pullToRefreshActive){
                pullToRefreshActive = true
                dataSource.removeAll()
                getAllLiveStreams()
            }
        }
        else{
            self.refreshControl.endRefreshing()
        }
    }
    
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        showOverlay()
        
        if(pullToRefreshActive){
            removeOverlay()
        }
        
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
        self.dataSource.removeAll()
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
                    let dateStr = dateFormatter.stringFromDate(NSDate())
                    let currentDate = dateFormatter.dateFromString(dateStr)
                    self.dataSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:"", self.thumbImageKey:imageForMedia ,self.streamTockenKey:stremTockn,self.actualImageKey:"",self.userIdKey:userId,self.notificationKey:notificationType,self.mediaTypeKey:"live",self.timeKey:currentDate!,self.channelNameKey:channelname, self.channelIdkey: channelIdSelected!])
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                     self.streamListCollectionView.reloadData()
                })
            }
          
            initialise()
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
        let subUserName = dataSource[indexpathRow][userIdKey] as! String
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
        let mediaId = dataSource[indexpathRow][mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow, profile: profile)
    }
    
    func getLikeCount(mediaId: String,indexpathRow:Int,profile:UIImage) {
        let mediaTypeSelected : String = dataSource[indexpathRow][mediaTypeKey] as! String
        print(mediaTypeSelected)
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

        let type = dataSource[indexPathRow][mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            let dateString = self.dataSource[indexPathRow]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            print(self.dataSource[indexPathRow][self.notificationKey] as! String)
            let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPathRow][self.actualImageKey] as! String, channelName: self.dataSource[indexPathRow][self.channelNameKey] as! String,channelId: self.dataSource[indexPathRow][self.channelIdkey] as! String, userName: self.dataSource[indexPathRow][self.userIdKey] as! String, mediaType: self.dataSource[indexPathRow][self.mediaTypeKey] as! String, profileImage: profileImage, videoImageUrl: self.dataSource[indexPathRow][self.mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPathRow][self.notificationKey] as! String, mediaId: self.dataSource[indexPathRow][self.mediaIdKey] as! String,timeDiff:imageTakenTime,likeCountStr:likeCount) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = self.dataSource[indexPathRow][self.streamTockenKey] as! String
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName":self.dataSource[indexPathRow][self.channelNameKey] as! String, "userName":self.dataSource[indexPathRow][self.userIdKey] as! String, "mediaType":self.dataSource[indexPathRow][self.mediaTypeKey] as! String, "profileImage":profileImage, "notifType":self.dataSource[indexPathRow][self.notificationKey] as! String, "mediaId": self.dataSource[indexPathRow][self.mediaIdKey] as! String,"channelId":self.dataSource[indexPathRow][self.channelIdkey] as! String,"likeCount":likeCount as! String]
                let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://130.211.135.170:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                
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
        if  dataSource.count > 0
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("StreamListCollectionViewCell", forIndexPath: indexPath) as! StreamListCollectionViewCell
        
        if  dataSource.count > 0
        {
            if dataSource.count > indexPath.row
            {
                let type = dataSource[indexPath.row][mediaTypeKey] as! String
                if let imageThumb = dataSource[indexPath.row][thumbImageKey] as? UIImage
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
        if(!pullToRefreshActive){
            if  dataSource.count>0
            {
                if dataSource.count > indexPath.row
                {
                    collectionView.alpha = 0.4
                    showOverlay()
                    didSelectExtension(indexPath.row)
                }
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

