//
//  IONCamLiveStreamStatusViewController.swift
//  iONLive
//
//  Created by Gadgeon on 2/9/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class IONCamLiveStreamStatusViewController: UIViewController {
    
    @IBOutlet weak var liveStreamTableView: UITableView!
    static let identifier = "IONCamLiveStreamStatusViewController"
    let iONLiveStreamStatusManager  = iONCamLiveStatusManager.sharedInstance
    
    var FrameRateDataSource = []
    var tableViewDataSource = ["FrameRate": ["30","15"],"Resolution":["848x480",
        "424x240"]]
    func getIONLiveStatus( success: ((response: AnyObject?)->())?, failure: ((error: NSError?, code: String)->())?)
    {
        iONLiveStreamStatusManager.getiONLiveCameraStatus({ (response) -> () in
            if let responseObject = response as? [String:AnyObject]
            {
                success?(response: responseObject)
            }
        }) { (error, code) -> () in
            ErrorManager.sharedInstance.alert("Status Failed", message: "Failure to get streaming status ")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func iONLiveCamStreamGetStatusSuccessHandler(response:AnyObject?)
    {
        if let json = response as? [String: AnyObject]
        {
            if let liveStreamStatus = json["status"]
            {
                let alertController = UIAlertController(title: "Live Stream Status", message:
                    liveStreamStatus as! String, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func getLiveStreamStatus(sender: AnyObject) {
        self.getIONLiveStatus({ (response) -> () in
            self.iONLiveCamStreamGetStatusSuccessHandler(response)
            }, failure: { (error, code) -> () in
                
        })
    }
    
    @IBAction func startLiveStreamAction(sender: AnyObject) {
        //        iONCamLiveStatusManager.putIONLiveCameraStreamConfiguration(inputScaleTextField.text, quality: inputQualityTextField.text, singleClick: inputSingleClickTextField.text, doubleClick: inputDoubleClickTextField.text, success: { (response) -> () in
        //
        //            self.iONLiveCamGetConfigSuccessHandler(response)
        //
        //            }) { (error, code) -> () in
        //                ErrorManager.sharedInstance.alert("Config Failed", message: "Failure to get config ")
    }
}

extension IONCamLiveStreamStatusViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 75.0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tableViewDataSource.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if tableViewDataSource.count > indexPath.row
        {
            var keys = Array(tableViewDataSource.keys)
            let values:Array = tableViewDataSource[keys[indexPath.row]]!
            if values.count > 1
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(StreamPickerTableViewCell.identifier, forIndexPath: indexPath) as! StreamPickerTableViewCell
                
                cell.inputlabel.text = keys[indexPath.row]
                cell.pickerViewData = values
                cell.selectionStyle = .None
                cell.frameratePickerView.reloadAllComponents()
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier(SimpleTextFieldTableViewCell.identifier, forIndexPath: indexPath) as! SimpleTextFieldTableViewCell
                cell.inputLabel.text = keys[indexPath.row]
                cell.inputTextField.text = values[0]
                cell.selectionStyle = .None
                return cell
                
            }
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        //        switch indexPath.row
        //        {
        //        case 0:
        //            loadPictureAPIViewController()
        //            break;
        //        case 1:
        //            loadIONLiveCamVideo()
        //            break;
        //        case 2:
        //            loadCameraConfiguration()
        //        case 5:
        //            loadCameraStatus()
        //        default:
        //            break;
        //        }
    }
}

