//
//  OtherChannelViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/15/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class OtherChannelViewController: UIViewController {
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    static let identifier = "OtherChannelViewController"
    let channelIdkey = "ch_detail_id"
    let notificationKey = "notification"
    let channelNameKey = "channel_name"
    let userIdKey = "user_name"
    var lastContentOffset: CGPoint = CGPoint()
    var totalMediaCount: Int = Int()
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
    let streamTockenKey = "wowza_stream_token"
    var refreshControl:UIRefreshControl!
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    var limit : Int = Int()
    var fixedLimit : Int =  0
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()
    let thumbImageKey = "thumbImage"
    let actualImageKey = "actualImage"
    var downloadCompleteFlag : String = "start"
    var pullToRefreshActive = false
    @IBOutlet weak var channelItemsCollectionView: UICollectionView!
    @IBOutlet weak var channelTitleLabel: UILabel!
    override func viewDidLoad()
    {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.updateChannelMediaList), name: "SharedChannelMediaDetail", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.ObjectInserted), name: "AddedOneObject", object:nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OtherChannelViewController.pushNotificationUpdateStream), name: "PushNotification", object:nil)
        
        super.viewDidLoad()
        showOverlay()
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(StreamsListViewController.pullToRefresh),forControlEvents :
            UIControlEvents.ValueChanged)
        self.channelItemsCollectionView.addSubview(self.refreshControl)
        isWatchedTrue()
        ChannelSharedListAPI.sharedInstance.updateMediaSharedInChannelList()
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
        //        removeOverlay()
        channelItemsCollectionView.alpha = 1.0
    }
    
    func pushNotificationUpdateStream(notif: NSNotification)
    {
        let info = notif.object as! [String : AnyObject]
        if (info["type"] as! String == "liveStream")
        {
            channelPushNotificationLiveStarted(info)
            
        }
    }
    
    func channelPushNotificationLiveStarted(info: [String : AnyObject])
    {
        // let info = notif.object as! [String : AnyObject]
        let subType = info["subType"] as! String
        
        switch subType {
        case "started":
            //     updateLiveStreamStartedEntry(info)
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
        ErrorManager.sharedInstance.streamAvailable()
    }
    func updateLiveStreamStoppeddEntry(info:[String : AnyObject])
    {
        if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 0)
        {
            
            SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.removeAtIndex(0)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.channelItemsCollectionView.reloadData()
            })
        }
        //  }
    }
    
    func pullToRefresh()
    {
        if(!pullToRefreshActive){
            pullToRefreshActive = true
            do {
                getPullToRefreshData()
                
            } catch {
                print("Not me error")
            }
            
        }
    }
    func ObjectInserted()
    {
        self.channelItemsCollectionView.reloadData()
        
    }
    func updateChannelMediaList(notif: NSNotification)
    {
        
        if(self.downloadCompleteFlag == "start")
        {
            downloadCompleteFlag = "end"
        }
        if(pullToRefreshActive){
            self.refreshControl.endRefreshing()
            pullToRefreshActive = false
        }
        
        let success =  notif.object as! String
        if(success == "success")
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.channelItemsCollectionView.reloadData()
                self.isWatchedTrue()
            })
            
            
        }
        else{
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                //  self.isWatchedTrue()
            })
        }
        
    }
    @IBAction func backClicked(sender: AnyObject)
    {
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
        //        self.navigationController?.view.addSubview(self.loadingOverlay!)
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
                mediaSharedCountArray[i][isWatched] = "1";
                let defaults = NSUserDefaults .standardUserDefaults()
                defaults.setObject(mediaSharedCountArray, forKey: "Shared")
            }
        }
    }
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        if (self.lastContentOffset.y < scrollView.contentOffset.y) {
            print("Scrolled Down");
            
        }
            
        else if (self.lastContentOffset.y > scrollView.contentOffset.y) {
            print("Scrolled Up");
            
            if(self.downloadCompleteFlag == "end")
            {
                do {
                    getInfinteScrollData()
                } catch {
                    print("do it error")
                }
                
            }
            
        }
    }
    func getInfinteScrollData()
    {
        if self.downloadCompleteFlag == "end"
        {
            self.downloadCompleteFlag = "start"
            
            
            let sortList : Array = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource
            var subIdArray : [Int] = [Int]()
            
            for(var i = 0 ; i < sortList.count ; i++)
            {
                subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                
            }
            if(subIdArray.count > 0)
            {
            let subid = subIdArray.minElement()!
            let channelSelectedMediaId =  "\(subid)"
            let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
            SharedChannelDetailsAPI.sharedInstance.infiniteScroll(channelId, selectedChannelName: channelName, selectedChannelUserName: userId, channelMediaId: channelSelectedMediaId)
            }
        }
        
    }
    func getPullToRefreshData()
    {
        if(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource.count > 2)
        {
            let type  = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[0][mediaTypeKey] as! String
            if type != "live"
            {
                let sortList : Array = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource
                
                if self.downloadCompleteFlag == "end"
                {
                    self.downloadCompleteFlag = "start"
                    
                    var subIdArray : [Int] = [Int]()
                    
                    for(var i = 0 ; i < sortList.count ; i++)
                    {
                        subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                        
                        //subIdArray[i] =            // subIdArray.arrayByAddingObject()
                        
                    }
                    if(subIdArray.count > 0)
                    {
                    let subid = subIdArray.maxElement()
                    let channelSelectedMediaId = "\(subid)"
                    let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
                    SharedChannelDetailsAPI.sharedInstance.pullToRefresh(channelId, selectedChannelUserName: userId, channelMediaId: channelSelectedMediaId)
                    }
                }
            }
            else{
                let channelSelectedMediaId =  SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[1][infiniteScrollIdKey] as! String
                let userId = NSUserDefaults.standardUserDefaults().valueForKey(userLoginIdKey) as! String
                if self.downloadCompleteFlag == "end"
                {
                    let sortList : Array = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource
                    
                    
                    self.downloadCompleteFlag = "start"
                    var subIdArray : [Int] = [Int]()
                    
                    for(var i = 1 ; i < sortList.count ; i++)
                    {
                        subIdArray.append(Int(sortList[i]["channel_media_detail_id"] as! String)!)
                        
                        //subIdArray[i] =            // subIdArray.arrayByAddingObject()
                        
                    }
                    if subIdArray.count > 0
                    {
                    let subid = subIdArray.maxElement()
                    let channelSelectedMediaId = "\(subid)"
                    SharedChannelDetailsAPI.sharedInstance.pullToRefresh(channelId, selectedChannelUserName: userId, channelMediaId: channelSelectedMediaId)
                    }
                }
            }
        }
        
    }
    func  didSelectExtension(indexPathRow: Int)
    {
        getLikeCountForSelectedIndex(indexPathRow)
    }
    
    func getLikeCountForSelectedIndex(indexpathRow:Int)  {
        let mediaId = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexpathRow][mediaIdKey] as! String
        getLikeCount(mediaId, indexpathRow: indexpathRow)
    }
    
    func getLikeCount(mediaId: String,indexpathRow:Int) {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        let mediaTypeSelected : String = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexpathRow][mediaTypeKey] as! String
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
            likeCountSelectedIndex = json["likeCount"] as! String
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
        let defaults = NSUserDefaults .standardUserDefaults()
        let type = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][mediaTypeKey] as! String
        if((type ==  "image") || (type == "video"))
        {
            let dateString = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            
            let vc = MovieViewController.movieViewControllerWithImageVideo(SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.actualImageKey] as! String, channelName: self.channelName,channelId: self.channelId as String, userName: userName, mediaType: SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.mediaTypeKey] as! String, profileImage:self.profileImage,videoImageUrl:SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.mediaUrlKey] as! UIImage, notifType: SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.notificationKey] as! String, mediaId: SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.mediaIdKey] as! String,timeDiff: imageTakenTime,likeCountStr: likeCount) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
            }
        }
        else
        {
            let streamTocken = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.streamTockenKey] as! String
            if streamTocken != ""
            {
                let parameters : NSDictionary = ["channelName": self.channelName, "userName":userName ,    "mediaType":type, "profileImage":self.profileImage, "notifType":SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.notificationKey] as! String, "mediaId": SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPathRow][self.mediaIdKey] as! String,"channelId":self.channelId, "likeCount":likeCount as! String]
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
            let mediaType = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPath.row][mediaTypeKey] as! String
            let imageData =  SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPath.row][thumbImageKey] as! UIImage
            if mediaType == "video"
            {
                cell.detailLabel.hidden = false
                cell.detailLabel.text = ""
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
                let userId = userName
                let type = SharedChannelDetailsAPI.sharedInstance.selectedSharedChannelMediaSource[indexPath.row][mediaTypeKey] as! String
                showOverlay()
                channelItemsCollectionView.alpha = 0.4
                didSelectExtension(indexPath.row)
            }
        }
    }
}
