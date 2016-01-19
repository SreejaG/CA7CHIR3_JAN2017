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
    var snapCamMode : SnapCamSelectionMode = .Photos
    var toggleSnapCamIPhoneMode:SnapCamSelectionMode = .SnapCam

    var dataSource = ["Live Stream", "Photos", "Video" , "Catch gif", "Time lapse", "Switch to iPhone","TestAPI"]
   
    @IBOutlet var snapCamButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        snapCamSettingsTableView.separatorStyle = .None
        snapCamButton.clipsToBounds = true
        snapCamButton.layer.cornerRadius = 5
        updateDatabaseForSnapCamOrIPhone()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
//        let presentingViewController :UIViewController! = self.presentingViewController;
//        let vc:MovieViewController = presentingViewController as! MovieViewController
//        vc.initialiseDecoder()

    }
    
    func updateDatabaseForSnapCamOrIPhone()
    {
        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.SnapCam
        {
            dataSource[5] = "Switch to iPhone"
        }
        else
        {
            dataSource[5] = "Switch to SnapCam"
        }
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
        updateSnapCamModeSelection(indexPath.row, ForCell: selectedCell)
        
        switch indexPath.row
        {
        case 5:
            toggleSnapCamIPhoneSelection()
            break
            
        case 6:
            // TestAPI
            loadAPITestView()
            break
            
        default :
            break;
        }
    }
    
    func toggleSnapCamIPhoneSelection()
    {
        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.SnapCam
        {
            dataSource[5] = "Switch to iPhone"
            toggleSnapCamIPhoneMode = SnapCamSelectionMode.iPhone
            loadCameraViewController()
        }
        else
        {
            dataSource[5] = "Switch to SnapCam"
            toggleSnapCamIPhoneMode = SnapCamSelectionMode.SnapCam
            loadLiveStreamView()
        }
    }
    
//    func loadSnapCamOrIPhoneView()
//    {
//        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.iPhone
//        {
//            loadCameraViewController()
//        }
//        else
//        {
//            loadLiveStreamView()
//        }
//
//    }
    
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! UIViewController
        
        clearStreamingUserDefaults(NSUserDefaults.standardUserDefaults())
        let navigationController:UINavigationController = UINavigationController(rootViewController: vc)
        navigationController.navigationBarHidden = true
        self.presentViewController(navigationController, animated: true) { () -> Void in
        }
    }

    func clearStreamingUserDefaults(defaults:NSUserDefaults)
    {
        defaults.removeObjectForKey(streamingToken)
        defaults.removeObjectForKey(startedStreaming)
        defaults.removeObjectForKey(initializingStream)
    }

    func loadCameraViewController()
    {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        
        let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
        navController.navigationBarHidden = true
        self.presentViewController(navController, animated: true) { () -> Void in
        }
        
    }
    
    func loadAPITestView()
    {
        let storyBoard = UIStoryboard(name:"iONCamPictureAPITest" , bundle: nil)
        let testAPIListVC = storyBoard.instantiateViewControllerWithIdentifier(iONLiveCamAPIListViewController.identifier)
        self.navigationController?.pushViewController(testAPIListVC, animated: true)
    }

    func updateSnapCamModeSelection(row:Int , ForCell selectedCell:UITableViewCell)
    {
        if isStreamStarted()
        {
//            saveSelectedTypeTemporarily(row)
            showAlertViewToStopStream()
        }
        else
        {
            updateSnapCamSelection(row)
            changeSnapCamModeForCell(selectedCell)
        }
    }
    
//    func saveSelectedTypeTemporarily(rowVal:Int)
//    {
//        switch(rowVal)
//        {
//        case 0 :
//            restoreSnapCamMode = .LiveStream
//            break
//        case 1:
//            restoreSnapCamMode = .Photos
//            break
//        case 2:
//            restoreSnapCamMode = .Video
//            break
//        case 3:
//            restoreSnapCamMode = .CatchGif
//            break
//        case 4:
//            restoreSnapCamMode = .Timelapse
//            break
//        case 5:
//            restoreSnapCamMode = .iPhone
//            break
//        default :
//            break
//        }
//    }
//    
    func updateSnapCamSelection(rowVal:Int)
    {
        switch(rowVal)
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
        case 6:
            changeSelectedSnapCamMode(.TestAPI)
            break
       default :
            break
        }
    }
    
    func changeSelectedSnapCamMode(selectedMode:SnapCamSelectionMode)
    {
        if snapCamMode == selectedMode
        {
//            snapCamMode = .DefaultMode
        }
        else
        {
            snapCamMode = selectedMode
        }
    }
    
    func showAlertViewToStopStream()
    {
        let alert: UIAlertView = UIAlertView()
        alert.title = "Streaming In Progress"
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
            stream.stopStreamingClicked()
//            snapCamMode = restoreSnapCamMode
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
        if (snapCamMode == SnapCamSelectionMode.SnapCam || snapCamMode ==  SnapCamSelectionMode.iPhone) && row == 5
        {
            customizeSnapCamIPhoneCell(selectedCell)
        }
        else if snapCamMode == SnapCamSelectionMode.TestAPI && row == 6 // this is only for testing ,we can remove this once we can done.
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
        }
        else if snapCamMode.rawValue == row
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
    
    func customizeSnapCamIPhoneCell(selectedCell : UITableViewCell)
    {
        selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
    }
    
    func isStreamStarted()->Bool
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        return  defaults.boolForKey("StartedStreaming")
    }

    //PRAGMA MARK:- IBActions
    @IBAction func settingsbuttonClicked(sender: AnyObject)
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let settingsVC = storyBoard.instantiateViewControllerWithIdentifier("SettingsViewController") as! SettingsViewController
        
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.navigationBarHidden = true
        self.presentViewController(navController, animated: true) { () -> Void in
        }
    }
    @IBAction func snapcamButtonClicked(sender: AnyObject)
    {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}





