
import UIKit

class ResolutionSelectionViewController: UIViewController {
    
    static let identifier = "ResolutionSelectionViewController"
    
    @IBOutlet var resolutionTableView: UITableView!
    
    var liveResolutions = ["352x240 (240p)","480x360 (360p)","850x480 (480p)","1280x720 (720p)","1920x1080 (1080p)"]
    var selectedOption:String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") != nil)
        {
            let value = NSUserDefaults.standardUserDefaults().valueForKey("liveResolution") as! String
            selectedOption = FileManagerViewController.sharedInstance.getLiveResolutionLongString(value)
        }
        else{
            selectedOption = "1280x720 (720p)"
        }
        resolutionTableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject)
    {
        let value = FileManagerViewController.sharedInstance.getLiveResolutionShortString(selectedOption)
        NSUserDefaults.standardUserDefaults().setValue(value, forKey: "liveResolution")
        self.navigationController?.popViewControllerAnimated(true)
    }
}

extension ResolutionSelectionViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(ResolutionHeaderTableViewCell.identifier) as! ResolutionHeaderTableViewCell
        headerCell.topBorder.hidden = false
        headerCell.bottomBorder.hidden = false
        
        switch section
        {
        case 0:
            headerCell.topBorder.hidden = true
            headerCell.headerTitleLabel.text = ""
            break
        case 1:
            headerCell.bottomBorder.hidden = true
            headerCell.headerTitleLabel.text = ""
            break
        default:
            break
        }
        return headerCell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 44.0
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return 0.01   // to avoid extra blank lines
    }
}

extension ResolutionSelectionViewController:UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return liveResolutions.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if liveResolutions.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(ResolutionTableViewCell.identifier, forIndexPath:indexPath) as! ResolutionTableViewCell
            cell.resolutionLabel.text = liveResolutions[indexPath.row]
            cell.selectionStyle = .None
            
            if selectedOption == liveResolutions[indexPath.row]
            {
                cell.selectionImageView.hidden = false
            }
            else
            {
                cell.selectionImageView.hidden = true
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if liveResolutions.count > indexPath.row
        {
            selectedOption = liveResolutions[indexPath.row]
            resolutionTableView.reloadData()
        }
    }
}