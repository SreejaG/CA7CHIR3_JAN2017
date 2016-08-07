
import UIKit

class MyChannelItemDetailsViewController: UIViewController {
    
    let mediaDetailIdKey = "media_detail_id"
    let thumbImageURLKey = "thumbImage_URL"
    let fullImageURLKey = "fullImage_URL"
    let thumbImageKey = "thumbImage"
    let notificationTypeKey = "notification_type"
    let createdTimeStampKey = "created_timeStamp"
    let mediaTypeKey = "media_type"
    let channelMediaDetailIdKey = "channel_media_detail_id"
    let uploadProgressKey = "upload_progress"
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    @IBOutlet weak var channelItemsCollectionView: UICollectionView!
    @IBOutlet weak var channelTitleLabel: UILabel!
    
    let cameraController = IPhoneCameraViewController()
    
    var loadingOverlay: UIView?
    
    var lastContentOffset: CGPoint = CGPoint()
    
    var refreshControl:UIRefreshControl!
    
    var totalMediaCount: Int = Int()
    var tapCount : Int = 0
    var totalCount : Int = 0
    
    var channelId:String!
    var channelName:String!
    
    var downloadingFlag : Bool = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.channelItemsCollectionView.alwaysBounceVertical = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(MyChannelItemDetailsViewController.removeActivityIndicator(_:)), name: "removeActivityIndicatorMyChannel", object: nil)
        
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "tabToAppear")
        self.tabBarItem.selectedImage = UIImage(named:"all_media_blue")?.imageWithRenderingMode(.AlwaysOriginal)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.channelItemsCollectionView.alpha = 1.0
    }
    
    @IBAction func backClicked(sender: AnyObject)
    {
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let sharingVC = sharingStoryboard.instantiateViewControllerWithIdentifier(MySharedChannelsViewController.identifier) as! MySharedChannelsViewController
        sharingVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(sharingVC, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func inviteContacts(sender: AnyObject) {
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let inviteContactsVC = sharingStoryboard.instantiateViewControllerWithIdentifier(ContactListViewController.identifier) as! ContactListViewController
        inviteContactsVC.channelId = channelId
        inviteContactsVC.channelName = channelName
        inviteContactsVC.totalMediaCount = totalMediaCount
        inviteContactsVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(inviteContactsVC, animated: false)
    }
    
    func initialise()
    {
        channelId = (self.tabBarController as! MyChannelDetailViewController).channelId
        channelName = (self.tabBarController as! MyChannelDetailViewController).channelName
        totalMediaCount = (self.tabBarController as! MyChannelDetailViewController).totalMediaCount
        
        showOverlay()
        
        if totalMediaCount == 0
        {
            removeOverlay()
            ErrorManager.sharedInstance.emptyMedia()
        }
        else
        {
            if (GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.count > 0)
            {
                let channelKeys = Array(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict.keys)
                if(channelKeys.contains(channelId)){
                    let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
                    totalCount = filteredData.count
                }
                if totalCount > 0
                {
                  
                    removeOverlay()
                    self.channelItemsCollectionView.reloadData()
                    
                }
                else if totalCount <= 0
                {
                 
                    totalCount = 0
                    self.channelItemsCollectionView.reloadData()
                }
                    let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                    let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                    dispatch_async(backgroundQueue, {
                        self.downloadImagesFromGlobalChannelImageMapping(21)
                    })
        
            }
        }
    }
    
    func thumbExists (item: [String : AnyObject]) -> Bool {
        return item[thumbImageKey] != nil
    }
    
    func downloadImagesFromGlobalChannelImageMapping(limit : Int)  {
        let start = totalCount
        var end = 0
        if((totalCount + limit) < GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count){
            end = limit
        }
        else{
            end = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count - totalCount
        }
     //   totalCount = totalCount + end
        end = start + end
        
        GlobalChannelToImageMapping.sharedInstance.downloadMediaFromGCS(channelId, start: start, end: end)
    }
    
    
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if (self.lastContentOffset.y > scrollView.contentOffset.y) {
            if totalCount > 0
            {
                if(totalCount < GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count)
                {
                    if self.downloadingFlag == false
                    {
                        self.downloadingFlag = true
                        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                        dispatch_async(backgroundQueue, {
                            self.downloadImagesFromGlobalChannelImageMapping(12)
                        })
                    }
                }
            }
        }
    }
    
    func removeActivityIndicator(notif : NSNotification){
        let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
        totalCount = filteredData.count
        
        GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]!.sortInPlace({ p1, p2 in
            let time1 = Int(p1[self.mediaDetailIdKey] as! String)
            let time2 = Int(p2[self.mediaDetailIdKey] as! String)
            return time1 > time2
        })
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.removeOverlay()
            self.channelItemsCollectionView.reloadData()
        })
        if downloadingFlag == true
        {
            downloadingFlag = false
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
}

extension MyChannelItemDetailsViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return totalCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MyChannelItemCell.identifier, forIndexPath: indexPath) as! MyChannelItemCell
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > 0
        {
            let mediaType = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][mediaTypeKey] as! String
            let channelImageView = cell.viewWithTag(100) as! UIImageView
            if let imageData =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][thumbImageKey] {
                channelImageView.image = imageData as? UIImage
            }
            else{
                channelImageView.image = UIImage(named: "thumb12")
            }
            
            if mediaType == "video"
            {
                cell.videoPlayIcon.hidden = false
            }
            else{
                cell.videoPlayIcon.hidden = true
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
        if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > 0){
            if let img = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][thumbImageKey]
            {
                
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                
                self.showOverlay()
                
                self.channelItemsCollectionView.alpha = 0.4
                var imageForProfile : UIImage = UIImage()
                let parentPath = FileManagerViewController.sharedInstance.getParentDirectoryPath()
                let savingPath = "\(parentPath)/\(userId)Profile"
                let fileExistFlag = FileManagerViewController.sharedInstance.fileExist(savingPath)
                if fileExistFlag == true{
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getImageFromFilePath(savingPath)
                    imageForProfile = mediaImageFromFile!
                }
                else{
                    imageForProfile =  UIImage(named: "dummyUser")!
                }
                let dateString = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][createdTimeStampKey] as! String
                let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let vc = MovieViewController.movieViewControllerWithImageVideo(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][self.fullImageURLKey] as! String, channelName: self.channelName, channelId: self.channelId as String, userName: userId, mediaType: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][self.mediaTypeKey] as! String, profileImage: imageForProfile, videoImageUrl: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][self.thumbImageKey] as! UIImage, notifType: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][self.notificationTypeKey] as! String,mediaId: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][self.mediaDetailIdKey] as! String, timeDiff: imageTakenTime,likeCountStr: "0") as! MovieViewController
                    self.presentViewController(vc, animated: false) { () -> Void in
                        self.removeOverlay()
                        self.channelItemsCollectionView.alpha = 1.0
                    }
                })
            }
        }
    }
}
