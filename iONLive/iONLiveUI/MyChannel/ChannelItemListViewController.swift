//
//  ChannelItemListViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/28/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class ChannelItemListViewController: UIViewController {
    
    static let identifier = "ChannelItemListViewController"
    @IBOutlet weak var channelTitleLabel: UILabel!
    @IBOutlet weak var channelItemCollectionView: UICollectionView!
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    var selectionFlag : Bool = false
    var offset: String = "0"
    var offsetToInt = Int!()
    var totalMediaCount: Int = Int()
    var deleteMediaIds : [Int] = [Int]()
    var loadingOverlay: UIView?
    var imageDataSource: [[String:AnyObject]] = [[String:AnyObject]]()
    var channelId:String!
    var channelName:String!
    var dataSource:[String]?
    
    var mediaSelected: NSMutableDictionary = NSMutableDictionary()
    
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var selectionButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var backButton: UIButton!
    
    let cameraController = IPhoneCameraViewController()
    
    let mediaUrlKey = "mediaUrl"
    let mediaIdKey = "mediaId"
    let selectionKey = "selection"
    
    var limit : Int = 6
    var totalCount: Int = 0
    
    var cellStatus: NSMutableDictionary = NSMutableDictionary()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        imageDataSource.removeAll()
        offsetToInt = Int(offset)
        deleteButton.hidden = true
        addButton.hidden = true
        cancelButton.hidden = true
        selectionFlag = false
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
        let fixedLimit : Int = 6
        if limit < totalMediaCount
        {
            limit = totalMediaCount - limit
            if limit > fixedLimit
            {
                limit = fixedLimit
            }
        }
        totalCount = totalCount + limit
        imageUploadManger.getChannelMediaDetails(channelId , userName: userId, accessToken: accessToken, limit: String(limit), offset: offsetString, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
        }
        offsetToInt = offsetToInt! + 6
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
                
                if(mediaUrl != "")
                {
                    let url: NSURL = convertStringtoURL(mediaUrl)
                    let data = NSData(contentsOfURL: url)
                    if let imageData = data as NSData? {
                        imageDataSource.append([mediaIdKey:mediaId, mediaUrlKey:imageData])
                    }
                }
            }
            
            if(totalMediaCount >= totalCount){
                initialise()
            }
            self.channelItemCollectionView.reloadData()
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
        addChannelVC.mediaDetailSelected = mediaSelected
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
        channelTitleLabel.text = "SELECT"
        cancelButton.hidden = false
        selectionButton.hidden = true
        deleteButton.hidden = false
        addButton.hidden = false
        backButton.hidden = true
        deleteButton.enabled = false
        addButton.enabled = false
        addButton.setTitle("Share", forState: .Normal)
        mediaSelected.removeAllObjects()
        selectionFlag = true
    }
    
    @IBAction func didTapCancelButton(sender: AnyObject) {
        mediaSelected.removeAllObjects()
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
        if(mediaSelected.count > 0){
            for(key,_) in mediaSelected{
                deleteMediaIds.append(Int(key as! String)!)
            }
            channelIds.append(Int(channelId)!)
            print(deleteMediaIds)
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            showOverlay()
            
            imageUploadManger.deleteMediasByChannel(userId, accessToken: accessToken, mediaIds: deleteMediaIds, channelId: channelIds, success: { (response) -> () in
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
            offsetToInt = 0
            totalMediaCount = totalMediaCount - mediaSelected.count
            imageDataSource.removeAll()
            mediaSelected.removeAllObjects()
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
        
       collectionView.allowsMultipleSelection = true
        
        if(selectionFlag){
            
            
            if(cell.selected){
                cell.selectionView.hidden = false
            }
            else{
                cell.selectionView.hidden = true
            }
        }
        else{
            cell.selectionView.hidden = true
        }
        
        if imageDataSource.count > 0
        {
            let imageData =  imageDataSource[indexPath.row][mediaUrlKey] as! NSData
            cell.channelItemImageView.image = UIImage(data: imageData)
        }
        cell.tickButton.frame = CGRect(x: ((UIScreen.mainScreen().bounds.width/3)-2) - 25, y: 3, width: 20, height: 20)
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
           
            let cell = channelItemCollectionView.cellForItemAtIndexPath(indexPath) as! ChannelItemListCollectionViewCell
            cell.selectionView.alpha = 0.4
            cell.tickButton.frame = CGRect(x: ((UIScreen.mainScreen().bounds.width/3)-2) - 25, y: 3, width: 20, height: 20)
            cell.insertSubview(cell.selectionView, aboveSubview: cell.channelItemImageView)
            
            cell.selected = true
            
            cell.reloadInputViews()
            cell.selectionView.hidden = false
            
            let id: String = imageDataSource[indexPath.row][mediaIdKey]! as! String
            mediaSelected.setValue(String(indexPath.row), forKey: id)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = channelItemCollectionView.cellForItemAtIndexPath(indexPath) as! ChannelItemListCollectionViewCell
        cell.selected = false
        cell.reloadInputViews()
        cell.selectionView.hidden = true
        let id: String = imageDataSource[indexPath.row][mediaIdKey]! as! String
        mediaSelected.removeObjectForKey(id)
        
    }
    
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
}
