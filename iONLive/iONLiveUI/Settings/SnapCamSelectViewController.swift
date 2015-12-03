//
//  SnapCamSelectViewController.swift
//  iONLive
//
//  Created by Gadgeon on 12/1/15.
//  Copyright © 2015 Gadgeon. All rights reserved.
//

import UIKit

class SnapCamSelectViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    static let identifier = "SnapCamSelectViewController"
    @IBOutlet weak var snapCamSettingsTableView: UITableView!
    var streamingDelegate:StreamingProtocol?
    var snapCamMode : SnapCamSelectionMode = .DefaultMode
//    var restoreSnapCamMode:SnapCamSelectionMode = .DefaultMode

    var dataSource = ["Live Stream", "Photos", "Video" , "Catch gif", "Time lapse", "Switch to iPhone"]
   
    @IBOutlet var snapCamButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        snapCamSettingsTableView.separatorStyle = .None
        snapCamButton.clipsToBounds = true
        snapCamButton.layer.cornerRadius = 5
    }
    
    override func viewWillDisappear(animated: Bool) {
        
//        let presentingViewController :UIViewController! = self.presentingViewController;
//        let vc:MovieViewController = presentingViewController as! MovieViewController
//        vc.initialiseDecoder()

    }
    
    // Blur for ios 8
    
    //    override func viewWillAppear(animated: Bool) {
    //            self.view.backgroundColor = UIColor.clearColor()
    //            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
    //            let blurEffectView = UIVisualEffectView(effect: blurEffect)
    //            //always fill the view
    //            blurEffectView.frame = self.view.bounds
    //            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
    //            self.view.addSubview(blurEffectView)
    //            self.view.bringSubviewToFront(snapCamSettingsTableView)//if you have more UIViews, use an insertSubview API to place it where needed
    //        }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //PRAGMA MARK:- TableView datasource, delegates
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let count = dataSource.count
        if count > 0
        {
            return count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
       let cell = tableView.dequeueReusableCellWithIdentifier(SnapCamTableViewCell.identifier, forIndexPath: indexPath) as! SnapCamTableViewCell
        
        if dataSource.count > indexPath.row
        {
            cell.optionlabel.text = dataSource[indexPath.row]
        }
        
        customizeCellBasedOnSnapCamSelectionMode(cell , row: indexPath.row)

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        
        if isStreamStarted()
        {
//            restoreSnapCamMode.rawValue = indexPath.row
            showAlertViewToStopStream()
        }
     
        else
        {
            print("selected index = \(indexPath.row)")
            switch(indexPath.row)
            {
            case 0 :
                changeSelectedSnapCamMode(.LiveStream)
                break
            case 1:
                changeSelectedSnapCamMode(.Photos)
                break
            case 2:
                changeSelectedSnapCamMode(.Video)
                break
            case 3:
                changeSelectedSnapCamMode(.CatchGif)
                break
            case 4:
                changeSelectedSnapCamMode(.Timelapse)
                break
            case 5:
                changeSelectedSnapCamMode(.iPhone)
                break
            default :
                break
            }
            changeSnapCamModeForCell(selectedCell)
        }
    }
    
    func changeSelectedSnapCamMode(selectedMode:SnapCamSelectionMode)
    {
        if snapCamMode == selectedMode
        {
            snapCamMode = .DefaultMode
        }
        else
        {
            snapCamMode = selectedMode
        }
    }
    
    func showAlertViewToStopStream()
    {
        let alert: UIAlertView = UIAlertView()
        alert.title = "Steaming In Progress"
        alert.message = "Do you want to stop streaming?"
        alert.addButtonWithTitle("Yes")
        alert.addButtonWithTitle("No")
        alert.delegate = self
        alert.show()
    }
    
    func changeSnapCamModeForCell(selectedCell:UITableViewCell)
    {
        print("indexPathForSelectedRow = \(snapCamSettingsTableView.indexPathForSelectedRow?.row)")
        
        streamingDelegate?.cameraSelectionMode(snapCamMode)
        self.snapCamSettingsTableView.reloadData()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        let buttonTitle = alertView.buttonTitleAtIndex(buttonIndex)
        
        print("\(buttonTitle) pressed")
        if buttonTitle == "Yes" {
            
            let stream = UploadStream()
            stream.stopLiveStreaming()
            snapCamMode = .DefaultMode
            self.snapCamSettingsTableView.reloadData()
            streamingDelegate?.cameraSelectionMode(snapCamMode)

        }
        else
        {
            self.snapCamSettingsTableView.reloadData()
            print("No Pressed")
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
        //return snapCamSettingsTableView.bounds.height / CGFloat(dataSource.count)
    }
    
    func customizeCellBasedOnSnapCamSelectionMode(selectedCell:UITableViewCell , row:Int)
    {
        if snapCamMode.rawValue == row
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
//            selectedCell.setSelected(true, animated: true)
        }
        else
        {
            selectedCell.contentView.backgroundColor = UIColor.clearColor()
//            selectedCell.setSelected(false, animated: true)
        }
    }
    
    func isStreamStarted()->Bool
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        return  defaults.boolForKey("StartedStreaming")
    }

    //PRAGMA MARK:- IBActions
    @IBAction func settingsbuttonClicked(sender: AnyObject)
    {
        
    }
    @IBAction func snapcamButtonClicked(sender: AnyObject)
    {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}





