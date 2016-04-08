//
//  MyChannelNotificationViewController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 3/11/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit


class MyChannelNotificationViewController: UIViewController {
    
    static let identifier = "MyChannelNotificationViewController"
    
    @IBOutlet var triangleView: UIImageView!
    @IBOutlet var NotificationLabelView: UIView!
    @IBOutlet var NotificationTableView: UITableView!
    
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    
    var loadingOverlay: UIView?
    
    var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    
    let usernameKey = "userName"
    let profileImageKey = "profileImage"
    let notificationTypeKey = "notificationType"
    let mediaTypeKey = "mediaType"
    let mediaImageKey = "mediaImage"
    let messageKey = "message"
    
    var tapFlag : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func didTapNotificationButton(sender: AnyObject) {
        if(tapFlag){
            let storyboard = UIStoryboard(name:"MyChannel", bundle: nil)
            let channelVC = storyboard.instantiateViewControllerWithIdentifier(MyChannelViewController.identifier) as! MyChannelViewController
            channelVC.navigationController?.navigationBarHidden = true
            self.navigationController?.pushViewController(channelVC, animated: true)
        }
    }
    
    func initialise(){
        NotificationTableView.layer.cornerRadius=10
        tapFlag = false
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getNotificationDetails(userId, token: accessToken)
    }
    
    func getNotificationDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getMediaInteractionDetails(userName, accessToken: token, success: { (response) -> () in
            self.authenticationSuccessHandler(response)
            
            }) { (error, message) -> () in
                self.authenticationFailureHandler(error, code: message)
                
        }}
    
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
    
    func convertStringtoURL(url : String) -> NSURL
    {
        let url : NSString = url
        let searchURL : NSURL = NSURL(string: url as String)!
        return searchURL
    }
    
    func authenticationSuccessHandler(response:AnyObject?)
    {
        removeOverlay()
        if let json = response as? [String: AnyObject]
        {
            let responseArr = json["notification Details"]!["mediaDetails"] as! [[String:AnyObject]]
            print(responseArr)
            
            var mediaImage : UIImage?
            var profileImage : UIImage?
            for element in responseArr{
                let username = element["user_name"] as! String
                let notifType = element["notification_type"] as! String
                let mediaType = element["gcs_object_type"] as! String
                let message = "\(username.capitalizedString) \(notifType.lowercaseString) your \(mediaType)"
                
                let mediaThumbUrl = element["thumbnail_name_SignedUrl"] as! String
               
                if(mediaThumbUrl != "")
                {
                    let url: NSURL = convertStringtoURL(mediaThumbUrl)
                    if let mediaData = NSData(contentsOfURL: url){
                       let mediaImageData = (mediaData as NSData?)!
                        mediaImage = UIImage(data: mediaImageData)
                    }
                }
                else{
                    mediaImage = UIImage(named: "thumb12")
                }
                let profileImageName = element["profile_image"]
                if let imageByteArray: NSArray = profileImageName!["data"] as? NSArray
                {
                    var bytes:[UInt8] = []
                    for serverByte in imageByteArray {
                        bytes.append(UInt8(serverByte as! UInt))
                    }
                    
                    if let profileData:NSData = NSData(bytes: bytes, length: bytes.count){
                        let profileImageData = profileData as NSData?
                        profileImage = UIImage(data: profileImageData!)
                    }
                }
                else{
                    profileImage = UIImage(named: "defUser")
                }

               dataSource.append([messageKey:message,profileImageKey:profileImage!,mediaImageKey:mediaImage!])

            }
            
            tapFlag = true
            NotificationTableView.reloadData()
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
}

extension MyChannelNotificationViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 55.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}

extension MyChannelNotificationViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
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
            let cell = tableView.dequeueReusableCellWithIdentifier(MyChannelNotificationCell.identifier, forIndexPath:indexPath) as! MyChannelNotificationCell
            
            cell.notificationText.text = dataSource[indexPath.row][messageKey] as? String
            cell.NotificationSenderImageView.image = dataSource[indexPath.row][profileImageKey] as? UIImage
            cell.NotificationImage.image = dataSource[indexPath.row][mediaImageKey] as? UIImage
            cell.selectionStyle = .None
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
}
