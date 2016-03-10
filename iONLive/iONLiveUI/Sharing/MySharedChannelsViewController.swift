//
//  MySharedChannelsViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/22/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class MySharedChannelsViewController: UIViewController {

    static let identifier = "MySharedChannelsViewController"
    @IBOutlet weak var sharedChannelsTableView: UITableView!
    @IBOutlet weak var sharedChannelsSearchBar: UISearchBar!
    @IBOutlet weak var tableViewBottomConstaint: NSLayoutConstraint!
   
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance

    let channelNameKey = "channelName"
    let channelShareCountKey = "channelShareCount"
    let channelSelectionKey = "channelSelection"
    var channelDetails: NSMutableArray = NSMutableArray()

    var dataSource:[[String:String]] = [[String:String]]()
    var loadingOverlay: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
      //  createDummyDataSource()
        createChannelDataSource()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    @IBAction func backButtonClicked(sender: AnyObject)
    {
        self.dismissViewControllerAnimated(true) { () -> Void in
        }
    }
    func createChannelDataSource()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelDetails(userId, token: accessToken)
    }
    func createDummyDataSource()
    {
        dataSource = [[channelNameKey:"My Day",channelShareCountKey:"9",channelSelectionKey:"0"],[channelNameKey:"Work stuff",channelShareCountKey:"5",channelSelectionKey:"0"],[channelNameKey:"Ideas",channelShareCountKey:"8",channelSelectionKey:"0"]]
    }
    
    func getChannelDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getChannelDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                return
        }
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
        if tableViewBottomConstaint.constant == 0
        {
            self.tableViewBottomConstaint.constant = self.tableViewBottomConstaint.constant + keyboardFrame.size.height
        }
    }
    
    func keyboardDidHide()
    {
        if tableViewBottomConstaint.constant != 0
        {
            self.tableViewBottomConstaint.constant = 0
        }
    }
}


extension MySharedChannelsViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsHeaderCell.identifier) as! MySharedChannelsHeaderCell
        headerCell.headerTitleLabel.text = "MY SHARED CHANNELS"
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}


extension MySharedChannelsViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
//       return dataSource != nil ? (dataSource.count)! :0
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
//        if  dataSource
//        {
            if dataSource.count > indexPath.row
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(MySharedChannelsCell.identifier, forIndexPath:indexPath) as! MySharedChannelsCell
                cell.channelNameLabel.text = dataSource[indexPath.row][channelNameKey]
                cell.sharedCountLabel.text = dataSource[indexPath.row][channelShareCountKey]
                if Int(dataSource[indexPath.row][channelSelectionKey]!) == 0
                {
                    cell.channelSelectionButton.setImage(UIImage(named:"red-circle"), forState:.Normal)
                    cell.sharedCountLabel.hidden = true
                    cell.avatarIconImageView.hidden = true
                }
                else if Int(dataSource[indexPath.row][channelSelectionKey]!) == 1
                {
                    cell.channelSelectionButton.setImage(UIImage(named:"CheckOn"), forState:.Normal)
                    cell.sharedCountLabel.hidden = false
                    cell.avatarIconImageView.hidden = false
                }
                cell.cellDataSource = dataSource[indexPath.row]
                cell.selectionStyle = .None
                return cell
            }
      //  }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let sharingStoryboard = UIStoryboard(name:"sharing", bundle: nil)
        let channelDetailVC:UITabBarController = sharingStoryboard.instantiateViewControllerWithIdentifier(MyChannelDetailViewController.identifier) as! UITabBarController
//        if let dataSource = dataSource
//        {
            if dataSource.count > indexPath.row
            {
                if channelDetailVC.viewControllers?.count > 0
                {
                    let channelItemDetailVC = channelDetailVC.viewControllers![0] as! MyChannelItemDetailsViewController
                    channelItemDetailVC.channelName = dataSource[indexPath.row][channelNameKey]
                }
            }
       // }
 
        self.navigationController?.pushViewController(channelDetailVC, animated: true)
    }
    
    //Loading Overlay Methods
    func showOverlay(){
        let loadingOverlayController:IONLLoadingView=IONLLoadingView(nibName:"IONLLoadingOverlay", bundle: nil)
        loadingOverlayController.view.frame = self.view.bounds
        loadingOverlayController.startLoading()
        self.loadingOverlay = loadingOverlayController.view
        self.navigationController?.view.addSubview(self.loadingOverlay!)
    }

    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            print(json)
            channelDetails = json["channels"] as! NSMutableArray
            print(channelDetails)
            setChannelDetails()
        }
        else
        {
            ErrorManager.sharedInstance.inValidResponseError()
        }
    }
    func removeOverlay(){
        self.loadingOverlay?.removeFromSuperview()
    }
    func setChannelDetails()
    {
        for var index = 0; index < channelDetails.count; index++
        {
            let channelName = channelDetails[index].valueForKey("channel_name") as! String
            //            let totalMediaShared = channelDetails[index].valueForKey("total_no_media_shared") as! String
            //            let channelImageName = channelDetails[index].valueForKey("thumbnail_name") as! String
            
//            dataSource.append([channelNameKey:channelName, channelShareCountKey:"8", channelSelectionKey:"thumb9"])
            dataSource.append([channelNameKey:channelName, channelShareCountKey:"8", channelSelectionKey:"thumb9"])
        }
        sharedChannelsTableView.reloadData()
        
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
    

}
