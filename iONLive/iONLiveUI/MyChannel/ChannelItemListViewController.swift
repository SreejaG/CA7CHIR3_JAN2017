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
    
    var offset: String = "0"
    var offsetToInt = Int!()
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
    
    var limit : Int = Int()
    var totalCount: Int = 0
    var fixedLimit : Int =  0
    
    var isLimitReached : Bool = true
    var currentLimit : Int = 0
    var limitMediaCount : Int = Int()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imageDataSource.removeAll()
        fullImageDataSource.removeAll()
        selectedArray.removeAll()
        selected.removeAllObjects()
        offsetToInt = Int(offset)
        deleteButton.hidden = true
        addButton.hidden = true
        cancelButton.hidden = true
        selectionFlag = false
        
        if totalMediaCount > 6
        {
            fixedLimit = 6
        }
        else{
            fixedLimit = totalMediaCount
        }
        
        //  limit = fixedLimit
        
        limit = totalMediaCount
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        if let channelName = channelName
        {
            channelTitleLabel.text = channelName.uppercaseString
        }
        
    }
    
    func initialise(){
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        showOverlay()
        
        let offsetString : String = String(offsetToInt)
        
        imageUploadManger.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
        }
        
        
        //        offsetToInt = offsetToInt! + 6
        //
        //        if offsetToInt <= totalMediaCount
        //        {
        //            totalCount = totalMediaCount - offsetToInt
        //            if totalCount > fixedLimit
        //            {
        //                limit = fixedLimit
        //            }
        //            else
        //            {
        //                limit = totalCount
        //            }
        //        }
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }
    
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["objectJson"] as! [AnyObject]
            for var index = 0; index < responseArr.count; index++
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")!.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                imageDataSource.append([mediaIdKey:mediaId, mediaUrlKey:mediaUrl, mediaTypeKey:mediaType])
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
            completion(result: UIImage(data: imageData)!)
        }
        else
        {
            print("null Image")
            completion(result:mediaImage)
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
        
        for var i = limitMediaCount ; i < currentLimit  ; i++ {
            let mediaUrl = imageDataSource[i][mediaUrlKey] as! String
            if(mediaUrl != ""){
                let url: NSURL = convertStringtoURL(mediaUrl)
                downloadMedia(url, key: "ThumbImage", completion: { (result) -> Void in
                    self.fullImageDataSource.append([self.mediaIdKey:self.imageDataSource[i][self.mediaIdKey]!, self.mediaUrlKey:result, self.mediaTypeKey:self.imageDataSource[i][self.mediaTypeKey]!])
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.channelItemCollectionView.reloadData()
                    })
                })
                
            }
        }
    }
    
    @IBAction func didTapBackButton(sender: AnyObject)
    {
        let notificationStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelVC = notificationStoryboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
        channelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(channelVC, animated: true)
    }
    
    @IBAction func didTapAddtoButton(sender: AnyObject) {
        let channelStoryboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let addChannelVC = channelStoryboard.instantiateViewControllerWithIdentifier(AddChannelViewController.identifier) as! AddChannelViewController
        addChannelVC.mediaDetailSelected = selected
        addChannelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(addChannelVC, animated: true)
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
            offset = "0"
            offsetToInt = Int(offset)
            totalCount = 0
            totalMediaCount = totalMediaCount - selected.count
            
//            if totalMediaCount > 6
//            {
//                fixedLimit = 6
//            }
//            else{
//                fixedLimit = totalMediaCount
//            }
            
            limit = totalMediaCount
           
            imageDataSource.removeAll()
            fullImageDataSource.removeAll()
            selected.removeAllObjects()
            selectionFlag = false
            
            limitMediaCount = 0
            currentLimit = 0
            isLimitReached = true
            
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
        }
        else{
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
}

extension ChannelItemListViewController : UIScrollViewDelegate{
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let fullyScrolledContentOffset:CGFloat = channelItemCollectionView.frame.size.width
        
        if (scrollView.contentOffset.x >= fullyScrolledContentOffset)
        {
            if(scrollView.contentOffset.x == fullyScrolledContentOffset)
            {
                print("End of scroll view")
                
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
                        // self.photoThumpCollectionView.reloadData()
                    })
                })
                
            }
            
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
        
        cell.videoView.alpha = 0.4
        if fullImageDataSource.count > 0
        {
            if(fullImageDataSource.count == selectedArray.count){
            }
            else{
                selectedArray.append(0)
            }
            
            let mediaType = fullImageDataSource[indexPath.row][mediaTypeKey] as! String
            let channelItemImageView = cell.viewWithTag(100) as! UIImageView
            let imageData =  fullImageDataSource[indexPath.row][mediaUrlKey] as! UIImage
            
            if mediaType == "video"
            {
                cell.videoView.hidden = false
                let imageToConvert: UIImage = imageData
                let sizeThumb = CGSizeMake(150, 150)
                let imageAfterConversionThumbnail = cameraController.thumbnaleImage(imageToConvert, scaledToFillSize: sizeThumb)
                channelItemImageView.image = imageAfterConversionThumbnail
            }
            else{
                cell.videoView.hidden = true
                channelItemImageView.image = imageData
            }
            
            cell.insertSubview(cell.videoView, aboveSubview: cell.channelItemImageView)
            
            if(selectionFlag){
                for var i = 0; i < selectedArray.count; i++
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
            
            
            for var i = 0;i < selectedArray.count; i++
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
        
    }
}
