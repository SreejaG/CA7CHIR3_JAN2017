//
//  StreamsListViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

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
    var totalMediaCount: Int = Int()
    var channelId:String!
    var channelName:String!
    
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
        dataSource.removeAll()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")

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
        if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
        {
            mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        }
        
        print(mediaShared)
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
       print(totalMediaCount)
        imageUploadManger.getSubscribedChannelMediaDetails(userId, accessToken: accessToken, limit: endValue, offset: startValue, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
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
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            imageDataSource.removeAll()
            if(pullToRefreshActive){
                self.refreshControl.endRefreshing()
                pullToRefreshActive = false
                
            }
            removeOverlay()

            let responseArr = json["objectJson"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let userid = responseArr[index].valueForKey(userIdKey) as! String
                let time = responseArr[index].valueForKey("last_updated_time_stamp") as! String
                let channelName =  responseArr[index].valueForKey("channel_name") as! String
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
                
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,userIdKey:userid,timestamp:time,channelNameKey:channelName])
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
            
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        removeOverlay()
    
        if(pullToRefreshActive){
            self.refreshControl.endRefreshing()
            pullToRefreshActive = false
            tapCount = 0
        }
        
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
        if imageDataSource.count > 0
        {
        for var i in 0 ..< imageDataSource.count
        {
            let mediaIdS = "\(imageDataSource[i][mediaIdKey] as! String)"
            print(mediaIdS)
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
                            FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                            imageForMedia = result
                        }
                    })
                }
            }
            
            
            self.dataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.thumbImageKey:imageForMedia ,self.streamTockenKey:"",self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.userIdKey:self.imageDataSource[i][self.userIdKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,self.timestamp :self.imageDataSource[i][self.timestamp]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.channelNameKey:self.imageDataSource[i][self.channelNameKey]!])
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.streamListCollectionView.reloadData()
            })
        }
        }
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
//        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func loadLiveStreamView(streamTocken:String)
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.154.69.174:1935/live/\(streamTocken)", parameters: nil , liveVideo: false) as! UIViewController
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
                    self.initialise()
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
            if (responseArrLive.count != 0)
            {
                for element in responseArrLive{
                    
                    let stremTockn = element[streamTockenKey] as! String
                    let userId = element[userIdKey] as! String
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
                    self.dataSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:"", self.thumbImageKey:imageForMedia ,self.streamTockenKey:stremTockn,self.actualImageKey:"",self.userIdKey:userId,self.notificationKey:notificationType,self.mediaTypeKey:"live",self.timeKey:currentDate!,self.channelNameKey:channelname])
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
                let type = dataSource[indexPath.row][mediaTypeKey] as! String
                
                let subUserName = dataSource[indexPath.row][userIdKey] as! String
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
                var profileImage = UIImage()
                
                collectionView.alpha = 0.4
                showOverlay()
                
                profileManager.getSubUserProfileImage(userId, accessToken: accessToken, subscriberUserName: subUserName, success: { (response) in
                    
                    if let json = response as? [String: AnyObject]
                    {
                        self.removeOverlay()
                        collectionView.alpha = 1.0
                        
                        let profileImageNameBeforeNullChk = json["profile_image_thumbnail"]
                        let profileImageName = self.nullToNil(profileImageNameBeforeNullChk) as! String
                        if(profileImageName != "")
                        {
                            let url: NSURL = self.convertStringtoURL(profileImageName)
                            if let data = NSData(contentsOfURL: url){
                                let imageDetailsData = (data as NSData?)!
                                profileImage = UIImage(data: imageDetailsData)!
                            }
                            else{
                                profileImage = UIImage(named: "dummyUser")!
                            }
                        }
                        else{
                            profileImage = UIImage(named: "dummyUser")!
                        }
                        
                    }
                    else{
                        self.removeOverlay()
                        collectionView.alpha = 1.0
                        profileImage = UIImage(named: "dummyUser")!
                    }
                    
                    //                    profileImage = UIImage(named: "dummyUser")!
                    
                    if type ==  "image"
                    {
                        let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.dataSource[indexPath.row][self.channelNameKey] as! String, userName: self.dataSource[indexPath.row][self.userIdKey] as! String, mediaType: self.dataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage: profileImage, videoImageUrl: self.dataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPath.row][self.notificationKey] as! String, mediaId: self.dataSource[indexPath.row][self.mediaIdKey] as! String, isProfile: true) as! MovieViewController
                        self.presentViewController(vc, animated: false) { () -> Void in
                        }
                    }
                    else if type == "video"
                    {
                        let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.dataSource[indexPath.row][self.channelNameKey] as! String, userName: self.dataSource[indexPath.row][self.userIdKey] as! String, mediaType: self.dataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage:profileImage, videoImageUrl: self.dataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPath.row][self.notificationKey] as! String, mediaId: self.dataSource[indexPath.row][self.mediaIdKey] as! String, isProfile: true) as! MovieViewController
                        self.presentViewController(vc, animated: false) { () -> Void in
                        }
                    }
                    else
                    {
                        let streamTocken = self.dataSource[indexPath.row][self.streamTockenKey] as! String
                        if streamTocken != ""
                        {
                            let parameters : NSDictionary = ["channelName":self.dataSource[indexPath.row][self.channelNameKey] as! String, "userName":self.dataSource[indexPath.row][self.userIdKey] as! String, "mediaType":self.dataSource[indexPath.row][self.mediaTypeKey] as! String, "profileImage":profileImage, "notifType":self.dataSource[indexPath.row][self.notificationKey] as! String, "mediaId": self.dataSource[indexPath.row][self.mediaIdKey] as! String, "isProfile":true]
                            let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.154.69.174:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                            
                            self.presentViewController(vc, animated: false) { () -> Void in
                                
                            }
                        }
                        else
                        {
                            ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
                        }
                    }
                    
                }) { (error, message) in
                    profileImage = UIImage(named: "dummyUser")!
                    if type ==  "image"
                    {
                        let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.dataSource[indexPath.row][self.channelNameKey] as! String, userName: self.dataSource[indexPath.row][self.userIdKey] as! String, mediaType: self.dataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage: profileImage, videoImageUrl: self.dataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPath.row][self.notificationKey] as! String, mediaId: self.dataSource[indexPath.row][self.mediaIdKey] as! String, isProfile: true) as! MovieViewController
                        self.presentViewController(vc, animated: false) { () -> Void in
                        }
                    }
                    else if type == "video"
                    {
                        let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.dataSource[indexPath.row][self.channelNameKey] as! String, userName: self.dataSource[indexPath.row][self.userIdKey] as! String, mediaType: self.dataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage:profileImage, videoImageUrl: self.dataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPath.row][self.notificationKey] as! String, mediaId: self.dataSource[indexPath.row][self.mediaIdKey] as! String, isProfile: true) as! MovieViewController
                        self.presentViewController(vc, animated: false) { () -> Void in
                        }
                    }
                    else
                    {
                        let streamTocken = self.dataSource[indexPath.row][self.streamTockenKey] as! String
                        if streamTocken != ""
                        {
                            let parameters : NSDictionary = ["channelName":self.dataSource[indexPath.row][self.channelNameKey] as! String, "userName":self.dataSource[indexPath.row][self.userIdKey] as! String, "mediaType":self.dataSource[indexPath.row][self.mediaTypeKey] as! String, "profileImage":profileImage, "notifType":self.dataSource[indexPath.row][self.notificationKey] as! String, "mediaId": self.dataSource[indexPath.row][self.mediaIdKey] as! String, "isProfile":true]
                            let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.154.69.174:1935/live/\(streamTocken)", parameters: parameters as! [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                            
                            self.presentViewController(vc, animated: false) { () -> Void in
                                self.removeOverlay()
                            }
                        }
                        else
                        {
                            ErrorManager.sharedInstance.alert("Streaming error", message: "Not a valid stream tocken")
                        }
                    }
                    
                }
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

