//
//  AddChannelViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 04/03/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class AddChannelViewController: UIViewController {

    static let identifier = "AddChannelViewController"
    
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var channelCreateButton: UIView!
    @IBOutlet var channelTextField: UITextField!
    
    @IBOutlet var addChannelTableView: UITableView!
    var userId : String!
    var accessToken : String!
    
    let imageUploadManger = ImageUpload.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelManager = ChannelManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    let channelNameKey = "channelName"
    let channelItemCountKey = "channelItemCount"
    let channelHeadImageNameKey = "channelHeadImageName"
    let channelIdKey = "channelId"
    let channelCreatedTimeKey = "channelCreatedTime"
    
    var channelSelected: NSMutableDictionary = NSMutableDictionary()
    
    var dataSource:[[String:String]] = [[String:String]]()
    
    var channelDetails: NSMutableArray = NSMutableArray()
    
    var mediaDetailSelected : NSMutableDictionary = NSMutableDictionary()
    var addMediaIds : [Int] = [Int]()
    var addChannelIds : [Int] = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
   
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func initialise()
    {
        addChannelIds.removeAll()
        channelSelected.removeAllObjects()
        addMediaIds.removeAll()
        let defaults = NSUserDefaults.standardUserDefaults()
        userId = defaults.valueForKey(userLoginIdKey) as! String
        accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
        channelCreateButton.hidden = true
        channelTextField.addTarget(self, action: "textFieldDidChange:", forControlEvents: UIControlEvents.EditingChanged)
    }
    
    func textFieldDidChange(textField: UITextField)
    {
        if let text = textField.text where !text.isEmpty
        {
            if text.characters.count >= 3
            {
                channelCreateButton.hidden = false
            }
            else
            {
                channelCreateButton.hidden = true
            }
        }
        
    }
    
    @IBAction func didTapCancelButon(sender: AnyObject){
        let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
        let channelVC = storyboard.instantiateViewControllerWithIdentifier(ChannelItemListViewController.identifier) as! ChannelItemListViewController
        channelVC.navigationController?.navigationBarHidden = true
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func didTapGestureRecognizer(sender: AnyObject) {
        view.endEditing(true)
    }
    
    @IBAction func didTapCreateButton(sender: AnyObject) {
        let channelname: String = channelTextField.text!
        channelTextField.text = ""
        channelCreateButton.hidden = true
        channelTextField.resignFirstResponder()
        channelSelected.removeAllObjects()
        addChannelDetails(userId, token: accessToken, channelName: channelname)
    }
    
    func getChannelDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandlerList(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }
    
    func addChannelDetails(userName: String, token: String, channelName: String)
    {
        showOverlay()
        channelManager.addChannelDetails(userName, accessToken: token, channelName: channelName, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }

    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            channelTextField.text = ""
            getChannelDetails(userId, token: accessToken)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
    func authenticationFailureHandler(error: NSError?, code: String)
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

    func authenticationSuccessHandlerList(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            channelDetails = json["channels"] as! NSMutableArray
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }

    func setChannelDetails()
    {
        dataSource.removeAll()
        for var index = 0; index < channelDetails.count; index++
        {
            let channelId = channelDetails[index].valueForKey("channel_detail_id")?.stringValue
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            let mediaSharedCount = channelDetails[index].valueForKey("total_no_media_shared")?.stringValue
            var thumbUrl = channelDetails[index].valueForKey("thumbnail_Url") as! String
            if thumbUrl == "" {
                thumbUrl = ""
            }
            let createdTime = channelDetails[index].valueForKey("last_updated_time_stamp") as! String
            
            dataSource.append([channelIdKey:channelId!, channelNameKey:channelName, channelItemCountKey:mediaSharedCount!, channelCreatedTimeKey: createdTime, channelHeadImageNameKey:thumbUrl])
        }
        
        dataSource.sortInPlace({ p1, p2 in
            let time1 = p1[channelCreatedTimeKey]
            let time2 = p2[channelCreatedTimeKey]
            return time1 > time2
        })
        addChannelTableView.reloadData()
        
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
    
    
    func addKeyboardObservers()
    {
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidShow:", name: UIKeyboardDidShowNotification, object:nil)]
        [NSNotificationCenter .defaultCenter().addObserver(self, selector:"keyboardDidHide", name: UIKeyboardWillHideNotification, object:nil)]
    }
    
    func keyboardDidShow(notification:NSNotification)
    {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        if tableViewBottomConstraint.constant == 0
        {
            self.tableViewBottomConstraint.constant = self.tableViewBottomConstraint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstraint.constant != 0
        {
            self.tableViewBottomConstraint.constant = 0
        }
    }
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    
    @IBAction func didTapShareButton(sender: AnyObject) {
        addChannelIds.removeAll()
        addMediaIds.removeAll()

        if(channelSelected.count > 0){
            for(_,value) in channelSelected{
                addChannelIds.append(value as! Int)
            }
            for(_,value) in mediaDetailSelected{
                addMediaIds.append(value as! Int)
            }
            print(addChannelIds)
            print(addMediaIds)
            addMediaToChannels(addChannelIds, mediaIds: addMediaIds)
            
        }
    }
    
    func addMediaToChannels(channelIds:NSArray, mediaIds:NSArray){
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        showOverlay()
        imageUploadManger.addMediaToChannel(userId, accessToken: accessToken, mediaIds: mediaIds, channelId: channelIds, success: { (response) -> () in
                self.authenticationSuccessHandlerAdd(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
    }
    
    func authenticationSuccessHandlerAdd(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            channelTextField.text = ""
            getChannelDetails(userId, token: accessToken)
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    
}

extension AddChannelViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}

extension AddChannelViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        //        return dataSource != nil ? (dataSource.count)! :0
        if dataSource.count > 0
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if dataSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(AddChannelCell.identifier, forIndexPath:indexPath) as! AddChannelCell
            cell.accessoryType = .None
            cell.addChannelTextLabel.text = dataSource[indexPath.row][channelNameKey]
            cell.addChannelCountLabel.text = dataSource[indexPath.row][channelItemCountKey]
            let imageName =  dataSource[indexPath.row][channelHeadImageNameKey]! as String
            if(imageName != "")
            {
                let url: NSURL = convertStringtoURL(imageName)
                let data = NSData(contentsOfURL: url)
                if let imageData = data as NSData? {
                    cell.addChannelImageView.image = UIImage(data: imageData)
                }
            }
            
            cell.selectionStyle = .None
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let id: String = dataSource[indexPath.row][channelIdKey]! as String
            if(cell.accessoryType == .Checkmark){
                channelSelected.removeObjectForKey( String(indexPath.row))
                cell.accessoryType = .None
            }
            else{
                channelSelected.setValue(Int(id), forKey: String(indexPath.row))
                cell.accessoryType = .Checkmark
            }
        }
        print(channelSelected)
    }
    
}



