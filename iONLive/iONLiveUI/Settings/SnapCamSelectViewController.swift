
import UIKit

class SnapCamSelectViewController: UIViewController {
    
    static let identifier = "SnapCamSelectViewController"
    @IBOutlet weak var snapCamSettingsTableView: UITableView!
    weak var streamingDelegate:StreamingProtocol?
    var snapCamMode : SnapCamSelectionMode = SnapCamSelectionMode()
    var toggleSnapCamIPhoneMode:SnapCamSelectionMode = .SnapCam
    
    @IBOutlet var titleLabel: UILabel!
    var rowAfterAlertHit: Int!
    var cellAfterAlertHit : UITableViewCell = UITableViewCell()
    
    @IBOutlet var activityLabel: UILabel!
    @IBOutlet var activityImageView: UIImageView!
    
    var dataSource = ["Live Stream", "Photos", "Video" , "Catch gif", "Time lapse", "Switch to iPhone","TestAPI"]
    
    @IBOutlet var iPhoneSnapCamImageView: UIImageView!
    @IBOutlet var blurView: UIView!
    @IBOutlet var snapCamButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       loadDefaults()
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
    
    func loadDefaults()
    {
        snapCamSettingsTableView.separatorStyle = .None
        snapCamButton.clipsToBounds = true
        snapCamButton.layer.cornerRadius = 5
        updateDatabaseForSnapCamOrIPhone()
    }
    
    func updateDatabaseForSnapCamOrIPhone()
    {
        let defaults = NSUserDefaults .standardUserDefaults()
        let shutterMode = defaults.integerForKey("shutterActionMode")
        switch(shutterMode)
        {
        case 0 :
            snapCamMode = .LiveStream
            break
        case 1:
            snapCamMode = .Photos
            break
        case 2:
            snapCamMode = .Video
            break
        case 3:
            snapCamMode = .CatchGif
            break
        case 4:
            snapCamMode = .Timelapse
            break
        case 5:
            snapCamMode = .iPhone
            break
        case 6:
            snapCamMode = .TestAPI
            break
        default :
            break
        }
        
        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.SnapCam
        {
            dataSource[5] = "Switch to iPhone"
            titleLabel.text = "Snapcam"
            snapCamButton.setImage(UIImage(named: "snapCamMode"), forState: .Normal)
            
        }
        else
        {
            dataSource[5] = "Switch to SnapCam"
            titleLabel.text = "iPhone"
            snapCamButton.setImage(UIImage(named: "iphone"), forState: .Normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    deinit {
        print("snapcamviewcontroller deinit")
    }

}

//PRAGMA MARK:- TableView datasource, delegates

extension SnapCamSelectViewController:UITableViewDataSource
{
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let count = dataSource.count
        return count > 0 ? count : 0
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
}

extension SnapCamSelectViewController:UITableViewDelegate
{
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let selectedCell:UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
        updateSnapCamModeSelection(indexPath.row, ForCell: selectedCell)
        
        switch indexPath.row
        {
        case 5:
            if  toggleSnapCamIPhoneMode == SnapCamSelectionMode.iPhone
            {
                titleLabel.text = "Snapcam"
                loadCameraViewWithFadeInFadeOutAnimation()
            }
            else
            {
                titleLabel.text = "iPhone"
                let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
                let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
                self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
                loadSnapCamViewWithFadeInFadeOutAnimation()
            }
            break
            
        case 6:
            loadAPITestView()
            break
            
        default :
//            self.dismissViewControllerAnimated(false, completion: nil)
            let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
            let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
            let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
            self.presentViewController(navController, animated: false) { () -> Void in
            }
            break;
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 60
    }
}

//PRAGMA MARK:- Helper Methods
extension SnapCamSelectViewController
{
    func updateSnapCamModeSelection(row:Int , ForCell selectedCell:UITableViewCell)
    {
        if isStreamStarted()
        {
            showAlertViewToStopStream(row, ForCell: selectedCell)
        }
        else
        {
            updateSnapCamSelection(row)
            changeSnapCamModeForCell(selectedCell)
        }
    }
    
    //PRAGMA MARK:- Animated views
    func loadSnapCamViewWithFadeInFadeOutAnimation()
    {
        self.blurView.alpha = 0;
        self.blurView.hidden = false;
        activityImageView.hidden = true;
        activityLabel.hidden = true;
        iPhoneSnapCamImageView.image = UIImage(named: "Switched_mode_Camera");
        snapCamSettingsTableView.hidden = true;
        
        UIView.animateWithDuration(1.0, animations: { () -> Void in
            self.blurView.alpha = 1.0
        }) { (finished) -> Void in
            UIView.animateWithDuration(1.0, animations: { () -> Void in
                self.blurView.alpha = 0.0
                }, completion: { (finshed) -> Void in
                    self.switchToiPhoneView()
            })
        }
    }
    
    func loadCameraViewWithFadeInFadeOutAnimation()
    {
        self.blurView.alpha = 0;
        self.blurView.hidden = false;
        activityImageView.image =  UIImage.animatedImageNamed("loader-", duration: 1.0)
        iPhoneSnapCamImageView.image = UIImage(named: "Switched modes");
        snapCamSettingsTableView.hidden = true;
        
        UIView .animateWithDuration(1.0, animations: { () -> Void in
            self.blurView.alpha = 1.0
            
        }) { (finished) -> Void in
            self.startSnapCamViewAnimation()
        }
    }
    
    func startSnapCamViewAnimation()
    {
        UIView .animateWithDuration(1.0, animations: { () -> Void in
            
            self.activityImageView.hidden = true;
            self.activityLabel.hidden = true;
            self.iPhoneSnapCamImageView.image = UIImage(named: "SnapCam Switched modes");
            
        }) { (finished) -> Void in
            
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                
                self.blurView.alpha = 0.0
                
                }, completion: { (finshed) -> Void in
                    self.switchToSnapCamView()
            })
        }
    }
    
    func switchToSnapCamView()
    {
        dataSource[5] = "Switch to SnapCam"
        toggleSnapCamIPhoneMode = SnapCamSelectionMode.SnapCam
        
        loadLiveStreamView()
    }
    
    func switchToiPhoneView()
    {
        dataSource[5] = "Switch to iPhone"
        toggleSnapCamIPhoneMode = SnapCamSelectionMode.iPhone
        loadCameraViewController()
    }
    
    //PRAGMA MARK:- LoadViews for each table Actions
    func loadLiveStreamView()
    {
        let vc = MovieViewController.movieViewControllerWithContentPath("rtsp://192.168.42.1:554/live", parameters: nil , liveVideo: true) as! MovieViewController
        clearStreamingUserDefaults(NSUserDefaults.standardUserDefaults())
        let navigationController:UINavigationController = UINavigationController(rootViewController: vc)
        navigationController.navigationBarHidden = true
        self.presentViewController(navigationController, animated: false) { () -> Void in
        }
    }
    
    func loadCameraViewController()
    {
//        self.dismissViewControllerAnimated(false, completion: nil)
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
        navController.navigationBarHidden = true
        self.presentViewController(navController, animated: false) { () -> Void in
        }
    }
    
    func loadAPITestView()
    {
        let storyBoard = UIStoryboard(name:"iONCamPictureAPITest" , bundle: nil)
        let testAPIListVC = storyBoard.instantiateViewControllerWithIdentifier(iONLiveCamAPIListViewController.identifier)
        self.navigationController?.pushViewController(testAPIListVC, animated: true)
    }
    
    
    func changeSelectedSnapCamMode(selectedMode:SnapCamSelectionMode)
    {
        if snapCamMode == selectedMode
        {
        }
        else
        {
            snapCamMode = selectedMode
            if snapCamMode != SnapCamSelectionMode.SnapCam && snapCamMode != SnapCamSelectionMode.iPhone
            {
                NSUserDefaults.standardUserDefaults().setObject(selectedMode.rawValue, forKey: "shutterActionMode");
            }
        }
    }
    
    func showAlertViewToStopStream(row:Int , ForCell selectedCell:UITableViewCell)
    {
        let alert: UIAlertView = UIAlertView()
        alert.title = "Streaming In Progress"
        alert.message = "Do you want to stop streaming?"
        alert.addButtonWithTitle("Yes")
        alert.addButtonWithTitle("No")
        alert.delegate = self
        rowAfterAlertHit = row
        cellAfterAlertHit = selectedCell
        alert.show()
    }
    
    func changeSnapCamModeForCell(selectedCell:UITableViewCell)
    {
        streamingDelegate?.cameraSelectionMode(snapCamMode)
        self.snapCamSettingsTableView.reloadData()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        let buttonTitle = alertView.buttonTitleAtIndex(buttonIndex)
        if buttonTitle == "Yes" {
            
            stopLiveStreaming()
            updateSnapCamSelection(rowAfterAlertHit)
            changeSnapCamModeForCell(cellAfterAlertHit)
            self.snapCamSettingsTableView.reloadData()
        }
        else
        {
            self.snapCamSettingsTableView.reloadData()
        }
    }
    
    func stopLiveStreaming()
    {
        if toggleSnapCamIPhoneMode == SnapCamSelectionMode.SnapCam
        {
            stopSnapCamCameraLiveStreaming()
        }
        else if toggleSnapCamIPhoneMode == SnapCamSelectionMode.iPhone
        {
            stopIPhoneCameraLiveStreaming()
        }
    }
    
    func stopSnapCamCameraLiveStreaming()
    {
        let stream = UploadStream()
        stream.stopStreamingClicked()
        streamingDelegate?.cameraSelectionMode(snapCamMode)
    }
    
    func stopIPhoneCameraLiveStreaming()
    {
        let liveStreaming = IPhoneLiveStreaming()
        liveStreaming.stopStreamingClicked()
    }
    
    //PRAGMA MARK:- customize table cell
    
    func customizeCellBasedOnSnapCamSelectionMode(selectedCell:UITableViewCell , row:Int)
    {
        if (snapCamMode == SnapCamSelectionMode.SnapCam || snapCamMode ==  SnapCamSelectionMode.iPhone) && row == 5
        {
            customizeSnapCamIPhoneCell(selectedCell)
        }
        else if snapCamMode == SnapCamSelectionMode.TestAPI && row == 6
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
        }
        else if snapCamMode.rawValue == row
        {
            selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
        }
        else
        {
            selectedCell.contentView.backgroundColor = UIColor.clearColor()
        }
    }
    
    func customizeSnapCamIPhoneCell(selectedCell : UITableViewCell)
    {
        selectedCell.contentView.backgroundColor = UIColor(red: 44/255, green: 214/255, blue: 224/255, alpha: 1.0)
    }
    
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
    
    //PRAGMA MARK:- User defaults
    func isStreamStarted()->Bool
    {
        let defaults = NSUserDefaults.standardUserDefaults()
        return  defaults.boolForKey("StartedStreaming")
    }
    
    func clearStreamingUserDefaults(defaults:NSUserDefaults)
    {
        defaults.removeObjectForKey(streamingToken)
        defaults.removeObjectForKey(startedStreaming)
        defaults.removeObjectForKey(initializingStream)
    }
    
    //PRAGMA MARK:- IBActions
    @IBAction func settingsbuttonClicked(sender: AnyObject)
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let settingsVC = storyBoard.instantiateViewControllerWithIdentifier("SettingsViewController") as! SettingsViewController
        
        let navController = UINavigationController(rootViewController: settingsVC)
        navController.navigationBarHidden = true
        self.presentViewController(navController, animated: false) { () -> Void in
        }
    }
    
    @IBAction func snapcamButtonClicked(sender: AnyObject)
    {
//        self.dismissViewControllerAnimated(false, completion: nil)
        
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
//        let navController = UINavigationController(rootViewController: iPhoneCameraViewController)
//        navController.navigationBarHidden = true
        
        self.presentViewController(iPhoneCameraViewController, animated: false) { () -> Void in
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
}





