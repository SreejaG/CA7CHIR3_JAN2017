
import UIKit

class MyChannelItemDetailsViewController: UIViewController {
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    var operationQueueObjInSharingImageList = NSOperationQueue()
    var operationInSharingImageList = NSBlockOperation()
    
    @IBOutlet weak var channelItemsCollectionView: UICollectionView!
    @IBOutlet weak var channelTitleLabel: UILabel!
    
    let cameraController = IPhoneCameraViewController()
    
    var customView = CustomInfiniteIndicator()
    
    var loadingOverlay: UIView?
    
    var lastContentOffset: CGPoint = CGPoint()
    
    var refreshControl:UIRefreshControl!
    
    var totalMediaCount: Int = Int()
    var tapCount : Int = 0
    var totalCount : Int = 0
    
    var channelId:String!
    var channelName:String!
    
    var downloadingFlag : Bool = false
    
    var scrollObjSharing = UIScrollView()
    var NoDatalabelFormySharingImageList : UILabel = UILabel()
    
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
        downloadingFlag = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        operationInSharingImageList.cancel()
        self.channelItemsCollectionView.alpha = 1.0
        customView.stopAnimationg()
        customView.removeFromSuperview()
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
        let inviteContactsVC = sharingStoryboard.instantiateViewControllerWithIdentifier(OtherContactListViewController.identifier) as! OtherContactListViewController
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
        createScrollViewAnimations()
        if totalMediaCount == 0
        {
            removeOverlay()
            addNoDataLabel()
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
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.channelItemsCollectionView.reloadData()
                    })
                    if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > totalCount){
                        if(totalCount < 18){
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.customView.stopAnimationg()
                                self.customView.removeFromSuperview()
                                self.customView = CustomInfiniteIndicator(frame: CGRectMake(self.channelItemsCollectionView.layer.frame.width/2 - 20, self.channelItemsCollectionView.layer.frame.height - 100, 40, 40))
                                self.channelItemsCollectionView.addSubview(self.customView)
                                self.customView.startAnimating()
                            })
                        }
                    }
                }
                else if totalCount <= 0
                {
                    totalCount = 0
                    self.channelItemsCollectionView.reloadData()
                }
                self.downloadImagesFromGlobalChannelImageMapping(21)
            }
        }
    }
    
    func thumbExists (item: [String : AnyObject]) -> Bool {
        return item[tImageKey] != nil
    }
    
    func downloadImagesFromGlobalChannelImageMapping(limit : Int)  {
        operationInSharingImageList.cancel()
        let start = totalCount
        var end = 0
        if((totalCount + limit) <= GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count){
            end = limit
        }
        else{
            end = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count - totalCount
        }
        end = start + end
        if end <= GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count
        {
            operationInSharingImageList  = NSBlockOperation (block: {
                GlobalChannelToImageMapping.sharedInstance.downloadMediaFromGCS(self.channelId, start: start, end: end, operationObj: self.operationInSharingImageList)
            })
            self.operationQueueObjInSharingImageList.addOperation(operationInSharingImageList)
        }
    }
    
    func createScrollViewAnimations()  {
        channelItemsCollectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 40, 40))
        channelItemsCollectionView.infiniteScrollIndicatorMargin = 50
        channelItemsCollectionView.addInfiniteScrollWithHandler { [weak self] (scrollView) -> Void in
            if self!.totalCount > 0
            {
                if(self!.totalCount < GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self!.channelId]!.count)
                {
                    if self!.downloadingFlag == false
                    {
                        self!.scrollObjSharing = scrollView
                        self!.downloadingFlag = true
                        self!.downloadImagesFromGlobalChannelImageMapping(12)
                    }
                }
                else{
                    scrollView.finishInfiniteScroll()
                }
            }
            else{
                scrollView.finishInfiniteScroll()
            }
        }
    }
    
    func addNoDataLabel()
    {
        self.NoDatalabelFormySharingImageList = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
        self.NoDatalabelFormySharingImageList.textAlignment = NSTextAlignment.Center
        self.NoDatalabelFormySharingImageList.text = "No Media Available"
        self.view.addSubview(self.NoDatalabelFormySharingImageList)
    }
    
    func removeActivityIndicator(notif : NSNotification){
        operationInSharingImageList.cancel()
        let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
        totalCount = filteredData.count
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.customView.stopAnimationg()
            self.customView.removeFromSuperview()
            self.removeOverlay()
            self.scrollObjSharing.finishInfiniteScroll()
            self.scrollObjSharing = UIScrollView()
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
            if let imageData =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][tImageKey] {
                channelImageView.image = imageData as? UIImage
            }
            else{
                channelImageView.image = UIImage(named: "thumb12")
            }
            
            if mediaType == "video"
            {
                cell.videoPlayIcon.hidden = false
                cell.videoDurationLabel.hidden = false
                if let vDuration =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][videoDurationKey]
                {
                    cell.videoDurationLabel.text = vDuration as? String
                }
                
            }
            else{
                cell.videoPlayIcon.hidden = true
                cell.videoDurationLabel.hidden = true
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
            if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][tImageKey] != nil
            {
                let defaults = NSUserDefaults .standardUserDefaults()
                let userId = defaults.valueForKey(userLoginIdKey) as! String
                let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
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
                    let profileUrl = UrlManager.sharedInstance.getUserProfileImageBaseURL() + userId + "/" + accessToken + "/" + userId
                    let mediaImageFromFile = FileManagerViewController.sharedInstance.getProfileImage(profileUrl )
                    imageForProfile = mediaImageFromFile
                }
                let dateString = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][mediaCreatedTimeKey] as! String
                let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
                
                let index = Int32(indexPath.row)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let vc = MovieViewController.movieViewControllerWithImageVideo(self.channelName, channelId: self.channelId as String, userName: userId, mediaType: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][mediaTypeKey] as! String, profileImage: imageForProfile, videoImageUrl: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][tImageKey] as! UIImage, notifType: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][notifTypeKey] as! String,mediaId: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][mediaIdKey] as! String, timeDiff: imageTakenTime,likeCountStr: "0",selectedItem: index,pageIndicator: 0 ) as! MovieViewController
                    self.presentViewController(vc, animated: false) { () -> Void in
                        self.removeOverlay()
                        self.channelItemsCollectionView.alpha = 1.0
                    }
                })
            }
        }
    }
}

extension MyChannelItemDetailsViewController: UIScrollViewDelegate
{
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if(totalCount > 0){
            self.customView.stopAnimationg()
            self.customView.removeFromSuperview()
        }
    }
}
