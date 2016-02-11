//
//  IONLiveCamConfigViewController.swift
//  iONLive
//
//  Created by Vinitha on 2/5/16.
//  Copyright © 2016 Gadgeon. All rights reserved.
//

import UIKit

class IONLiveCamConfigViewController: UIViewController {

    static let identifier = "IONLiveCamConfigViewController"
    
    @IBOutlet var cameraConfigTableView: UITableView!
    
    
    //PRAGMA MARK: - DataSource
    var videoResolutionDataSource = []
    var tableViewDataSource = ["Video Resolution": ["3840x2160","1920x1080","1280x720","848x480"],"ButtonSingleClick":["Picture"],"videoFps":["240","200","120","100","60","50","30","25"],"buttonDoubleClick":["video"],"led":["on"],"quality":["1","2","3"],"scale":["1","2","4","8"]]
    
    //PRAGMA MARK:- class variables
    let requestManager = RequestManager.sharedInstance
    let iONLiveCameraConfigManager = iONLiveCameraConfiguration.sharedInstance
    
    //PRAGMA MARK:- loadView
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    //PRAGMA MARK:- API Handler
    
    func iONLiveCamGetConfigSuccessHandler(response:AnyObject?)
    {
        print("entered config")
        
        if let json = response as? [String: AnyObject]
        {
            print("success")
            if let quality = json["quality"]
            {
                let intVal = quality as! Int
                let stringVal = String(intVal)
                //                outputQualityTextField.text =  stringVal
            }
            if let scale = json["scale"]
            {
                let intVal = scale as! Int
                let stringVal = String(intVal)
                //                outputScaleTextField.text = stringVal
            }
            if let singleClick = json["singleClick"]
            {
                //                outputSingleClickTextField.text = singleClick as? String
            }
            if let doubleClick = json["doubleClick"]
            {
                //                outputDoubleClickTextField.text = doubleClick as? String
            }
        }
    }
    
    @IBAction func didTapPutCameraConfiguration(sender: AnyObject) {
        self.view.endEditing(true)
        //         iONLiveCameraConfigManager.putIONLiveCameraConfiguration(inputScaleTextField.text, quality: inputQualityTextField.text, singleClick: inputSingleClickTextField.text, doubleClick: inputDoubleClickTextField.text, success: { (response) -> () in
        //
        //             self.iONLiveCamGetConfigSuccessHandler(response)
        //
        //            }) { (error, code) -> () in
        //            ErrorManager.sharedInstance.alert("Config Failed", message: "Failure to get config ")
        //        }
        
    }
    
    @IBAction func didTapGetCameraConfiguration(sender: AnyObject) {
        self.view.endEditing(true)
        
        //        iONLiveCameraConfigManager.getiONLiveCameraConfiguration(inputScaleTextField.text, quality: inputQualityTextField.text, singleClick: inputSingleClickTextField.text, doubleClick: inputDoubleClickTextField.text, success: { (response) -> () in
        //
        //            self.iONLiveCamGetConfigSuccessHandler(response)
        //
        //            }) { (error, code) -> () in
        //                ErrorManager.sharedInstance.alert("Config Failed", message: "Failure to get config ")
        //        }
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    func createPickerViewTableViewCell()
    {
        
    }
}

extension IONLiveCamConfigViewController:UITableViewDelegate,UITableViewDataSource
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
                let cell = tableView.dequeueReusableCellWithIdentifier(PickerViewTableViewCell.identifier, forIndexPath: indexPath) as! PickerViewTableViewCell
                
                cell.inputLabel.text = keys[indexPath.row]
                cell.pickerViewData = values
                cell.selectionStyle = .None
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
}

//TextField Delegate
extension IONLiveCamConfigViewController:UITextFieldDelegate
{
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return false
    }
}
