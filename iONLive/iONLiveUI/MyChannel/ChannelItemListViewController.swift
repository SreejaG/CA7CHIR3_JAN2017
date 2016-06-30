//
//  ChannelItemListViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/28/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit


class ChannelItemListViewController: UIViewController {
    
    var selectionFlag : Bool = false
    var selected: NSMutableArray = NSMutableArray()
    
    static let identifier = "ChannelItemListViewController"
    @IBOutlet weak var channelTitleLabel: UILabel!
    @IBOutlet weak var channelItemCollectionView: UICollectionView!
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var totalMediaCount: Int = Int()
    
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var fullImageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var channelId:String!
    var channelName:String!
    
    var selectedArray:[Int] = [Int]()
    
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var selectionButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var backButton: UIButton!
    
    let cameraController = IPhoneCameraViewController()
    
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let mediaTypeKey = "mediaType"
    let actualImageKey = "actualImage"
    let notificationKey = "notification"
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        deleteButton.hidden = true
        addButton.hidden = true
        cancelButton.hidden = true
        selectionFlag = false
        self.channelItemCollectionView.alwaysBounceVertical = true
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        removeOverlay()
        self.channelItemCollectionView.alpha = 1.0
        channelItemCollectionView.userInteractionEnabled = true
    }
    
    func initialise(){
        imageDataSource.removeAll()
        fullImageDataSource.removeAll()
        selectedArray.removeAll()
        selected.removeAllObjects()
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        
        showOverlay()
        
        let startValue = "0"
        let endValue = String(totalMediaCount)
        
        imageUploadManger.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: endValue, offset: startValue, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
        }) { (error, message) -> () in
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
    
    func nullToNil(value : AnyObject?) -> AnyObject? {
        if value is NSNull {
            return ""
        } else {
            return value
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
       
        imageDataSource.removeAll()
        fullImageDataSource.removeAll()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["MediaDetail"] as! [AnyObject]
            for index in 0 ..< responseArr.count
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")?.stringValue
                let mediaUrlBeforeNullChk = responseArr[index].valueForKey("thumbnail_name_SignedUrl")
                let mediaUrl = nullToNil(mediaUrlBeforeNullChk) as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                let actualUrlBeforeNullChk =  responseArr[index].valueForKey("gcs_object_name_SignedUrl")
                let actualUrl = nullToNil(actualUrlBeforeNullChk) as! String
                let notificationType : String = "likes"
                let time = responseArr[index].valueForKey("created_time_stamp") as! String
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType, "createdTime": time])
            }
            if(imageDataSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                    self.downloadMediaFromGCS()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    })
                })
            }
            else{
                ErrorManager.sharedInstance.emptyMedia()
                removeOverlay()
                selectionButton.hidden = true
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
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
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
        let savedURL : String
        for var i = 0; i < imageDataSource.count; i++
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
                        if(result != UIImage()){
                            let imageDataFromresult = UIImageJPEGRepresentation(result, 0.5)
                            let imageDataFromresultAsNsdata = (imageDataFromresult as NSData?)!
                            let imageDataFromDefault = UIImageJPEGRepresentation(UIImage(named: "thumb12")!, 0.5)
                            let imageDataFromDefaultAsNsdata = (imageDataFromDefault as NSData?)!
                            if(imageDataFromresultAsNsdata.isEqual(imageDataFromDefaultAsNsdata)){
                              
                            }
                            else{
                                FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                            }
                            imageForMedia = result
                        }
                        else{
                            imageForMedia =  UIImage(named: "thumb12")!
                        }
                    })
                }
            }
            self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!,"createdTime":self.imageDataSource[i]["createdTime"]!])
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.removeOverlay()
                self.channelItemCollectionView.reloadData()
            })
        }
    }
    
    @IBAction func didTapBackButton(sender: AnyObject)
    {
        let notificationStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelVC = notificationStoryboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
        channelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelVC, animated: false)
    }
    
    @IBAction func didTapAddtoButton(sender: AnyObject) {
        for(var i = 0; i < selectedArray.count; i++){
            let mediaSelectedId = fullImageDataSource[selectedArray[i]][mediaIdKey]
            selected.addObject(mediaSelectedId!)
        }
        let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
        addChannelVC.mediaDetailSelected = selected
        addChannelVC.selectedChannelId = channelId
        addChannelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(addChannelVC, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapSelectionButton(sender: AnyObject) {
        selected.removeAllObjects()
        selectedArray.removeAll()
        selectionFlag = true
        self.channelItemCollectionView.allowsMultipleSelection = true
        channelTitleLabel.text = "SELECT"
        cancelButton.hidden = false
        selectionButton.hidden = true
        deleteButton.hidden = false
        addButton.hidden = false
        backButton.hidden = true
        deleteButton.enabled = false
        addButton.enabled = false
        deleteButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
        addButton.setTitleColor(UIColor.lightGrayColor(), forState: UIControlState.Normal)
     //   addButton.setTitle("Add to", forState: .Normal)
        channelItemCollectionView.reloadData()
    }
    
    @IBAction func didTapCancelButton(sender: AnyObject) {
        selected.removeAllObjects()
        selectedArray.removeAll()
        channelTitleLabel.text = channelName.uppercaseString
        cancelButton.hidden = true
        selectionButton.hidden = false
        deleteButton.hidden = true
        addButton.hidden = true
        backButton.hidden = false
        selectionFlag = false
        channelItemCollectionView.reloadData()
    }
    
    @IBAction func didTapDeleteButton(sender: AnyObject) {
        var channelIds : [Int] = [Int]()
        
        for(var i = 0; i < selectedArray.count; i++){
            let mediaSelectedId = fullImageDataSource[selectedArray[i]][mediaIdKey]
            selected.addObject(mediaSelectedId!)
        }
        if(selected.count > 0){
            channelIds.append(Int(channelId)!)
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            showOverlay()
            selectionButton.hidden = true
            imageUploadManger.deleteMediasByChannel(userId, accessToken: accessToken, mediaIds: selected, channelId: channelIds, success: { (response) -> () in
                self.authenticationSuccessHandlerDelete(response)
                }, failure: { (error, message) -> () in
                    self.authenticationFailureHandlerDelete(error, code: message)
            })
            
        }
    }
    
    func authenticationSuccessHandlerDelete(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            totalMediaCount = totalMediaCount - selected.count
            selectedArray = selectedArray.sort()
            for(var i = 0; i < selectedArray.count; i++){
                var selectedIndex = selectedArray[i]
                selectedIndex = selectedIndex - i
              
                imageDataSource.removeAtIndex(selectedIndex)
                fullImageDataSource.removeAtIndex(selectedIndex)
            }
            selectionFlag = false
            selectedArray.removeAll()
            selected.removeAllObjects()
            channelTitleLabel.text = channelName.uppercaseString
            cancelButton.hidden = true
            deleteButton.hidden = true
            addButton.hidden = true
            backButton.hidden = false
            if(fullImageDataSource.count > 0){
                selectionButton.hidden = false
            }
            else{
                selectionButton.hidden = true
            }
            channelItemCollectionView.reloadData()
        }
    }
    
    func authenticationFailureHandlerDelete(error: NSError?, code: String)
    {
        self.removeOverlay()
        selectionButton.hidden = false
        print("message = \(code) andError = \(error?.localizedDescription) ")
        
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
    }
}

extension ChannelItemListViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        if fullImageDataSource.count > 0
        {
            return fullImageDataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ChannelItemListCollectionViewCell.identifier, forIndexPath: indexPath) as! ChannelItemListCollectionViewCell
        
        cell.selectionView.alpha = 0.4
        cell.tickButton.frame = CGRect(x: ((UIScreen.mainScreen().bounds.width/3)-2) - 25, y: 3, width: 20, height: 20)
        
        let channelItemImageView = cell.viewWithTag(100) as! UIImageView
        
        if fullImageDataSource.count > 0
        {
            let mediaType = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
            
            let imageData =  fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage
            
            channelItemImageView.image = imageData
            
            if mediaType == "video"
            {
                cell.videoView.hidden = false
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
            collectionView.reloadData()
        }
        else{
            
            self.showOverlay()
            self.channelItemCollectionView.alpha = 0.4
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
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
            
            let dateString = self.fullImageDataSource[indexPath.row]["createdTime"] as! String
            let imageTakenTime = FileManagerViewController.sharedInstance.getTimeDifference(dateString)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                let vc = MovieViewController.movieViewControllerWithImageVideo(self.fullImageDataSource[indexPath.row][self.actualImageKey] as! String, channelName: self.channelName, channelId: self.channelId as String, userName: userId, mediaType: self.fullImageDataSource[indexPath.row][self.mediaTypeKey] as! String, profileImage: imageForProfile, videoImageUrl: self.fullImageDataSource[indexPath.row][self.mediaUrlKey] as! UIImage, notifType: self.fullImageDataSource[indexPath.row][self.notificationKey] as! String,mediaId: self.fullImageDataSource[indexPath.row][self.mediaIdKey] as! String, timeDiff: imageTakenTime,likeCountStr: "0") as! MovieViewController
                self.presentViewController(vc, animated: false) { () -> Void in
                    self.removeOverlay()
                    self.channelItemCollectionView.alpha = 1.0
                }
            })
            
        }
    }
}
