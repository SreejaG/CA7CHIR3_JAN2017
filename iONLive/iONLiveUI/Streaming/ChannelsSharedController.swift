//
//  ChannelsSharedController.swift
//  iONLive
//
//  Created by Gadgeon Smart Systems  on 4/11/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class ChannelsSharedController: UIViewController , UITableViewDelegate {
    
  var dataSource:[[String:AnyObject]] = [[String:AnyObject]]()
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    let channelNameKey = "channel_name"
    let sharedMediaCount = "total_no_media_shared"
    let timeStamp = "last_updated_time_stamp"
    let usernameKey = "user_name"
    let profileImageKey = "profile_image"
    let liveStreamStatus = "liveChannel"
    
//    let notificationTypeKey = "notificationType"
//    let mediaTypeKey = "mediaType"
    let mediaImageKey = "mediaImage"
//    let messageKey = "message"
    
    
    var loadingOverlay: UIView?

    @IBOutlet weak var ChannelSharedTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        initialise()
    }
    func initialise(){
        
        
        let defaults = NSUserDefaults .standardUserDefaults()
        let userId = defaults.valueForKey(userLoginIdKey) as! String
        let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
        getChannelSharedDetails(userId, token: accessToken)
    }
    func getChannelSharedDetails(userName: String, token: String)
    {
        showOverlay()
        channelManager.getChannelShared(userName, accessToken: token, success: { (response) -> () in
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
            
            print(json)
            let liveStream = json[liveStreamStatus] as! String

            let responseArr = json["channels"] as! [[String:AnyObject]]
            print(responseArr)
            if (responseArr.count == 0)
            {
                ErrorManager.sharedInstance.subscriptionEmpty()
            }
            var mediaImage : UIImage?
            var profileImage : UIImage?
            for element in responseArr{
                let channelName = element[channelNameKey]
                let mediaSharedCount = element[sharedMediaCount]
                let time = element[timeStamp] as! String
                let username = element[usernameKey] as! String
               // let notifType = element["notification_type"] as! String
              //  let mediaType = element["gcs_object_type"] as! String
               // let message = "\(username.capitalizedString) \(notifType.lowercaseString) your \(mediaType)"
                
               // let mediaThumbUrl = element["thumbnail_name_SignedUrl"] as! String
                let mediaThumbUrl = ""
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
                let profileImageName = element[profileImageKey]
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
                
                dataSource.append([channelNameKey:channelName!,sharedMediaCount:mediaSharedCount!,timeStamp:time,usernameKey:username,liveStreamStatus:liveStream, profileImageKey:profileImage!,mediaImageKey:mediaImage!])
                
            }
            
            ChannelSharedTableView.reloadData()
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
extension ChannelsSharedController:UITableViewDataSource
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
            let cell = tableView.dequeueReusableCellWithIdentifier(ChannelSharedCell.identifier, forIndexPath:indexPath) as! ChannelSharedCell
            
//            cell.channelProfileImage.layer.cornerRadius = 15
//            cell.channelProfileImage.clipsToBounds = true

            cell.channelProfileImage.image = dataSource[indexPath.row][profileImageKey] as? UIImage
            cell.channelNameLabel.text =  "My Day"
          //  cell.detailLabel.text =""
          cell.countLabel.hidden = true
           // cell.detailLabel.text = dataSource[indexPath.row][usernameKey] as! String

            if(dataSource[indexPath.row][liveStreamStatus] as! String == "1")
            {
               // var mediaImage : UIImage = UIImage()
                
                let text = "@" + (dataSource[indexPath.row][usernameKey] as! String) + "Live"
                  cell.currentUpdationImage.image  = UIImage(named: "Live_camera")
                let linkTextWithColor = "Live"
                
                let range = (text as NSString).rangeOfString(linkTextWithColor)
                
                let attributedString = NSMutableAttributedString(string:text)
                attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor() , range: range)
                cell.detailLabel.attributedText = attributedString

                
            }
            else if (dataSource[indexPath.row][sharedMediaCount]?.intValue == 0)
            {
                cell.currentUpdationImage.image  = UIImage(named: "thumb12")
                cell.detailLabel.text = dataSource[indexPath.row][usernameKey] as? String

            }
            else
            {
                cell.countLabel.hidden = false

                cell.countLabel.text = dataSource[indexPath.row][sharedMediaCount] as? String

                cell.detailLabel.text = "@" + (dataSource[indexPath.row][usernameKey] as! String) + "Live"

            }
            cell.selectionStyle = .None
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        
    }
    
}
