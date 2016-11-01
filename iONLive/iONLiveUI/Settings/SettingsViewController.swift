
import UIKit

class SettingsViewController: UIViewController, UIGestureRecognizerDelegate ,toggleCellDelegate {
    
    let optionTitle = "optionTitle"
    let optionType = "optionType"
    let accessryText = "accessryText"
    
    let toggleCell = "toggleCell"
    let normalCell = "normalCell"
    
    var cameraOptions = [[String:String]]()
    var accountOptions = [[String:String]]()
    var supportOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var backbutton: UIButton!
    @IBOutlet weak var settingsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraOptions = [[optionTitle:"Upload to wifi", optionType : toggleCell, accessryText:""],[optionTitle:"Vivid Mode", optionType : toggleCell, accessryText:""],[optionTitle:"Time Lapse", optionType : normalCell, accessryText:""],[optionTitle:"Media Capture Quality", optionType : normalCell, accessryText:"HD"],[optionTitle:"Camera LED", optionType : toggleCell, accessryText: ""],[optionTitle:"Program Camera Button", optionType : normalCell, accessryText: ""],
                         [optionTitle:"Software Updates", optionType : normalCell, accessryText: ""],[optionTitle:"Save to Camera Roll", optionType : toggleCell, accessryText: ""],[optionTitle:"Get Snapcam! ", optionType : normalCell, accessryText: ""],[optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]]
        
        accountOptions = [[optionTitle:"Edit profile", optionType : normalCell, accessryText:""],[optionTitle:"Delete Archived Media", optionType : normalCell, accessryText:"Never"],[optionTitle:"Connect Accounts", optionType : normalCell, accessryText:""]]
        
        supportOptions = [[optionTitle:"Help Center ", optionType : normalCell, accessryText:""],[optionTitle:"Report a Problem", optionType : normalCell, accessryText:""], [optionTitle:"App Info ", optionType : normalCell, accessryText:""]]
        
        dataSource = [cameraOptions,accountOptions,supportOptions]
        
        if(NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") != nil)
        {
            let value = NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") as! String
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:value]
        }
        else{
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.settingsTableView.backgroundView = nil
        self.settingsTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
        backbutton.hidden = true
        reloadTableData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    func reloadTableData(){
        if(NSUserDefaults.standardUserDefaults().valueForKey("archiveMediaDeletion") != nil)
        {
            let archiveConstant = NSUserDefaults.standardUserDefaults().valueForKey("archiveMediaDeletion") as! String
            dataSource![1][1] = [optionTitle:"Delete Archived Media", optionType : normalCell, accessryText:archiveConstant]
        }
        else{
            dataSource![1][1] = [optionTitle:"Delete Archived Media", optionType : normalCell, accessryText:"Never"]
        }
        
        if(NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") != nil)
        {
            let liveResolutionConstant = NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") as! String
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:liveResolutionConstant]
        }
        else{
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]
        }
        
        settingsTableView.reloadData()
    }
    
    @IBAction func doneClicked(sender: AnyObject) {
        let cameraViewStoryboard = UIStoryboard(name:"IPhoneCameraView" , bundle: nil)
        let iPhoneCameraViewController = cameraViewStoryboard.instantiateViewControllerWithIdentifier("IPhoneCameraViewController") as! IPhoneCameraViewController
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.pushViewController(iPhoneCameraViewController, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        doneButton.hidden = false
        backbutton.hidden = true
        settingsTableView.reloadData()
        self.settingsTableView.userInteractionEnabled = true
    }
    
   // #pragma mark - toggleCellDelegate
    
    func didChangeSwitchState(toggleCell:SettingsToggleTableViewCell , isOn: Bool) {
        let indexPath = self.settingsTableView.indexPathForCell(toggleCell)
        
        switch indexPath!.row {
        case 7:
            if isOn
            {
                NSUserDefaults.standardUserDefaults().setObject(1, forKey: "SaveToCameraRoll")
            }
            else{
                NSUserDefaults.standardUserDefaults().setObject(0, forKey: "SaveToCameraRoll")
            }
            break;
        case 4:
            if isOn
            {
                NSUserDefaults.standardUserDefaults().setObject(1, forKey: "flashMode")
            }
            else{
                NSUserDefaults.standardUserDefaults().setObject(0, forKey: "flashMode")
            }
            break;
        default:
            break;
        }
    }
}

extension SettingsViewController:UITableViewDelegate,UITableViewDataSource
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 45.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier("SettingsHeaderTableViewCell") as! SettingsHeaderTableViewCell
        headerCell.userInteractionEnabled = false
        switch (section) {
        case 0:
            headerCell.headerTitle.text = "CAMERA"
        case 1:
            headerCell.headerTitle.text = "ACCOUNT"
        case 2:
            headerCell.headerTitle.text = "SUPPORT"
        default:
            headerCell.headerTitle.text = ""
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            return dataSource != nil ? (dataSource?[0].count)! :0
            
        case 1:
            return dataSource != nil ? (dataSource?[1].count)! :0
            
        case 2:
            return dataSource != nil ? (dataSource?[2].count)! :0
            
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cellDataSource:[String:String]?
        if let dataSource = dataSource
        {
            if dataSource.count > indexPath.section
            {
                if dataSource[indexPath.section].count > indexPath.row
                {
                    cellDataSource = dataSource[indexPath.section][indexPath.row]
                }
            }
        }
        
        if let cellDataSource = cellDataSource
        {
            if cellDataSource[optionType] == toggleCell
            {
                let cell = tableView.dequeueReusableCellWithIdentifier("SettingsToggleTableViewCell", forIndexPath:indexPath) as! SettingsToggleTableViewCell
                cell.titlelabel.text = cellDataSource[optionTitle]
                cell.backgroundColor = UIColor.clearColor()
                cell.userInteractionEnabled = true
                cell.selectionStyle = .None
                if indexPath.row == 4 || indexPath.row == 7
                {
                    cell.userInteractionEnabled = true
                    cell.backgroundColor = UIColor.clearColor()
                    cell.titlelabel.textColor = UIColor.blackColor()
                    cell.titlelabel.alpha = 0.6
                    var switchStatus : Int = Int()
                    if indexPath.row == 4
                    {
                        switchStatus = NSUserDefaults.standardUserDefaults().integerForKey("flashMode")
                    }
                    else if indexPath.row == 7{
                        switchStatus =  NSUserDefaults.standardUserDefaults().integerForKey("SaveToCameraRoll")
                    }
                    if switchStatus == 0
                    {
                        cell.toggleCellSwitch.setOn(false, animated: false)
                    }
                    else{
                        cell.toggleCellSwitch.setOn(true, animated: false)
                    }
                }
                else{
                    cell.userInteractionEnabled = false
                    cell.titlelabel.textColor = UIColor.lightGrayColor()
                    cell.titlelabel.alpha = 1.0
                }
                cell.cellDelegate = self
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier("SettingsTableViewCell", forIndexPath:indexPath) as! SettingsTableViewCell
                cell.titleLabel.text = cellDataSource[optionTitle]
                cell.accessryLabel.text = cellDataSource[accessryText]
                cell.backgroundColor = UIColor.clearColor()
                
                if(((indexPath.section == 1) && (indexPath.row == 0)) || ((indexPath.section == 0) && (indexPath.row == 9)) || ((indexPath.section == 2) && (indexPath.row == 1)) || ((indexPath.section == 1) && (indexPath.row == 1)) || ((indexPath.section == 2) && (indexPath.row == 2)))
                {
                    cell.titleLabel.textColor = UIColor.blackColor()
                    cell.accessryLabel.textColor = UIColor.blackColor()
                    cell.titleLabel.alpha = 0.6
                    cell.accessryLabel.alpha = 0.6
                    cell.userInteractionEnabled = true
                }
                else{
                    cell.userInteractionEnabled = false
                    cell.titleLabel.textColor = UIColor.lightGrayColor()
                    cell.accessryLabel.textColor = UIColor.lightGrayColor()
                    cell.titleLabel.alpha = 1.0
                    cell.accessryLabel.alpha = 1.0
                }
                return cell
            }
        }
        else
        {
            return UITableViewCell()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        if let dataSource = dataSource
        {
            return dataSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        switch indexPath.section
        {
        case 0:
            switch indexPath.row
            {
            case 2:
                //   loadTimeLapseOptionsView()
                break
            case 5:
                //    loadProgramCameraButtonView()
                break
            case 9:
                loadLiveStreamView()
                break
            default:
                break
            }
        case 1:
            switch indexPath.row
            {
            case 0:
                loadEditProfileView()
                break
            case 1:
                loadDeleteMediaOptionsView()
                break
            case 2:
                //   loadConnectAccountView()
                break
            default:
                break
            }
        case 2:
            switch indexPath.row
            {
            case 0:
                break
            case 1:
                loadReportProblemView()
                break
            case 2:
                loadAppInfoView()
                break
            default:
                break
            }

        default:
            break
        }
    }
    func updateSwitchAtIndexPath(toggleSwitch: UISwitch)
    {
    }
    
    func loadReportProblemView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let reportVC = storyBoard.instantiateViewControllerWithIdentifier(ReportAProblemViewController.identifier) as! ReportAProblemViewController
        self.navigationController?.pushViewController(reportVC, animated: true)
    }
    
    func loadAppInfoView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let reportVC = storyBoard.instantiateViewControllerWithIdentifier(AppInfoViewController.identifier) as! AppInfoViewController
        self.navigationController?.pushViewController(reportVC, animated: true)
    }
    
    func loadEditProfileView()
    {
        let storyBoard = UIStoryboard.init(name:"EditProfile", bundle: nil)
        let editProfileVC = storyBoard.instantiateViewControllerWithIdentifier(EditProfileViewController.identifier) as! EditProfileViewController
        self.navigationController?.pushViewController(editProfileVC, animated: true)
    }
    
    func loadTimeLapseOptionsView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let timeLapseVC = storyBoard.instantiateViewControllerWithIdentifier(TimeLapseSettingsViewController.identifier) as! TimeLapseSettingsViewController
        self.navigationController?.pushViewController(timeLapseVC, animated: true)
    }
    
    func loadDeleteMediaOptionsView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let deleteMediaOptionsVC = storyBoard.instantiateViewControllerWithIdentifier(DeleteMediaSettingsViewController.identifier) as! DeleteMediaSettingsViewController
        self.navigationController?.pushViewController(deleteMediaOptionsVC, animated: true)
    }
    
    func loadConnectAccountView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let connectAccountVC = storyBoard.instantiateViewControllerWithIdentifier(ConnectAccountViewController.identifier) as! ConnectAccountViewController
        self.navigationController?.pushViewController(connectAccountVC, animated: true)
    }
    
    func loadProgramCameraButtonView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let connectAccountVC = storyBoard.instantiateViewControllerWithIdentifier(ProgramCameraButtonViewController.identifier) as! ProgramCameraButtonViewController
        self.navigationController?.pushViewController(connectAccountVC, animated: true)
    }
    
    func loadLiveStreamView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let LiveStreamVC = storyBoard.instantiateViewControllerWithIdentifier(ResolutionSelectionViewController.identifier) as! ResolutionSelectionViewController
        self.navigationController?.pushViewController(LiveStreamVC, animated: true)
    }
}

