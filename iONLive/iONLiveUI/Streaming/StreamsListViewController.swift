//
//  StreamsListViewController.swift
//  iON_Live
//
//  Created by Gadgeon on 11/18/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class StreamsListViewController: UIViewController{
    
    let streamTockenKey = "wowza_stream_token" //"streamToken"
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
    
    var limit : Int = Int()
    var fixedLimit : Int =  0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()
    var mediaShared:[[String:AnyObject]] = [[String:AnyObject]]()
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
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
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "pullToRefresh", forControlEvents: UIControlEvents.ValueChanged)
        self.streamListCollectionView.addSubview(refreshControl)
        self.streamListCollectionView.alwaysBounceVertical = true
        self.view.bringSubviewToFront(activityIndicator)
        showOverlay()
        dataSource.removeAll()
        getAllLiveStreams()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBarHidden = true
        activityIndicator.hidden = true
        self.view.bringSubviewToFront(activityIndicator)
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
    }
    
    func initialise()
    {
        totalMediaCount = 0
        if (NSUserDefaults.standardUserDefaults().objectForKey("Shared") != nil)
        {
            mediaShared = NSUserDefaults.standardUserDefaults().valueForKey("Shared") as! NSArray as! [[String : AnyObject]]
        }
        
        for i in 0 ..< mediaShared.count
        {
            totalMediaCount = totalMediaCount + Int(mediaShared[i]["totalNo"] as! String)!
        }
        if totalMediaCount > 6
        {
            fixedLimit = 6
        }
        else{
            fixedLimit = totalMediaCount
        }
        limit = totalMediaCount
        imageDataSource.removeAll()
        offsetToInt = Int(offset)!
    }
    
    func initialiseCloudData(){
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        let offsetString : String = String(offsetToInt)
        
        imageUploadManger.getSubscribedChannelMediaDetails(userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) in
            self.authenticationSuccessHandler(response)
        }) { (error, message) in
            self.authenticationFailureHandler(error, code: message)
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            imageDataSource.removeAll()
            let responseArr = json["objectJson"] as! [AnyObject]
            print(responseArr)
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrl =  responseArr[index].valueForKey("gcs_object_name_SignedUrl") as! String
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
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType,userIdKey:userid,timestamp:time,channelNameKey:channelName])
            }
            downloadCloudData(15, scrolled: false)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        removeOverlay()
        if(offsetToInt <= totalMediaCount){
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
            else{
                mediaImage = UIImage()
            }
            completion(result: UIImage(data: imageData)!)
        }
        else
        {
            completion(result:UIImage(named: "thumb12")!)
        }
    }
    
    func downloadCloudData(limitMedia : Int , scrolled : Bool)
    {
        
        if(imageDataSource.count <  (currentLimit +  limitMedia))
        {
            limitMediaCount = currentLimit
            currentLimit = currentLimit + (imageDataSource.count - currentLimit)
            isLimitReached = false
        }
        else if (imageDataSource.count > (currentLimit +  limitMedia))
        {
            limitMediaCount = currentLimit
            let count = imageDataSource.count - currentLimit
            if count > 15
            {
                currentLimit = currentLimit + 15
            }
            else{
                currentLimit = currentLimit + count
            }
            isLimitReached = true
        }
        else if(currentLimit == imageDataSource.count)
        {
            isLimitReached = false
            return
        }
        
        for i in limitMediaCount  ..< currentLimit
        {
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
                        FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                        if(result != UIImage()){
                            imageForMedia = result
                        }
                        else{
                            imageForMedia = UIImage()
                        }
                        
                    })
                    
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.dummy.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.thumbImageKey:imageForMedia ,self.streamTockenKey:"",self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.userIdKey:self.imageDataSource[i][self.userIdKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,self.timestamp :self.imageDataSource[i][self.timestamp]!,self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.channelNameKey:self.imageDataSource[i][self.channelNameKey]!])
                if(self.dummy.count > 0)
                {
                    self.dummy.sortInPlace({ p1, p2 in
                        
                        let time1 = p1[self.timestamp] as! String
                        let time2 = p2[self.timestamp] as! String
                        return time1 > time2
                    })
                }
                for element in self.dummy
                {
                    self.dataSource.append(element)
                }
                self.dummy.removeAll()
                self.removeOverlay()
                self.streamListCollectionView.reloadData()
            })
            
        }
    }
    
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - (64 + 50))
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
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
        pullToRefreshActive = true
        currentLimit = 0
        limitMediaCount = 0
        getAllLiveStreams()
        showOverlay()
    }
    
    //PRAGMA MARK:- API Handlers
    func getAllLiveStreams()
    {
        let userDefault = NSUserDefaults.standardUserDefaults()
        let loginId = userDefault.objectForKey(userLoginIdKey)
        let accessTocken = userDefault.objectForKey(userAccessTockenKey)
        
        if let loginId = loginId, let accessTocken = accessTocken
        {
            livestreamingManager.getAllLiveStreams(loginId:loginId as! String , accesstocken:accessTocken as! String ,success: { (response) -> () in
                self.getAllStreamSuccessHandler(response)
                }, failure: { (error, message) -> () in
                    self.getAllStreamFailureHandler(error, message: message)
                    return
            })
        }
        else
        {
            removeOverlay()
            ErrorManager.sharedInstance.authenticationIssue()
        }
    }
    
    
    func getAllStreamSuccessHandler(response:AnyObject?)
    {
        activityIndicator.hidden = true
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        self.dataSource.removeAll()
        dummy.removeAll()
        if let json = response as? [String: AnyObject]
        {
            print(json)
            let responseArrLive = json["liveStreams"] as! [[String:AnyObject]]
            if (responseArrLive.count != 0)
            {
                for element in responseArrLive{
                    
                    let stremTockn = element[streamTockenKey] as! String
                    let thumbUrl = element["signedUrl"] as! String
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
                    if(thumbUrl != ""){
                        let url: NSURL = convertStringtoURL(thumbUrl)
                        downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                            if(result != UIImage()){
                                imageForMedia = result
                            }
                        })
                    }
                    self.dataSource.append([self.mediaIdKey:mediaId!, self.mediaUrlKey:"", self.thumbImageKey:imageForMedia ,self.streamTockenKey:stremTockn,self.actualImageKey:"",self.userIdKey:userId,self.notificationKey:notificationType,self.mediaTypeKey:"live",self.timeKey:"",self.channelNameKey:channelname])
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.streamListCollectionView.reloadData()
                })
                
            }
            
            initialise()
            initialiseCloudData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func getAllStreamFailureHandler(error: NSError?, message: String)
    {
        removeOverlay()
        activityIndicator.hidden = true
        self.refreshControl.endRefreshing()
        pullToRefreshActive = false
        if !self.requestManager.validConnection() {
            loadStaticImagesOnly()
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if message.isEmpty == false
        {
            if message == "WOWZA001"
            {
                loadStaticImagesOnly()
            }
            else
            {
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(message)
            }
        }
        else{
            ErrorManager.sharedInstance.liveStreamFetchingError()
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}

extension StreamsListViewController : UIScrollViewDelegate{
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let fullyScrolledContentOffset:CGFloat = streamListCollectionView.frame.size.width
        
        if (scrollView.contentOffset.x >= fullyScrolledContentOffset)
        {
            if(scrollView.contentOffset.x == fullyScrolledContentOffset)
            {
                
            }
        }
        if offsetY > contentHeight - scrollView.frame.size.height {
            
            if(isLimitReached)
            {
                isLimitReached = false
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadCloudData(15, scrolled: true)
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        
                    })
                })
                
            }
            
        }
    }
}


extension StreamsListViewController:UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if  dataSource.count>0
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
        
        
        if  dataSource.count>0
        {
            if dataSource.count > indexPath.row
            {
                let type = dataSource[indexPath.row][mediaTypeKey] as! String
                let imageThumb = dataSource[indexPath.row][thumbImageKey] as? UIImage
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
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        if  dataSource.count>0
        {
            if dataSource.count > indexPath.row
            {
                let type = dataSource[indexPath.row][mediaTypeKey] as! String
                if type ==  "image"
                {
                    let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPath.row][actualImageKey] as! String, channelName: self.dataSource[indexPath.row][channelNameKey] as! String, userName: self.dataSource[indexPath.row][userIdKey] as! String, mediaType: self.dataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(), videoImageUrl: self.dataSource[indexPath.row][mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPath.row][notificationKey] as! String, mediaId: self.dataSource[indexPath.row][mediaIdKey] as! String, isProfile: false) as! MovieViewController
                    self.presentViewController(vc, animated: false) { () -> Void in
                    }
                }
                else if type == "video"
                {
                    let vc = MovieViewController.movieViewControllerWithImageVideo(self.dataSource[indexPath.row][actualImageKey] as! String, channelName: self.dataSource[indexPath.row][channelNameKey] as! String, userName: self.dataSource[indexPath.row][userIdKey] as! String, mediaType: self.dataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(), videoImageUrl: self.dataSource[indexPath.row][mediaUrlKey] as! UIImage, notifType: self.dataSource[indexPath.row][notificationKey] as! String, mediaId: self.dataSource[indexPath.row][mediaIdKey] as! String, isProfile: false) as! MovieViewController
                    self.presentViewController(vc, animated: false) { () -> Void in
                    }
                }
                else
                {
                    let streamTocken = dataSource[indexPath.row][streamTockenKey] as! String
                    if streamTocken != ""
                    {
                        let parameters : NSDictionary = ["channelName":self.dataSource[indexPath.row][channelNameKey] as! String, "userName":self.dataSource[indexPath.row][userIdKey] as! String, "mediaType":self.dataSource[indexPath.row][mediaTypeKey] as! String, "profileImage":UIImage(), "notifType":self.dataSource[indexPath.row][notificationKey] as! String, "mediaId": self.dataSource[indexPath.row][mediaIdKey] as! String, "isProfile":false]
                        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://104.154.69.174:1935/live/\(streamTocken)", parameters: parameters as [NSObject : AnyObject] , liveVideo: false) as! UIViewController
                        
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

