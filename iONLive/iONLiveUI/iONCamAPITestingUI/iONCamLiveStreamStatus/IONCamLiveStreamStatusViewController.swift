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
//     let identifier = iONCamLiveStatusManager.sharedInstance
//    var liveStaus : String?
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
        
                //call the success block that was passed with response data
                success?(response: responseObject)

                
            }

            }) { (error, code) -> () in
                   ErrorManager.sharedInstance.alert("Status Failed", message: "Failure to get streaming status ")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func iONLiveCamStreamGetStatusSuccessHandler(response:AnyObject?)
    {
        print("entered status")
        if let json = response as? [String: AnyObject]
        {
            print("success")
            if let liveStreamStatus = json["status"]
            {
              //  freememTextField.text = freemem as? String
                let alertController = UIAlertController(title: "Live Stream Status", message:
                   liveStreamStatus as! String, preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }

        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
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
//
   }


    extension IONCamLiveStreamStatusViewController:UITableViewDelegate,UITableViewDataSource
    {
        func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
        {
            return 75.0
        }
        
        func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
        {
            return tableViewDataSource.count//tableViewDataSource.count
        }
        
        func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
        {
            if tableViewDataSource.count > indexPath.row
            {
                var keys = Array(tableViewDataSource.keys)
                let values:Array = tableViewDataSource[keys[indexPath.row]]!
                print(values);
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
                    
                    //                let keyValue = keys[indexPath.row];
                    //                print(keyValue)
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

