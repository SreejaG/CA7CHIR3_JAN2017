
import UIKit

class AppInfoViewController: UIViewController {

    static let identifier = "AppInfoViewController"

    let optionTitle = "optionTitle"
    let accessryText = "accessryText"
    
    @IBOutlet var appInfoBackButton: UIButton!
    @IBOutlet var appInfoTableView: UITableView!
    
    var appInfoSource = [[String:String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String
        var build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
        print("\(version) \(build)")
        
        if(build == "1"){
            build = "1.0"
        }
        
        appInfoSource = [[optionTitle:"Build Number", accessryText:build],[optionTitle:"Version", accessryText:version]]
        
        appInfoTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didTapBackButton(sender: AnyObject) {
         self.navigationController?.popViewControllerAnimated(true)
    }
    
}
extension AppInfoViewController: UITableViewDelegate
{
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40.0
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        let  headerCell = tableView.dequeueReusableCellWithIdentifier(AppInfoHeaderTableViewCell.identifier) as! AppInfoHeaderTableViewCell
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

extension AppInfoViewController:UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return appInfoSource.count
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if appInfoSource.count > indexPath.row
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(AppInfoTableViewCell.identifier, forIndexPath:indexPath) as! AppInfoTableViewCell
            cell.userInteractionEnabled = false
            cell.selectionStyle = .None
            cell.titleLabel.text = appInfoSource[indexPath.row][optionTitle]
            cell.accessryLabel.text = appInfoSource[indexPath.row][accessryText]
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
    }
}