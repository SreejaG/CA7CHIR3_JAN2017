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
    var dataSource:[[String:String]] = [[String:String]]()
    let channelNameKey = "channelName"
    let channelShareCountKey = "channelShareCount"
    let channelSelectionKey = "channelSelection"
    
    let channelSubscribedUser="subscriber_user_id"
    let channelNotificationTyp="notification_type"
    let channelNotificationComment="comment"
    var shadowLayer: CAShapeLayer!
    let channelManager = ChannelManager.sharedInstance
    let requestManager = RequestManager.sharedInstance
    var loadingOverlay: UIView?
    var channelDetails: NSMutableArray = NSMutableArray()
    let userDict: NSMutableDictionary = NSMutableDictionary()

    @IBOutlet var triangleView: UIImageView!
    @IBOutlet var NotificationLabelView: UIView!
    @IBOutlet var NotificationTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
      //  createDummyDataSource()
createChannelNotificationDataSource()
        roundViewCorner()
        // Do any additional setup after loading the view.
    }

    @IBOutlet var triangleViewRight: UIImageView!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func roundViewCorner()
    {
        NotificationTableView.layer.cornerRadius=10
        //drawLeftTriangle(triangleView.bounds)
    }
    func createDummyDataSource()
    {
        dataSource = [[channelNameKey:"My Day",channelShareCountKey:"9",channelSelectionKey:"0"],[channelNameKey:"Work stuff",channelShareCountKey:"5",channelSelectionKey:"0"],[channelNameKey:"Ideas",channelShareCountKey:"8",channelSelectionKey:"0"]]
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
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
                
                    cell.notificationText.text = dataSource[indexPath.row][channelNotificationComment]

                        cell.NotificationSenderImageView.image = UIImage(named: "boyFace")
                cell.NotificationImage.image = UIImage(named: "boyFace")
                
                cell.selectionStyle = .None
                return cell
            }
            return UITableViewCell()
        }
        
        func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
        {
           
        }
        func drawLeftTriangle(rect: CGRect) {
            
            // Get Height and Width
            let layerHeight = triangleView.layer.frame.height
            let layerWidth = triangleView.layer.frame.width
            
            // Create Path
            let bezierPath = UIBezierPath()
            
            // Draw Points
            bezierPath.moveToPoint(CGPointMake(0, layerHeight))
            bezierPath.addLineToPoint(CGPointMake(layerWidth, layerHeight))
            bezierPath.addLineToPoint(CGPointMake(layerHeight, 0))
            bezierPath.addLineToPoint(CGPointMake(0, layerHeight))
            bezierPath.closePath()
            
            // Apply Color
            UIColor.greenColor().setFill()
            bezierPath.fill()
            
            // Mask to Path
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = bezierPath.CGPath
            triangleView.layer.mask = shapeLayer
            
        }
        
        func createChannelNotificationDataSource()
        {
            let defaults = NSUserDefaults .standardUserDefaults()
            let userId = defaults.valueForKey(userLoginIdKey) as! String
            let accessToken = defaults.valueForKey(userAccessTockenKey) as! String
            getChannelDetails(userId, token: accessToken)
        }
        func getChannelDetails(userName: String, token: String)
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
        func authenticationSuccessHandler(response:AnyObject?)
        {
            removeOverlay()
            if let json = response as? [String: AnyObject]
            {
                print(json)
             //   channelDetails = json["notification Details"] as! NSMutableArray
                let responseArr = json["notification Details"] as! [AnyObject]
                
                for element in responseArr{
                    userDict.setDictionary(element as! [NSObject : AnyObject])
                }
               
                print(userDict)
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
              //  let channelName = userDict[index].valueForKey("channel_name") as! String
                let channelSubscriberid = userDict["media_detail_id"] as! String
                let channelSubscribComment = userDict["comment"] as! String
                //            let totalMediaShared = channelDetails[index].valueForKey("total_no_media_shared") as! String
                //            let channelImageName = channelDetails[index].valueForKey("thumbnail_name") as! String
                
                //            dataSource.append([channelNameKey:channelName, channelShareCountKey:"8", channelSelectionKey:"thumb9"])
                dataSource.append([channelSubscribedUser:channelSubscriberid, channelNotificationComment:channelSubscribComment, channelSelectionKey:"thumb9"])
            }
            
            
           
            NotificationTableView.reloadData()
            
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
