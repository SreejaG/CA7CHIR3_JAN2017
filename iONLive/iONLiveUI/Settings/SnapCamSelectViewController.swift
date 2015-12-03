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
    var cameraMode : Bool = false

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
        if indexPath.row == 0
        {
            customizeCellBasedOnSnapCamSelectionMode(cell)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        if isStreamStarted()
        {
            let alert: UIAlertView = UIAlertView()
            alert.title = "Steaming In Progress"
            alert.message = "Do you want to stop streaming?"
            let yesBut = alert.addButtonWithTitle("Yes")
            let noBut = alert.addButtonWithTitle("No")
            alert.delegate = self  // set the delegate here
            alert.show()

        }
     
        else
        {
            switch(indexPath.row)
            {
            case 0 :
                changeSnapCamMode(selectedCell)
//                cameraMode = !cameraMode
//                customizeCellBasedOnSnapCamSelectionMode(selectedCell);
//                self.snapCamSettingsTableView.reloadData()
//                
//                streamingDelegate?.cameraSelectionMode(cameraMode)
                break
            case 1:
                cameraMode =  true
                break
            default :
                cameraMode = true
                break
            }
        }
    }
    
    func changeSnapCamMode(selectedCell:UITableViewCell)
    {
        cameraMode = !cameraMode
        customizeCellBasedOnSnapCamSelectionMode(selectedCell);
        self.snapCamSettingsTableView.reloadData()
        
        streamingDelegate?.cameraSelectionMode(cameraMode)
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        let buttonTitle = alertView.buttonTitleAtIndex(buttonIndex)
        
        print("\(buttonTitle) pressed")
        if buttonTitle == "Yes" {
            
            let stream = UploadStream()
            stream.stopLiveStreaming()
            cameraMode = !cameraMode
            self.snapCamSettingsTableView.reloadData()
            streamingDelegate?.cameraSelectionMode(cameraMode)

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
    
    func customizeCellBasedOnSnapCamSelectionMode(selectedCell:UITableViewCell)
    {
        if cameraMode == false
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
//            selectedCell.setSelected(true, animated: true)
//            cameraMode = false
        }
        else
        {
            selectedCell.contentView.backgroundColor = UIColor.clearColor()
//            selectedCell.setSelected(false, animated: true)
//            cameraMode = true
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





