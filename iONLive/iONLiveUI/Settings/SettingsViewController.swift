
import UIKit

class SettingsViewController: UIViewController {
    
    let optionTitle = "optionTitle"
    let optionType = "optionType"
    let accessryText = "accessryText"
    
    let toggleCell = "toggleCell"
    let normalCell = "normalCell"
    
    var cameraOptions = [[String:String]]()
    var accountOptions = [[String:String]]()
    var supportOptions = [[String:String]]()
    
    var dataSource:[[[String:String]]]?
    
    @IBOutlet weak var settingsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraOptions = [[optionTitle:"Upload to wifi", optionType : toggleCell, accessryText:""],[optionTitle:"Vivid Mode", optionType : toggleCell, accessryText:""],[optionTitle:"Time Lapse", optionType : normalCell, accessryText:""],[optionTitle:"Media Capture Quality", optionType : normalCell, accessryText:"HD"],[optionTitle:"Camera LED", optionType : toggleCell, accessryText: ""],[optionTitle:"Program Camera Button", optionType : normalCell, accessryText: ""],
                         [optionTitle:"Software Updates", optionType : normalCell, accessryText: ""],[optionTitle:"Save to Camera Roll", optionType : toggleCell, accessryText: ""],[optionTitle:"Get Snapcam! ", optionType : normalCell, accessryText: ""]]
        
        accountOptions = [[optionTitle:"Edit profile", optionType : normalCell, accessryText:""],[optionTitle:"Delete Archived Media", optionType : normalCell, accessryText:"Never"],[optionTitle:"Connect Accounts", optionType : normalCell, accessryText:""]]
        
        supportOptions = [[optionTitle:"Help Center ", optionType : normalCell, accessryText:""],[optionTitle:"Report a Problem", optionType : normalCell, accessryText:""]]
        
        dataSource = [cameraOptions,accountOptions,supportOptions]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.settingsTableView.backgroundView = nil
        self.settingsTableView.backgroundColor = UIColor(red: 249.0/255, green: 249.0/255, blue: 249.0/255, alpha: 1)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
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
                if((indexPath.section == 1) && (indexPath.row == 0))
                {
                    
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
        default:
            break
        }
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
    
}
