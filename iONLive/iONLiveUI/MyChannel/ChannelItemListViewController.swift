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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imageDataSource.removeAll()
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
        
        limit = fixedLimit
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
        offsetToInt = offsetToInt! + 6
        
        if offsetToInt <= totalMediaCount
        {
            totalCount = totalMediaCount - offsetToInt
            if totalCount > fixedLimit
            {
                limit = fixedLimit
            }
            else
            {
                limit = totalCount
            }
        }
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["objectJson"] as! [AnyObject]
            var imageDetails = UIImage?()
            for var index = 0; index < responseArr.count; index++
            {
                let mediaId = responseArr[index].valueForKey("media_detail_id")!.stringValue
                let mediaUrl = responseArr[index].valueForKey("thumbnail_name_SignedUrl") as! String
                let mediaType =  responseArr[index].valueForKey("gcs_object_type") as! String
                print(mediaId)
                print(mediaType)
                if(mediaUrl != "")
                {
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    let data = NSData(contentsOfURL: url)
                    if let imageData = data as NSData? {
                       imageDetails = UIImage(data: imageData)
                    }
                }
                 imageDataSource.append([mediaIdKey:mediaId, mediaUrlKey:imageDetails!, mediaTypeKey:mediaType])
            }
                if(totalMediaCount >= offsetToInt){
                    self.initialise()
                }
                 channelItemCollectionView.reloadData()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
    {
        self.removeOverlay()
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
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    @IBAction func didTapSelectionButton(sender: AnyObject) {
//        for index in self.channelItemCollectionView.indexPathsForSelectedItems()!
//        {
//            self.channelItemCollectionView.deselectItemAtIndexPath(index, animated: false)
//        }
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
            
            if totalMediaCount > 6
            {
                fixedLimit = 6
            }
            else{
                fixedLimit = totalMediaCount
            }
            
            limit = fixedLimit
            
            imageDataSource.removeAll()
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
        if imageDataSource.count > 0
        {
            return imageDataSource.count
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
        if imageDataSource.count > 0
        {
            if(imageDataSource.count == selectedArray.count){
            }
            else{
                selectedArray.append(0)
            }
           
            let mediaType = imageDataSource[indexPath.row][mediaTypeKey] as! String
            let channelItemImageView = cell.viewWithTag(100) as! UIImageView
            let imageData =  imageDataSource[indexPath.row][mediaUrlKey] as! UIImage
           
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
                    let selectedValue: String = imageDataSource[i][mediaIdKey] as! String
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
