
import UIKit

class ChannelItemListViewController: UIViewController {
    
    @IBOutlet weak var channelTitleLabel: UILabel!
    
    @IBOutlet weak var channelItemCollectionView: UICollectionView!
    
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var selectionButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var backButton: UIButton!
    
    @IBOutlet var bottomView: UIView!
    
    static let identifier = "ChannelItemListViewController"
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    let cameraController = IPhoneCameraViewController()
    
    var operationQueueObjInChannelImageList = NSOperationQueue()
    var operationInChannelImageList = NSBlockOperation()
    
    var lastContentOffset: CGPoint = CGPoint()
    
    var loadingOverlay: UIView?
    var customView = CustomInfiniteIndicator()
    
    var addToDict : [[String:AnyObject]] = [[String:AnyObject]]()
    
    var selected: NSMutableArray = NSMutableArray()
    var selectedArray:[Int] = [Int]()
    var deletedMediaArray : NSMutableArray = NSMutableArray()
    
    var selectionFlag : Bool = false
    var downloadingFlag : Bool = false
    
    var channelId:String!
    var channelName:String!
    
    var userId : String = String()
    var accessToken: String = String()
    
    var totalCount = 0
    
    var totalMediaCount: Int = Int()
    var scrollObj = UIScrollView()
    
    var NoDatalabelFormyChanelImageList : UILabel = UILabel()
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        bottomView.hidden = true
        deleteButton.hidden = true
        addButton.hidden = true
        cancelButton.hidden = true
        selectionFlag = false
        self.channelItemCollectionView.alwaysBounceVertical = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(ChannelItemListViewController.removeActivityIndicatorMyChanel(_:)), name: "removeActivityIndicatorMyChannel", object: nil)
        
        showOverlay()
        totalCount = 0
        createScrollViewAnimations()
        if totalMediaCount == 0
        {
            selectionButton.hidden = true
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
                    selectionButton.hidden = false
                    removeOverlay()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.channelItemCollectionView.reloadData()
                    })
                    if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > totalCount){
                        if(totalCount < 18){
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.channelItemCollectionView.userInteractionEnabled = false
                                self.customView = CustomInfiniteIndicator(frame: CGRectMake(self.channelItemCollectionView.layer.frame.width/2 - 20, self.channelItemCollectionView.layer.frame.height - 100, 40, 40))
                                self.channelItemCollectionView.addSubview(self.customView)
                                self.customView.startAnimating()
                            })
                        }
                    }
                }
                else if totalCount <= 0
                {
                    selectionButton.hidden = true
                    totalCount = 0
                    self.channelItemCollectionView.reloadData()
                }
                downloadImagesFromGlobalChannelImageMapping(21)
            }
        }
    }
    
    func addNoDataLabel()
    {
        self.NoDatalabelFormyChanelImageList = UILabel(frame: CGRectMake((self.view.frame.width/2) - 100,(self.view.frame.height/2) - 35, 200, 70))
        self.NoDatalabelFormyChanelImageList.textAlignment = NSTextAlignment.Center
        self.NoDatalabelFormyChanelImageList.text = "No Media Available"
        self.view.addSubview(self.NoDatalabelFormyChanelImageList)
    }
    
    func removeActivityIndicatorMyChanel(notif : NSNotification){
        operationInChannelImageList.cancel()
        let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
        totalCount = filteredData.count
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.selectionFlag == false {
                self.selectionButton.hidden = false
            }
            else{
                self.cancelButton.hidden = false
            }
            self.channelItemCollectionView.userInteractionEnabled = true
            self.customView.stopAnimationg()
            self.customView.removeFromSuperview()
            self.removeOverlay()
            self.scrollObj.finishInfiniteScroll()
            self.scrollObj = UIScrollView()
            self.channelItemCollectionView.reloadData()
        })
        
        if downloadingFlag == true
        {
            downloadingFlag = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        channelTitleLabel.minimumScaleFactor = 2
        channelTitleLabel.adjustsFontSizeToFitWidth = true
        downloadingFlag = false
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        operationInChannelImageList.cancel()
        removeOverlay()
        self.channelItemCollectionView.alpha = 1.0
        customView.stopAnimationg()
        customView.removeFromSuperview()
        channelItemCollectionView.userInteractionEnabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func thumbExists (item: [String : AnyObject]) -> Bool {
        return item[tImageKey] != nil
    }
    
    func createScrollViewAnimations()  {
        customView.stopAnimationg()
        customView.removeFromSuperview()
        channelItemCollectionView.infiniteScrollIndicatorView = CustomInfiniteIndicator(frame: CGRectMake(0, 0, 40, 40))
        channelItemCollectionView.infiniteScrollIndicatorMargin = 50
        channelItemCollectionView.addInfiniteScrollWithHandler { [weak self] (scrollView) -> Void in
            if self!.totalCount > 0
            {
                if(self!.totalCount < GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self!.channelId]!.count)
                {
                    if self!.downloadingFlag == false
                    {
                        self!.scrollObj = scrollView
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
    
    func downloadImagesFromGlobalChannelImageMapping(limit:Int)  {
        operationInChannelImageList.cancel()
        let start = totalCount
        var end = 0
        
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId] != nil
        {
            if((totalCount + limit) <= GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count){
                end = limit
            }
            else{
                end = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count - totalCount
            }
            end = start + end
            if end <= GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count
            {
                operationInChannelImageList  = NSBlockOperation (block: {
                    GlobalChannelToImageMapping.sharedInstance.downloadMediaFromGCS(self.channelId, start: start, end: end, operationObj: self.operationInChannelImageList)
                })
                self.operationQueueObjInChannelImageList.addOperation(operationInChannelImageList)
            }
            else{
                removeOverlay()
            }
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
                catch _ as NSError {
                }
                FileManagerViewController.sharedInstance.createParentDirectory()
            }
            else{
                FileManagerViewController.sharedInstance.createParentDirectory()
            }
            
            let deviceToken = self.defaults.valueForKey("deviceToken") as! String
            self.defaults.removePersistentDomainForName(NSBundle.mainBundle().bundleIdentifier!)
            self.defaults.setValue(deviceToken, forKey: "deviceToken")
            self.defaults.setObject(1, forKey: "shutterActionMode");
            
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
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.view .addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject)
    {
        let notificationStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelVC = notificationStoryboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
        channelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelVC, animated: false)
    }
    
    @IBAction func didTapAddtoButton(sender: AnyObject) {
        for i in 0 ..< selectedArray.count
        {
            let mediaSelectedId = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![selectedArray[i]][mediaIdKey]
            selected.addObject(mediaSelectedId!)
            addToDict.append(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![selectedArray[i]])
        }
        
        let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
        
        addChannelVC.mediaDetailSelected = selected
        addChannelVC.selectedChannelId = channelId
        addChannelVC.localMediaDict = addToDict
        
        addChannelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(addChannelVC, animated: false)
    }
    
    @IBAction func didTapSelectionButton(sender: AnyObject) {
        selected.removeAllObjects()
        selectedArray.removeAll()
        selectionFlag = true
        self.channelItemCollectionView.allowsMultipleSelection = true
        channelTitleLabel.text = "SELECT"
        cancelButton.hidden = false
        selectionButton.hidden = true
        bottomView.hidden = false
        deleteButton.hidden = false
        addButton.hidden = false
        backButton.hidden = true
        deleteButton.enabled = false
        addButton.enabled = false
        deleteButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        addButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.channelItemCollectionView.reloadData()
        })
    }
    
    @IBAction func didTapCancelButton(sender: AnyObject) {
        removeOverlay()
        selected.removeAllObjects()
        selectedArray.removeAll()
        channelTitleLabel.text = channelName.uppercaseString
        cancelButton.hidden = true
        selectionButton.hidden = false
        bottomView.hidden = true
        deleteButton.hidden = true
        addButton.hidden = true
        backButton.hidden = false
        selectionFlag = false
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.channelItemCollectionView.reloadData()
        })
    }
    
    @IBAction func didTapDeleteButton(sender: AnyObject) {
        var channelIds : [Int] = [Int]()
        scrollObj.finishInfiniteScroll()
        operationInChannelImageList.cancel()
        for i in 0 ..< selectedArray.count
        {
            let mediaSelectedId = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![selectedArray[i]][mediaIdKey]
            selected.addObject(mediaSelectedId!)
        }
        if(selected.count > 0){
            channelIds.append(Int(channelId)!)
            showOverlay()
            selectionButton.hidden = true
//            downloadImagesFromGlobalChannelImageMapping(selected.count)
            imageUploadManger.deleteMediasByChannel(userId, accessToken: accessToken, mediaIds: selected, channelId: channelIds, success: { (response) -> () in
                self.authenticationSuccessHandlerDelete(response)
                }, failure: { (error, message) -> () in
                    self.authenticationFailureHandlerDelete(error, code: message)
            })
        }
    }
    
    func authenticationSuccessHandlerDelete(response:AnyObject?)
    {
//        if(selected.count < 6){
            removeOverlay()
//        }
        if (response as? [String: AnyObject]) != nil
        {
            GlobalChannelToImageMapping.sharedInstance.deleteMediasFromChannel(channelId, mediaIds: selected)
            totalMediaCount = totalMediaCount - selected.count
            
            let filteredData = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.filter(thumbExists)
            totalCount = filteredData.count
            
            downloadingFlag = false
            selectionFlag = false
            
            if(totalCount == GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count){
               
            }
            else{
                if(selected.count > 3){
                    if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > totalCount){
                        if(totalCount < 18){
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                 self.channelItemCollectionView.userInteractionEnabled = false
                                self.customView = CustomInfiniteIndicator(frame: CGRectMake(self.channelItemCollectionView.layer.frame.width/2 - 20, self.channelItemCollectionView.layer.frame.height - 100, 40, 40))
                                self.channelItemCollectionView.addSubview(self.customView)
                                self.customView.startAnimating()
                            })
                        }
                    }
                }
                else{
                    customView.stopAnimationg()
                    customView.removeFromSuperview()
                }
                downloadImagesFromGlobalChannelImageMapping(selected.count)
            }
            
            selectedArray.removeAll()
            selected.removeAllObjects()
            channelTitleLabel.text = channelName.uppercaseString
            cancelButton.hidden = true
            bottomView.hidden = true
            deleteButton.hidden = true
            addButton.hidden = true
            backButton.hidden = false
            if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > 0){
                selectionButton.hidden = false
            }
            else{
                selectionButton.hidden = true
            }
            if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count == 0){
                addNoDataLabel()
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.channelItemCollectionView.reloadData()
            })
        }
    }
    
    func authenticationFailureHandlerDelete(error: NSError?, code: String)
    {
        self.removeOverlay()
        selectionButton.hidden = false
        cancelButton.hidden = true
        backButton.hidden = false
        bottomView.hidden = true
        if !self.requestManager.validConnection() {
            ErrorManager.sharedInstance.noNetworkConnection()
        }
        else if code.isEmpty == false {
            
            if((code == "USER004") || (code == "USER005") || (code == "USER006")){
                loadInitialViewController(code)
            }
            else{
                ErrorManager.sharedInstance.mapErorMessageToErrorCode(code)
            }
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
        selectedArray.removeAll()
        if(GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > 0){
            selectionButton.hidden = false
        }
        else{
            selectionButton.hidden = true
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.channelItemCollectionView.reloadData()
        })
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
}

extension ChannelItemListViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return totalCount
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ChannelItemListCollectionViewCell.identifier, forIndexPath: indexPath) as! ChannelItemListCollectionViewCell
        
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        cell.selectionView.alpha = 0.4
        cell.tickButton.frame = CGRect(x: ((UIScreen.mainScreen().bounds.width/3)-2) - 25, y: 3, width: 20, height: 20)
        
        let channelItemImageView = cell.viewWithTag(100) as! UIImageView
        
        if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]!.count > 0
        {
            let mediaType = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][mediaTypeKey] as! String
            if let imageData =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][tImageKey]
            {
                channelItemImageView.image = imageData as? UIImage
            }
            else{
                channelItemImageView.image = UIImage(named: "thumb12")
            }
            
            
            if mediaType == "video"
            {
                cell.videoView.hidden = false
                if let vDuration =  GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][videoDurationKey]
                {
                    cell.videoDurationLabel.text = vDuration as? String
                }
            }
            else{
                cell.videoView.hidden = true
            }
            
            cell.insertSubview(cell.videoView, aboveSubview: cell.channelItemImageView)
            
            if(selectionFlag){
                
                if(selectedArray.contains(indexPath.row)){
                    
                    cell.selectionView.hidden = false
                    cell.insertSubview(cell.selectionView, aboveSubview: cell.videoView)
                }
                else{
                    
                    cell.selectionView.hidden = true
                    cell.insertSubview(cell.videoView, aboveSubview: cell.selectionView)
                }
            }
            else{
                cell.selectionView.hidden = true
            }
        }
        else{
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
        if(selectionFlag){
            deleteButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
            deleteButton.enabled = true
            addButton.enabled = true
            addButton.setTitle("Add to", forState: .Normal)
            addButton.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
            if(selectedArray.contains(indexPath.row)){
                let elementIndex = selectedArray.indexOf(indexPath.row)
                selectedArray.removeAtIndex(elementIndex!)
            }
            else{
                selectedArray.append(indexPath.row)
            }
            if(selectedArray.count <= 0){
                deleteButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
                addButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
                deleteButton.enabled = false
                addButton.enabled = false
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.channelItemCollectionView.reloadData()
            })
        }
        else{
            
            if GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][tImageKey] != nil
            {
                self.showOverlay()
                self.channelItemCollectionView.alpha = 0.4
                
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
                
                let dateString = GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[channelId]![indexPath.row][mediaCreatedTimeKey] as! String
                let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
                
                let index = Int32(indexPath.row)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let vc = MovieViewController.movieViewControllerWithImageVideo(self.channelName, channelId: self.channelId as String, userName: self.userId, mediaType: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][mediaTypeKey] as! String, profileImage: imageForProfile, videoImageUrl: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][tImageKey] as! UIImage, notifType: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][notifTypeKey] as! String,mediaId: GlobalChannelToImageMapping.sharedInstance.GlobalChannelImageDict[self.channelId]![indexPath.row][mediaIdKey] as! String, timeDiff: imageTakenTime,likeCountStr: "0",selectedItem:index,pageIndicator: 0) as! MovieViewController
                    self.presentViewController(vc, animated: false) { () -> Void in
                        self.removeOverlay()
                        self.channelItemCollectionView.alpha = 1.0
                    }
                })
            }
        }
    }
}
