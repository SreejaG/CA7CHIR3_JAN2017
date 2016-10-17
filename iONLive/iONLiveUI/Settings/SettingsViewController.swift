
import UIKit

class SettingsViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let optionTitle = "optionTitle"
    let optionType = "optionType"
    let accessryText = "accessryText"
    
    let toggleCell = "toggleCell"
    let normalCell = "normalCell"
    
    var cameraOptions = [[String:String]]()
    var accountOptions = [[String:String]]()
    var supportOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    var resValue = String()
    
    var liveResolutions : [String] = [String]()
    
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var backbutton: UIButton!
    @IBOutlet var pickerFullView: UIView!
    @IBOutlet weak var settingsTableView: UITableView!
    
    @IBOutlet var pickerUIView: UIView!
    
    @IBOutlet var pickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        liveResolutions = ["352x240 (240p)","480x360 (360p)","850x480 (480p)","1280x720 (720p)","1920x1080 (1080p)", "Cancel"]
        
        cameraOptions = [[optionTitle:"Upload to wifi", optionType : toggleCell, accessryText:""],[optionTitle:"Vivid Mode", optionType : toggleCell, accessryText:""],[optionTitle:"Time Lapse", optionType : normalCell, accessryText:""],[optionTitle:"Media Capture Quality", optionType : normalCell, accessryText:"HD"],[optionTitle:"Camera LED", optionType : toggleCell, accessryText: ""],[optionTitle:"Program Camera Button", optionType : normalCell, accessryText: ""],
                         [optionTitle:"Software Updates", optionType : normalCell, accessryText: ""],[optionTitle:"Save to Camera Roll", optionType : toggleCell, accessryText: ""],[optionTitle:"Get Snapcam! ", optionType : normalCell, accessryText: ""],[optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]]
        
        accountOptions = [[optionTitle:"Edit profile", optionType : normalCell, accessryText:""],[optionTitle:"Delete Archived Media", optionType : normalCell, accessryText:"Never"],[optionTitle:"Connect Accounts", optionType : normalCell, accessryText:""]]
        
        supportOptions = [[optionTitle:"Help Center ", optionType : normalCell, accessryText:""],[optionTitle:"Report a Problem", optionType : normalCell, accessryText:""]]
        
        
        dataSource = [cameraOptions,accountOptions,supportOptions]
        
        if(NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") != nil)
        {
            let value = NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") as! String
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:value]
            resValue = value
        }
        else{
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]
            resValue = "720p"
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.settingsTableView.backgroundView = nil
        self.settingsTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
        
        pickerFullView.hidden = true
        pickerUIView.layer.cornerRadius = 10
        backbutton.hidden = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.selectResolution))
        tap.delegate = self
        self.pickerView.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    @IBAction func doneClicked(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setValue(resValue, forKey: "liveResolution")
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
    
    
    func selectResolution(tapGestureObj: UITapGestureRecognizer) {
        let row = self.pickerView.selectedRowInComponent(0)
        if(row == 0)
        {
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"240p"]
            resValue = "240p"
        }
        else if(row == 1)
        {
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"360p"]
            resValue = "360p"
        }
        else if(row == 2)
        {
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"480p"]
            resValue = "480p"
        }
        else if(row == 3)
        {
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]
            resValue = "720p"
        }
        else if(row == 4){
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"1080p"]
            resValue = "1080p"
        }
        else if(row == 5)
        {
            if(NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") != nil)
            {
                let value = NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") as! String
                dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:value]
            }
            else{
                dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]
                resValue = "720p"
            }
        }
        doneButton.hidden = false
        backbutton.hidden = true
        settingsTableView.reloadData()
        pickerFullView.hidden = true
        self.settingsTableView.userInteractionEnabled = true
    }
    
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        if(NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") != nil)
        {
            let value = NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") as! String
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:value]
        }
        else{
            dataSource![0][9] = [optionTitle:"Live Stream Resolution", optionType : normalCell, accessryText:"720p"]
            resValue = "720p"
        }
        doneButton.hidden = false
        backbutton.hidden = true
        settingsTableView.reloadData()
        pickerFullView.hidden = true
        self.settingsTableView.userInteractionEnabled = true
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
                cell.contentView.backgroundColor = UIColor.init(colorLiteralRed: 230/255, green: 230/255, blue: 230/255, alpha: 1)
                cell.userInteractionEnabled = false
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCellWithIdentifier("SettingsTableViewCell", forIndexPath:indexPath) as! SettingsTableViewCell
                cell.titleLabel.text = cellDataSource[optionTitle]
                cell.accessryLabel.text = cellDataSource[accessryText]
                if(((indexPath.section == 1) && (indexPath.row == 0)) || ((indexPath.section == 0) && (indexPath.row == 9)) || ((indexPath.section == 2) && (indexPath.row == 1)))
                {
                    cell.backgroundColor = UIColor.clearColor()
                    cell.userInteractionEnabled = true
                }
                else{
                    cell.backgroundColor = UIColor.init(colorLiteralRed: 230/255, green: 230/255, blue: 230/255, alpha: 1)
                    cell.userInteractionEnabled = false
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
                loadPickerView()
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
                //  loadDeleteMediaOptionsView()
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
                loadEditProfileView()
                break
            case 1:
                loadReportProblemView()
                break
            default:
                break
            }

        default:
            break
        }
    }
    
    func loadReportProblemView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let reportVC = storyBoard.instantiateViewControllerWithIdentifier(ReportAProblemViewController.identifier) as! ReportAProblemViewController
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
    
    func loadPickerView()  {
        pickerFullView.hidden = false
        doneButton.hidden = true
        self.settingsTableView.userInteractionEnabled = false
        self.view.bringSubviewToFront(self.pickerUIView)
    }
    
    func loadProgramCameraButtonView()
    {
        let storyBoard = UIStoryboard.init(name:"Settings", bundle: nil)
        let connectAccountVC = storyBoard.instantiateViewControllerWithIdentifier(ProgramCameraButtonViewController.identifier) as! ProgramCameraButtonViewController
        self.navigationController?.pushViewController(connectAccountVC, animated: true)
    }
    
}

extension SettingsViewController : UIPickerViewDelegate{
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return liveResolutions.count
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36.0
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let titleData = liveResolutions[row]
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "Georgia", size: 15.0)!,NSForegroundColorAttributeName:UIColor.blackColor()])
        return myTitle.string
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
    }
}
