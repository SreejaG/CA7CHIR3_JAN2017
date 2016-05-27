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
    }
    
    func initialise(){
        imageDataSource.removeAll()
        fullImageDataSource.removeAll()
        selectedArray.removeAll()
        selected.removeAllObjects()

        selectionButton.hidden = true
        
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
 
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64)
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
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
        removeOverlay()
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
                imageDataSource.append([mediaIdKey:mediaId!, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType,actualImageKey:actualUrl,notificationKey:notificationType])
            }
            if(imageDataSource.count > 0){
                let qualityOfServiceClass = QOS_CLASS_BACKGROUND
                let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
                dispatch_async(backgroundQueue, {
                   self.downloadMediaFromGCS()
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                      self.selectionButton.hidden = false
                    })
                })
            }
            else{
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
        for i in 0 ..< totalMediaCount
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
                            FileManagerViewController.sharedInstance.saveImageToFilePath(mediaIdForFilePath, mediaImage: result)
                            imageForMedia = result
                        }
                    })
                }
            }
        
                self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:imageForMedia, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!,self.actualImageKey:self.imageDataSource[i][self.actualImageKey]!,self.notificationKey:self.imageDataSource[i][self.notificationKey]!])
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
        let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
        addChannelVC.mediaDetailSelected = selected
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
        addButton.setTitle("Share", forState: .Normal)
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
        if(selected.count > 0){
            channelIds.append(Int(channelId)!)
            
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            showOverlay()
            
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
            imageDataSource.removeAll()
            fullImageDataSource.removeAll()
            selected.removeAllObjects()
            
            selectionFlag = false
            
            initialise()
            
            channelTitleLabel.text = channelName.uppercaseString
            cancelButton.hidden = true
            selectionButton.hidden = false
            deleteButton.hidden = true
            addButton.hidden = true
            backButton.hidden = false
            channelItemCollectionView.reloadData()
        }
    }
    
    func authenticationFailureHandlerDelete(error: NSError?, code: String)
    {
        self.removeOverlay()
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
}

extension ChannelItemListViewController : UICollectionViewDataSource,UICollectionViewDelegateFlowLayout
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        print(fullImageDataSource.count)
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
            if(fullImageDataSource.count == selectedArray.count){
            }
            else{
                selectedArray.append(0)
            }
            
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
            
//            cell.videoPlayIcon.frame = CGRect(x: 2, y: (Int(UIScreen.mainScreen().bounds.width/3)-2) - 16 , width: 10, height: 10)
            cell.insertSubview(cell.videoView, aboveSubview: cell.channelItemImageView)
            
            if(selectionFlag){
                for i in 0 ..< selectedArray.count
                {
                    let selectedValue: String = fullImageDataSource[i][mediaIdKey] as! String
                    if indexPath.row == i
                    {
                        if selectedArray[i] == 1
                        {
                            cell.selectionView.hidden = false
                            cell.insertSubview(cell.selectionView, aboveSubview: cell.videoView)
                            if(selected.containsObject(Int(selectedValue)!)){
                                
                            }
                            else{
                                selected.addObject(Int(selectedValue)!)
                            }
                        }
                        else{
                            cell.selectionView.hidden = true
                            cell.insertSubview(cell.videoView, aboveSubview: cell.selectionView)
                            if(selected.containsObject(Int(selectedValue)!)){
                                selected.removeObject(Int(selectedValue)!)
                            }
                            else{
                                
                            }
                            
                        }
                    }
                }
            }
            else{
                cell.selectionView.hidden = true
            }
        }
        else{
            channelItemImageView.image = UIImage(named: "thumb12")
//            cell.videoView.hidden = true
//            cell.selectionView.hidden = true
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
            
            for i in 0 ..< selectedArray.count
            {
                
                if i == indexPath.row
                {
                    if selectedArray[i] == 0
                    {
                        selectedArray[i] = 1
                        
                    }else{
                        selectedArray[i] = 0
                    }
                }
            }
            collectionView.reloadData()
        }
        else{
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let vc = MovieViewController.movieViewControllerWithImageVideo(fullImageDataSource[indexPath.row][actualImageKey] as! String, channelName: channelName, userName: userId, mediaType: fullImageDataSource[indexPath.row][mediaTypeKey] as! String, profileImage: UIImage(), videoImageUrl: fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage, notifType: fullImageDataSource[indexPath.row][notificationKey] as! String,mediaId: fullImageDataSource[indexPath.row][mediaIdKey] as! String,isProfile: true) as! MovieViewController
            self.presentViewController(vc, animated: false) { () -> Void in
                
            }
        }
        
    }
}
